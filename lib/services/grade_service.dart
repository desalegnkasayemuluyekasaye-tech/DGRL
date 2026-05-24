import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import 'notification_service.dart';

class GradeService {
  final CollectionReference _gradesCollection = 
      FirebaseFirestore.instance.collection('grades');
  final CollectionReference _coursesCollection = 
      FirebaseFirestore.instance.collection('courses');
  final CourseService _courseService = CourseService();

  Future<List<Grade>> getGradesForStudent(String studentId) async {
    try {
      final querySnapshot = await _gradesCollection
          .where('student_id', isEqualTo: studentId)
          .get();
      
      final grades = querySnapshot.docs
          .map((doc) => Grade.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      grades.sort((a, b) => a.semester.compareTo(b.semester));
      return grades;
    } catch (e) {
      print('Get grades error: $e');
      return [];
    }
  }

  Future<List<Grade>> getGradesForSemester(
    String studentId,
    String semester,
  ) async {
    try {
      final allGrades = await getGradesForStudent(studentId);
      return allGrades.where((g) => g.semester == semester).toList();
    } catch (e) {
      print('Get semester grades error: $e');
      return [];
    }
  }

  Future<bool> addGrade(Grade grade) async {
    try {
      await _gradesCollection.add(grade.toMap());
      
      // Trigger notification for student
      await _notifyStudentNewGrade(grade);
      
      return true;
    } catch (e) {
      print('Add grade error: $e');
      return false;
    }
  }
  
  Future<void> _notifyStudentNewGrade(Grade grade) async {
    try {
      final notificationService = NotificationService();
      final course = await getCourse(grade.courseCode);
      
      await notificationService.notifyGradeAdded(
        studentId: grade.studentId,
        courseCode: grade.courseCode,
        courseTitle: course?.courseTitle ?? 'Course',
        letterGrade: grade.letterGrade,
        totalScore: grade.totalScore,
      );
    } catch (e) {
      print('Error notifying student: $e');
    }
  }

  // Enhanced addGrade method with automatic calculations
  Future<bool> addGradeWithScores({
    required String studentId,
    required String courseCode,
    required double midScore,
    required double assignmentScore,
    required double finalScore,
    required String semester,
  }) async {
    try {
      final grade = Grade.create(
        studentId: studentId,
        courseCode: courseCode,
        midScore: midScore,
        assignmentScore: assignmentScore,
        finalScore: finalScore,
        semester: semester,
      );
      
      await _gradesCollection.add(grade.toMap());
      await _notifyStudentNewGrade(grade);
      return true;
    } catch (e) {
      print('Add grade with scores error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getGradesWithIds(String studentId) async {
    try {
      final querySnapshot = await _gradesCollection
          .where('student_id', isEqualTo: studentId)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Get grades with IDs error: $e');
      return [];
    }
  }

  Future<bool> deleteGrade(String gradeId) async {
    try {
      await _gradesCollection.doc(gradeId).delete();
      return true;
    } catch (e) {
      print('Delete grade error: $e');
      return false;
    }
  }

  Future<double> calculateGPA(String studentId, String semester) async {
    try {
      final allGrades = await getGradesForStudent(studentId);
      final semesterGrades = allGrades.where((g) => g.semester == semester).toList();
      
      if (semesterGrades.isEmpty) return 0.0;
      
      double totalPoints = 0.0;
      int totalCredits = 0;
      
      for (var grade in semesterGrades) {
        final course = await _courseService.getCourse(grade.courseCode);
        final creditHours = course?.creditHours ?? 3;
        totalPoints += Grade.gradePoint(grade.letterGrade) * creditHours;
        totalCredits += creditHours;
      }
      
      return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
    } catch (e) {
      print('Calculate GPA error: $e');
      return 0.0;
    }
  }

  Future<double> calculateCGPA(String studentId) async {
    try {
      final querySnapshot = await _gradesCollection
          .where('student_id', isEqualTo: studentId)
          .get();
      
      if (querySnapshot.docs.isEmpty) return 0.0;
      
      double totalPoints = 0.0;
      int totalCredits = 0;
      
      for (var doc in querySnapshot.docs) {
        final grade = Grade.fromMap(doc.data() as Map<String, dynamic>);
        final course = await _courseService.getCourse(grade.courseCode);
        final creditHours = course?.creditHours ?? 3;
        totalPoints += Grade.gradePoint(grade.letterGrade) * creditHours;
        totalCredits += creditHours;
      }
      
      return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
    } catch (e) {
      print('Calculate CGPA error: $e');
      return 0.0;
    }
  }

  Future<List<String>> getSemesters(String studentId) async {
    try {
      final querySnapshot = await _gradesCollection
          .where('student_id', isEqualTo: studentId)
          .get();
      
      final semesters = querySnapshot.docs
          .map((doc) => Grade.fromMap(doc.data() as Map<String, dynamic>).semester)
          .toSet()
          .toList();
      
      semesters.sort(); // Sort semesters chronologically
      return semesters;
    } catch (e) {
      print('Get semesters error: $e');
      return [];
    }
  }

  Future<List<Course>> getAllCourses() async {
    try {
      final querySnapshot = await _coursesCollection.get();
      
      return querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get courses error: $e');
      return [];
    }
  }

  Future<Course?> getCourse(String courseCode) async {
    try {
      final querySnapshot = await _coursesCollection
          .where('course_code', isEqualTo: courseCode)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return Course.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get course error: $e');
      return null;
    }
  }

  Future<bool> addCourse(Course course) async {
    try {
      await _coursesCollection.add(course.toMap());
      
      // Notify all registered students about new course
      await _notifyStudentsNewCourse(course);
      
      return true;
    } catch (e) {
      print('Add course error: $e');
      return false;
    }
  }
  
  Future<void> _notifyStudentsNewCourse(Course course) async {
    try {
      // Get all students (in a real app, you'd filter by registered students)
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      final notificationService = NotificationService();
      
      for (var studentDoc in studentsSnapshot.docs) {
        await notificationService.notifyCourseRegistration(
          studentId: studentDoc.id,
          courseCode: course.courseCode,
          courseTitle: course.courseTitle,
          lectureName: course.instructor.isNotEmpty ? course.instructor : 'Professor',
        );
      }
    } catch (e) {
      print('Error notifying students about new course: $e');
    }
  }

  // Enhanced grade management features
  
  Future<bool> updateGrade(String gradeId, Grade grade) async {
    try {
      await _gradesCollection.doc(gradeId).update(grade.toMap());
      return true;
    } catch (e) {
      print('Update grade error: $e');
      return false;
    }
  }

  Future<List<Grade>> getFilteredGrades(
    String studentId, {
    String? semester,
    String? courseCode,
    String? letterGrade,
    double? minScore,
    double? maxScore,
  }) async {
    try {
      Query query = _gradesCollection.where('student_id', isEqualTo: studentId);
      
      if (semester != null) {
        query = query.where('semester', isEqualTo: semester);
      }
      if (courseCode != null) {
        query = query.where('course_code', isEqualTo: courseCode);
      }
      if (letterGrade != null) {
        query = query.where('letter_grade', isEqualTo: letterGrade);
      }
      
      final querySnapshot = await query.get();
      
      List<Grade> grades = querySnapshot.docs
          .map((doc) => Grade.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Apply score filters (client-side filtering for range queries)
      if (minScore != null) {
        grades = grades.where((g) => g.totalScore >= minScore).toList();
      }
      if (maxScore != null) {
        grades = grades.where((g) => g.totalScore <= maxScore).toList();
      }
      
      return grades;
    } catch (e) {
      print('Get filtered grades error: $e');
      return [];
    }
  }

  Future<List<Grade>> getSortedGrades(
    String studentId, {
    String sortBy = 'total_score', // 'total_score', 'course_code', 'semester'
    bool ascending = false,
  }) async {
    try {
      Query query = _gradesCollection.where('student_id', isEqualTo: studentId);
      
      // Apply sorting
      switch (sortBy) {
        case 'total_score':
          query = query.orderBy('total_score', descending: !ascending);
          break;
        case 'course_code':
          query = query.orderBy('course_code', descending: !ascending);
          break;
        case 'semester':
          query = query.orderBy('semester', descending: !ascending);
          break;
        default:
          query = query.orderBy('total_score', descending: !ascending);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => Grade.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get sorted grades error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getGradeStatistics(String studentId) async {
    try {
      final querySnapshot = await _gradesCollection
          .where('student_id', isEqualTo: studentId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return {
          'totalGrades': 0,
          'averageScore': 0.0,
          'highestScore': 0.0,
          'lowestScore': 0.0,
          'gradeDistribution': {},
          'semesterAverages': {},
          'courseAverages': {},
        };
      }
      
      final grades = querySnapshot.docs
          .map((doc) => Grade.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Calculate basic statistics
      final totalGrades = grades.length;
      final scores = grades.map((g) => g.totalScore).toList();
      final averageScore = scores.reduce((a, b) => a + b) / totalGrades;
      final highestScore = scores.reduce((a, b) => a > b ? a : b);
      final lowestScore = scores.reduce((a, b) => a < b ? a : b);
      
      // Grade distribution
      final gradeDistribution = <String, int>{};
      for (var grade in grades) {
        gradeDistribution[grade.letterGrade] = 
            (gradeDistribution[grade.letterGrade] ?? 0) + 1;
      }
      
      // Semester averages
      final semesterAverages = <String, double>{};
      final semesterGroups = <String, List<Grade>>{};
      for (var grade in grades) {
        semesterGroups.putIfAbsent(grade.semester, () => []).add(grade);
      }
      semesterGroups.forEach((semester, semesterGrades) {
        final avg = semesterGrades
            .map((g) => g.totalScore)
            .reduce((a, b) => a + b) / semesterGrades.length;
        semesterAverages[semester] = avg;
      });
      
      // Course averages
      final courseAverages = <String, double>{};
      final courseGroups = <String, List<Grade>>{};
      for (var grade in grades) {
        courseGroups.putIfAbsent(grade.courseCode, () => []).add(grade);
      }
      courseGroups.forEach((courseCode, courseGrades) {
        final avg = courseGrades
            .map((g) => g.totalScore)
            .reduce((a, b) => a + b) / courseGrades.length;
        courseAverages[courseCode] = avg;
      });
      
      return {
        'totalGrades': totalGrades,
        'averageScore': averageScore,
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'gradeDistribution': gradeDistribution,
        'semesterAverages': semesterAverages,
        'courseAverages': courseAverages,
      };
    } catch (e) {
      print('Get grade statistics error: $e');
      return {};
    }
  }

  Future<List<Grade>> getTopGrades(String studentId, {int limit = 5}) async {
    try {
      final querySnapshot = await _gradesCollection
          .where('student_id', isEqualTo: studentId)
          .orderBy('total_score', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Grade.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get top grades error: $e');
      return [];
    }
  }

  Future<List<Grade>> getBottomGrades(String studentId, {int limit = 5}) async {
    try {
      final querySnapshot = await _gradesCollection
          .where('student_id', isEqualTo: studentId)
          .orderBy('total_score', descending: false)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Grade.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get bottom grades error: $e');
      return [];
    }
  }

  Future<Map<String, int>> getGradeCountByLetter(String studentId) async {
    try {
      final querySnapshot = await _gradesCollection
          .where('student_id', isEqualTo: studentId)
          .get();
      
      final gradeCounts = <String, int>{};
      
      for (var doc in querySnapshot.docs) {
        final grade = Grade.fromMap(doc.data() as Map<String, dynamic>);
        gradeCounts[grade.letterGrade] = (gradeCounts[grade.letterGrade] ?? 0) + 1;
      }
      
      return gradeCounts;
    } catch (e) {
      print('Get grade count by letter error: $e');
      return {};
    }
  }
}
