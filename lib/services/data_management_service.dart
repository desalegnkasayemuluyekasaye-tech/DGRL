import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/grade.dart';
import '../models/course.dart';
import '../models/course_registration.dart';

class DataManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Full Firestore Migration
  Future<Map<String, dynamic>> migrateToFirestore() async {
    try {
      final migrationResults = {
        'students': await _migrateStudents(),
        'grades': await _migrateGrades(),
        'courses': await _migrateCourses(),
        'registrations': await _migrateRegistrations(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
      };
      
      // Log migration
      await _firestore.collection('migration_logs').add(migrationResults);
      
      return migrationResults;
    } catch (e) {
      print('Migration error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> _migrateStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_students');
      
      if (localData != null) {
        List<dynamic> decoded = jsonDecode(localData);
        int migrated = 0;
        int failed = 0;
        
        for (var studentData in decoded) {
          try {
            final student = Student(
              studentId: studentData['student_id'] ?? studentData['studentId'] ?? '',
              fullName: '${studentData['first_name'] ?? studentData['firstName'] ?? ''} ${studentData['last_name'] ?? studentData['lastName'] ?? ''}',
              department: studentData['department'] ?? '',
              batch: studentData['batch'] ?? studentData['year']?.toString() ?? '1',
              email: studentData['email'] ?? '',
              password: studentData['password'] ?? 'default123',
              phone: studentData['phone'],
              age: studentData['age'],
              photoUrl: studentData['photo_url'] ?? studentData['photoUrl'],
            );
            
            await _firestore.collection('students').add(student.toMap());
            migrated++;
          } catch (e) {
            failed++;
            print('Failed to migrate student: $e');
          }
        }
        
        // Clear local data after successful migration
        if (failed == 0) {
          await prefs.remove('local_students');
        }
        
        return {
          'total': decoded.length,
          'migrated': migrated,
          'failed': failed,
        };
      }
      
      return {'total': 0, 'migrated': 0, 'failed': 0};
    } catch (e) {
      print('Migrate students error: $e');
      return {'total': 0, 'migrated': 0, 'failed': 0, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _migrateGrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_grades');
      
      if (localData != null) {
        List<dynamic> decoded = jsonDecode(localData);
        int migrated = 0;
        int failed = 0;
        
        for (var gradeData in decoded) {
          try {
            final grade = Grade(
              studentId: gradeData['student_id'] ?? '',
              courseCode: gradeData['course_code'] ?? '',
              midScore: gradeData['mid_score']?.toDouble() ?? 0.0,
              assignmentScore: gradeData['assignment_score']?.toDouble() ?? 0.0,
              finalScore: gradeData['final_score']?.toDouble() ?? 0.0,
              totalScore: gradeData['total_score']?.toDouble() ?? 0.0,
              letterGrade: gradeData['letter_grade'] ?? '',
              semester: gradeData['semester'] ?? '',
            );
            
            await _firestore.collection('grades').add(grade.toMap());
            migrated++;
          } catch (e) {
            failed++;
            print('Failed to migrate grade: $e');
          }
        }
        
        // Clear local data after successful migration
        if (failed == 0) {
          await prefs.remove('local_grades');
        }
        
        return {
          'total': decoded.length,
          'migrated': migrated,
          'failed': failed,
        };
      }
      
      return {'total': 0, 'migrated': 0, 'failed': 0};
    } catch (e) {
      print('Migrate grades error: $e');
      return {'total': 0, 'migrated': 0, 'failed': 0, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _migrateCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_courses');
      
      if (localData != null) {
        List<dynamic> decoded = jsonDecode(localData);
        int migrated = 0;
        int failed = 0;
        
        for (var courseData in decoded) {
          try {
            // Create a basic course with default schedule
            final course = Course(
              courseCode: courseData['courseCode'] ?? courseData['course_code'] ?? '',
              courseTitle: courseData['courseTitle'] ?? courseData['course_title'] ?? '',
              creditHours: courseData['creditHours'] ?? courseData['credit_hours'] ?? 3,
              instructor: courseData['instructor'] ?? '',
              semester: courseData['semester'] ?? '',
              schedule: CourseSchedule(
                dayOfWeek: 'Monday',
                startTime: '09:00',
                endTime: '10:30',
              ),
            );
            
            await _firestore.collection('courses').add(course.toMap());
            migrated++;
          } catch (e) {
            failed++;
            print('Failed to migrate course: $e');
          }
        }
        
        // Clear local data after successful migration
        if (failed == 0) {
          await prefs.remove('local_courses');
        }
        
        return {
          'total': decoded.length,
          'migrated': migrated,
          'failed': failed,
        };
      }
      
      return {'total': 0, 'migrated': 0, 'failed': 0};
    } catch (e) {
      print('Migrate courses error: $e');
      return {'total': 0, 'migrated': 0, 'failed': 0, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _migrateRegistrations() async {
    try {
      // Generate mock registration data based on existing grades
      final gradesSnapshot = await _firestore.collection('grades').get();
      int migrated = 0;
      int failed = 0;
      
      for (var gradeDoc in gradesSnapshot.docs) {
        try {
          final gradeData = gradeDoc.data();
          final registration = CourseRegistration.create(
            studentId: gradeData['student_id'] ?? '',
            courseCode: gradeData['course_code'] ?? '',
            semester: gradeData['semester'] ?? '',
          );
          
          await _firestore.collection('course_registrations').add(registration.toMap());
          migrated++;
        } catch (e) {
          failed++;
          print('Failed to migrate registration: $e');
        }
      }
      
      return {
        'total': gradesSnapshot.docs.length,
        'migrated': migrated,
        'failed': failed,
      };
    } catch (e) {
      print('Migrate registrations error: $e');
      return {'total': 0, 'migrated': 0, 'failed': 0, 'error': e.toString()};
    }
  }

  // Data Backup System
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final backupData = {
        'students': await _backupCollection('students'),
        'grades': await _backupCollection('grades'),
        'courses': await _backupCollection('courses'),
        'registrations': await _backupCollection('course_registrations'),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      // Store backup in Firestore
      await _firestore.collection('backups').add({
        'data': backupData,
        'created_at': Timestamp.now(),
        'status': 'completed',
      });
      
      return {
        'status': 'success',
        'backupId': backupData['timestamp'],
        'data': backupData,
      };
    } catch (e) {
      print('Create backup error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> _backupCollection(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();
    } catch (e) {
      print('Backup collection $collectionName error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> restoreBackup(String backupId) async {
    try {
      final backupDoc = await _firestore
          .collection('backups')
          .where('created_at', isEqualTo: Timestamp.fromMillisecondsSinceEpoch(int.parse(backupId)))
          .limit(1)
          .get();
      
      if (backupDoc.docs.isNotEmpty) {
        final backupData = backupDoc.docs.first.data()['data'] as Map<String, dynamic>;
        
        final restoreResults = {
          'students': await _restoreCollection('students', backupData['students']),
          'grades': await _restoreCollection('grades', backupData['grades']),
          'courses': await _restoreCollection('courses', backupData['courses']),
          'registrations': await _restoreCollection('course_registrations', backupData['registrations']),
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'completed',
        };
        
        return restoreResults;
      }
      
      return {'status': 'failed', 'error': 'Backup not found'};
    } catch (e) {
      print('Restore backup error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _restoreCollection(String collectionName, List<dynamic> data) async {
    try {
      int restored = 0;
      int failed = 0;
      
      // Clear existing data
      final existingDocs = await _firestore.collection(collectionName).get();
      for (var doc in existingDocs.docs) {
        await doc.reference.delete();
      }
      
      // Restore data
      for (var item in data) {
        try {
          await _firestore.collection(collectionName).add(item['data']);
          restored++;
        } catch (e) {
          failed++;
          print('Failed to restore item: $e');
        }
      }
      
      return {
        'total': data.length,
        'restored': restored,
        'failed': failed,
      };
    } catch (e) {
      print('Restore collection $collectionName error: $e');
      return {'total': 0, 'restored': 0, 'failed': 0, 'error': e.toString()};
    }
  }

  // Comprehensive Import/Export Functionality
  Future<Map<String, dynamic>> exportData({String format = 'json'}) async {
    try {
      final exportData = {
        'metadata': {
          'exportDate': DateTime.now().toIso8601String(),
          'format': format,
          'version': '1.0',
        },
        'students': await _exportCollection('students'),
        'grades': await _exportCollection('grades'),
        'courses': await _exportCollection('courses'),
        'registrations': await _exportCollection('course_registrations'),
      };
      
      switch (format.toLowerCase()) {
        case 'csv':
          return _exportToCSV(exportData);
        case 'xml':
          return _exportToXML(exportData);
        default:
          return _exportToJSON(exportData);
      }
    } catch (e) {
      print('Export data error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> _exportCollection(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Export collection $collectionName error: $e');
      return [];
    }
  }

  Map<String, dynamic> _exportToJSON(Map<String, dynamic> data) {
    return {
      'status': 'success',
      'format': 'json',
      'filename': 'export_${DateTime.now().millisecondsSinceEpoch}.json',
      'mimeType': 'application/json',
      'data': jsonEncode(data),
    };
  }

  Map<String, dynamic> _exportToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Export students
    buffer.writeln('=== STUDENTS ===');
    buffer.writeln('student_id,first_name,last_name,email,phone,department,year,gpa');
    for (var student in data['students']) {
      buffer.writeln('${student['student_id']},${student['first_name']},${student['last_name']},${student['email']},${student['phone']},${student['department']},${student['year']},${student['gpa']}');
    }
    
    // Export grades
    buffer.writeln('\n=== GRADES ===');
    buffer.writeln('student_id,course_code,mid_score,assignment_score,final_score,total_score,letter_grade,semester');
    for (var grade in data['grades']) {
      buffer.writeln('${grade['student_id']},${grade['course_code']},${grade['mid_score']},${grade['assignment_score']},${grade['final_score']},${grade['total_score']},${grade['letter_grade']},${grade['semester']}');
    }
    
    return {
      'status': 'success',
      'format': 'csv',
      'filename': 'export_${DateTime.now().millisecondsSinceEpoch}.csv',
      'mimeType': 'text/csv',
      'data': buffer.toString(),
    };
  }

  Map<String, dynamic> _exportToXML(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<export>');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <exportDate>${data['metadata']['exportDate']}</exportDate>');
    buffer.writeln('    <format>${data['metadata']['format']}</format>');
    buffer.writeln('    <version>${data['metadata']['version']}</version>');
    buffer.writeln('  </metadata>');
    
    // Export students
    buffer.writeln('  <students>');
    for (var student in data['students']) {
      buffer.writeln('    <student>');
      buffer.writeln('      <student_id>${student['student_id']}</student_id>');
      buffer.writeln('      <first_name>${student['first_name']}</first_name>');
      buffer.writeln('      <last_name>${student['last_name']}</last_name>');
      buffer.writeln('      <email>${student['email']}</email>');
      buffer.writeln('      <phone>${student['phone']}</phone>');
      buffer.writeln('      <department>${student['department']}</department>');
      buffer.writeln('      <year>${student['year']}</year>');
      buffer.writeln('      <gpa>${student['gpa']}</gpa>');
      buffer.writeln('    </student>');
    }
    buffer.writeln('  </students>');
    
    buffer.writeln('</export>');
    
    return {
      'status': 'success',
      'format': 'xml',
      'filename': 'export_${DateTime.now().millisecondsSinceEpoch}.xml',
      'mimeType': 'application/xml',
      'data': buffer.toString(),
    };
  }

  Future<Map<String, dynamic>> importData(String data, String format) async {
    try {
      Map<String, dynamic> importData;
      
      switch (format.toLowerCase()) {
        case 'csv':
          importData = _parseCSV(data);
          break;
        case 'xml':
          importData = _parseXML(data);
          break;
        default:
          importData = jsonDecode(data);
      }
      
      final importResults = {
        'students': await _importCollection('students', importData['students']),
        'grades': await _importCollection('grades', importData['grades']),
        'courses': await _importCollection('courses', importData['courses']),
        'registrations': await _importCollection('course_registrations', importData['registrations']),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
      };
      
      return importResults;
    } catch (e) {
      print('Import data error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _parseCSV(String csvData) {
    // Simple CSV parsing - in production, use a proper CSV library
    final lines = csvData.split('\n');
    final students = <Map<String, dynamic>>[];
    final grades = <Map<String, dynamic>>[];
    
    bool inStudentsSection = false;
    bool inGradesSection = false;
    
    for (var line in lines) {
      if (line.startsWith('=== STUDENTS ===')) {
        inStudentsSection = true;
        inGradesSection = false;
        continue;
      }
      if (line.startsWith('=== GRADES ===')) {
        inStudentsSection = false;
        inGradesSection = true;
        continue;
      }
      
      if (inStudentsSection && line.contains(',')) {
        final parts = line.split(',');
        if (parts.length >= 8) {
          students.add({
            'student_id': parts[0],
            'first_name': parts[1],
            'last_name': parts[2],
            'email': parts[3],
            'phone': parts[4],
            'department': parts[5],
            'year': int.tryParse(parts[6]) ?? 1,
            'gpa': double.tryParse(parts[7]) ?? 0.0,
          });
        }
      }
      
      if (inGradesSection && line.contains(',')) {
        final parts = line.split(',');
        if (parts.length >= 8) {
          grades.add({
            'student_id': parts[0],
            'course_code': parts[1],
            'mid_score': double.tryParse(parts[2]) ?? 0.0,
            'assignment_score': double.tryParse(parts[3]) ?? 0.0,
            'final_score': double.tryParse(parts[4]) ?? 0.0,
            'total_score': double.tryParse(parts[5]) ?? 0.0,
            'letter_grade': parts[6],
            'semester': parts[7],
          });
        }
      }
    }
    
    return {
      'students': students,
      'grades': grades,
      'courses': [],
      'registrations': [],
    };
  }

  Map<String, dynamic> _parseXML(String xmlData) {
    // Simple XML parsing - in production, use a proper XML library
    // This is a simplified implementation
    return {
      'students': [],
      'grades': [],
      'courses': [],
      'registrations': [],
    };
  }

  Future<Map<String, dynamic>> _importCollection(String collectionName, List<dynamic> data) async {
    try {
      int imported = 0;
      int failed = 0;
      
      for (var item in data) {
        try {
          await _firestore.collection(collectionName).add(item);
          imported++;
        } catch (e) {
          failed++;
          print('Failed to import item: $e');
        }
      }
      
      return {
        'total': data.length,
        'imported': imported,
        'failed': failed,
      };
    } catch (e) {
      print('Import collection $collectionName error: $e');
      return {'total': 0, 'imported': 0, 'failed': 0, 'error': e.toString()};
    }
  }

  // Data Validation System
  Future<Map<String, dynamic>> validateData() async {
    try {
      final validationResults = {
        'students': await _validateStudents(),
        'grades': await _validateGrades(),
        'courses': await _validateCourses(),
        'registrations': await _validateRegistrations(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
      };
      
      return validationResults;
    } catch (e) {
      print('Validate data error: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _validateStudents() async {
    try {
      final snapshot = await _firestore.collection('students').get();
      int valid = 0;
      int invalid = 0;
      final errors = <String>[];
      
      for (var doc in snapshot.docs) {
        final student = doc.data();
        bool isValid = true;
        
        // Validate required fields
        if (student['student_id'] == null || student['student_id'].toString().isEmpty) {
          errors.add('Student ${doc.id}: Missing student_id');
          isValid = false;
        }
        
        if (student['email'] == null || student['email'].toString().isEmpty) {
          errors.add('Student ${doc.id}: Missing email');
          isValid = false;
        }
        
        // Validate email format
        if (student['email'] != null && !_isValidEmail(student['email'])) {
          errors.add('Student ${doc.id}: Invalid email format');
          isValid = false;
        }
        
        if (isValid) {
          valid++;
        } else {
          invalid++;
        }
      }
      
      return {
        'total': snapshot.docs.length,
        'valid': valid,
        'invalid': invalid,
        'errors': errors,
      };
    } catch (e) {
      print('Validate students error: $e');
      return {'total': 0, 'valid': 0, 'invalid': 0, 'errors': [e.toString()]};
    }
  }

  Future<Map<String, dynamic>> _validateGrades() async {
    try {
      final snapshot = await _firestore.collection('grades').get();
      int valid = 0;
      int invalid = 0;
      final errors = <String>[];
      
      for (var doc in snapshot.docs) {
        final grade = doc.data();
        bool isValid = true;
        
        // Validate required fields
        if (grade['student_id'] == null || grade['student_id'].toString().isEmpty) {
          errors.add('Grade ${doc.id}: Missing student_id');
          isValid = false;
        }
        
        if (grade['course_code'] == null || grade['course_code'].toString().isEmpty) {
          errors.add('Grade ${doc.id}: Missing course_code');
          isValid = false;
        }
        
        // Validate score ranges
        if (grade['total_score'] != null && (grade['total_score'] < 0 || grade['total_score'] > 100)) {
          errors.add('Grade ${doc.id}: Invalid total_score range');
          isValid = false;
        }
        
        if (isValid) {
          valid++;
        } else {
          invalid++;
        }
      }
      
      return {
        'total': snapshot.docs.length,
        'valid': valid,
        'invalid': invalid,
        'errors': errors,
      };
    } catch (e) {
      print('Validate grades error: $e');
      return {'total': 0, 'valid': 0, 'invalid': 0, 'errors': [e.toString()]};
    }
  }

  Future<Map<String, dynamic>> _validateCourses() async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      int valid = 0;
      int invalid = 0;
      final errors = <String>[];
      
      for (var doc in snapshot.docs) {
        final course = doc.data();
        bool isValid = true;
        
        // Validate required fields
        if (course['course_code'] == null || course['course_code'].toString().isEmpty) {
          errors.add('Course ${doc.id}: Missing course_code');
          isValid = false;
        }
        
        if (course['course_title'] == null || course['course_title'].toString().isEmpty) {
          errors.add('Course ${doc.id}: Missing course_title');
          isValid = false;
        }
        
        // Validate credit hours
        if (course['credit_hours'] != null && (course['credit_hours'] < 1 || course['credit_hours'] > 10)) {
          errors.add('Course ${doc.id}: Invalid credit_hours range');
          isValid = false;
        }
        
        if (isValid) {
          valid++;
        } else {
          invalid++;
        }
      }
      
      return {
        'total': snapshot.docs.length,
        'valid': valid,
        'invalid': invalid,
        'errors': errors,
      };
    } catch (e) {
      print('Validate courses error: $e');
      return {'total': 0, 'valid': 0, 'invalid': 0, 'errors': [e.toString()]};
    }
  }

  Future<Map<String, dynamic>> _validateRegistrations() async {
    try {
      final snapshot = await _firestore.collection('course_registrations').get();
      int valid = 0;
      int invalid = 0;
      final errors = <String>[];
      
      for (var doc in snapshot.docs) {
        final registration = doc.data();
        bool isValid = true;
        
        // Validate required fields
        if (registration['student_id'] == null || registration['student_id'].toString().isEmpty) {
          errors.add('Registration ${doc.id}: Missing student_id');
          isValid = false;
        }
        
        if (registration['course_code'] == null || registration['course_code'].toString().isEmpty) {
          errors.add('Registration ${doc.id}: Missing course_code');
          isValid = false;
        }
        
        if (isValid) {
          valid++;
        } else {
          invalid++;
        }
      }
      
      return {
        'total': snapshot.docs.length,
        'valid': valid,
        'invalid': invalid,
        'errors': errors,
      };
    } catch (e) {
      print('Validate registrations error: $e');
      return {'total': 0, 'valid': 0, 'invalid': 0, 'errors': [e.toString()]};
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Data Statistics
  Future<Map<String, dynamic>> getDataStatistics() async {
    try {
      final stats = {
        'students': await _getCollectionStats('students'),
        'grades': await _getCollectionStats('grades'),
        'courses': await _getCollectionStats('courses'),
        'registrations': await _getCollectionStats('course_registrations'),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return stats;
    } catch (e) {
      print('Get data statistics error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getCollectionStats(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return {
        'total': snapshot.docs.length,
        'lastUpdated:': snapshot.docs.isNotEmpty 
            ? snapshot.docs.map((doc) => doc.get('last_updated') ?? Timestamp.now()).reduce((a, b) => a.compareTo(b) > 0 ? a : b)
            : Timestamp.now(),
      };
    } catch (e) {
      print('Get collection stats error: $e');
      return {'total': 0, 'lastUpdated': Timestamp.now()};
    }
  }
}
