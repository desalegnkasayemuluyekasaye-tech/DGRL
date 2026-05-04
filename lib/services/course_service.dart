import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/course_registration.dart';

class CourseService {
  final CollectionReference _coursesCollection = 
      FirebaseFirestore.instance.collection('courses');
  final CollectionReference _registrationsCollection = 
      FirebaseFirestore.instance.collection('course_registrations');

  // Basic Course CRUD Operations
  Future<bool> addCourse(Course course) async {
    try {
      await _coursesCollection.add(course.toMap());
      return true;
    } catch (e) {
      print('Add course error: $e');
      return false;
    }
  }

  Future<bool> updateCourse(String courseId, Course course) async {
    try {
      await _coursesCollection.doc(courseId).update(course.toMap());
      return true;
    } catch (e) {
      print('Update course error: $e');
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      await _coursesCollection.doc(courseId).delete();
      return true;
    } catch (e) {
      print('Delete course error: $e');
      return false;
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

  // Advanced Course Management
  Future<List<Course>> getCoursesBySemester(String semester) async {
    try {
      final querySnapshot = await _coursesCollection
          .where('semester', isEqualTo: semester)
          .where('is_active', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get courses by semester error: $e');
      return [];
    }
  }

  Future<List<Course>> getCoursesByDepartment(String department) async {
    try {
      final querySnapshot = await _coursesCollection
          .where('department', isEqualTo: department)
          .where('is_active', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get courses by department error: $e');
      return [];
    }
  }

  Future<List<Course>> getAvailableCourses(String semester) async {
    try {
      final querySnapshot = await _coursesCollection
          .where('semester', isEqualTo: semester)
          .where('is_active', isEqualTo: true)
          .get();
      
      final courses = querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Filter courses that have availability
      return courses.where((course) => course.hasAvailability).toList();
    } catch (e) {
      print('Get available courses error: $e');
      return [];
    }
  }

  // Course Registration Management
  Future<bool> registerForCourse(String studentId, String courseCode, String semester) async {
    try {
      // Check if course exists and has availability
      final course = await getCourse(courseCode);
      if (course == null || !course.hasAvailability) {
        return false;
      }

      // Check if student is already registered
      final existingRegistration = await getRegistration(studentId, courseCode, semester);
      if (existingRegistration != null) {
        return false; // Already registered
      }

      // Check prerequisites
      if (!await checkPrerequisites(studentId, course.prerequisites)) {
        return false;
      }

      // Create registration
      final registration = CourseRegistration.create(
        studentId: studentId,
        courseCode: courseCode,
        semester: semester,
      );

      await _registrationsCollection.add(registration.toMap());

      // Update course enrollment count
      await updateCourseEnrollment(courseCode, course.currentEnrolled + 1);

      return true;
    } catch (e) {
      print('Register for course error: $e');
      return false;
    }
  }

  Future<bool> dropCourse(String studentId, String courseCode, String semester) async {
    try {
      final registration = await getRegistration(studentId, courseCode, semester);
      if (registration == null) {
        return false;
      }

      // Update registration status
      await _registrationsCollection.doc(registration.id).update({
        'status': 'dropped',
        'is_active': false,
      });

      // Update course enrollment count
      final course = await getCourse(courseCode);
      if (course != null && course.currentEnrolled > 0) {
        await updateCourseEnrollment(courseCode, course.currentEnrolled - 1);
      }

      return true;
    } catch (e) {
      print('Drop course error: $e');
      return false;
    }
  }

  Future<List<CourseRegistration>> getStudentRegistrations(String studentId, {String? semester}) async {
    try {
      Query query = _registrationsCollection
          .where('student_id', isEqualTo: studentId)
          .where('is_active', isEqualTo: true);
      
      if (semester != null) {
        query = query.where('semester', isEqualTo: semester);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => CourseRegistration.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get student registrations error: $e');
      return [];
    }
  }

  Future<CourseRegistration?> getRegistration(String studentId, String courseCode, String semester) async {
    try {
      final querySnapshot = await _registrationsCollection
          .where('student_id', isEqualTo: studentId)
          .where('course_code', isEqualTo: courseCode)
          .where('semester', isEqualTo: semester)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return CourseRegistration.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get registration error: $e');
      return null;
    }
  }

  // Prerequisites Management
  Future<bool> checkPrerequisites(String studentId, List<String> prerequisites) async {
    if (prerequisites.isEmpty) {
      return true;
    }

    try {
      // Get all completed courses for the student
      final registrations = await getStudentRegistrations(studentId);
      final completedCourses = registrations
          .where((reg) => reg.isCompleted)
          .map((reg) => reg.courseCode)
          .toSet();

      // Check if all prerequisites are completed
      for (String prerequisite in prerequisites) {
        if (!completedCourses.contains(prerequisite)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Check prerequisites error: $e');
      return false;
    }
  }

  Future<List<Course>> getPrerequisiteCourses(String studentId) async {
    try {
      final registrations = await getStudentRegistrations(studentId);
      final completedCourses = registrations
          .where((reg) => reg.isCompleted)
          .map((reg) => reg.courseCode)
          .toSet();

      final allCourses = await getAllCourses();
      final prerequisiteCourses = <Course>[];

      for (Course course in allCourses) {
        if (course.prerequisites.isNotEmpty) {
          // Check if student has completed all prerequisites for this course
          bool hasAllPrerequisites = course.prerequisites.every((prereq) => 
              completedCourses.contains(prereq));
          
          if (hasAllPrerequisites) {
            prerequisiteCourses.add(course);
          }
        }
      }

      return prerequisiteCourses;
    } catch (e) {
      print('Get prerequisite courses error: $e');
      return [];
    }
  }

  // Schedule Management
  Future<List<Course>> getCoursesBySchedule(String dayOfWeek, String time) async {
    try {
      final querySnapshot = await _coursesCollection.get();
      
      final courses = querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Filter by schedule
      return courses.where((course) => 
          course.schedule.dayOfWeek == dayOfWeek &&
          course.schedule.startTime == time
      ).toList();
    } catch (e) {
      print('Get courses by schedule error: $e');
      return [];
    }
  }

  Future<Map<String, List<Course>>> getStudentSchedule(String studentId, String semester) async {
    try {
      final registrations = await getStudentRegistrations(studentId, semester: semester);
      final registeredCourseCodes = registrations.map((reg) => reg.courseCode).toList();

      final schedule = <String, List<Course>>{};
      
      for (String courseCode in registeredCourseCodes) {
        final course = await getCourse(courseCode);
        if (course != null) {
          final day = course.schedule.dayOfWeek;
          if (!schedule.containsKey(day)) {
            schedule[day] = [];
          }
          schedule[day]!.add(course);
        }
      }

      // Sort courses by start time for each day
      schedule.forEach((day, courses) {
        courses.sort((a, b) => a.schedule.startTime.compareTo(b.schedule.startTime));
      });

      return schedule;
    } catch (e) {
      print('Get student schedule error: $e');
      return {};
    }
  }

  // Statistics and Analytics
  Future<Map<String, dynamic>> getCourseStatistics(String courseCode) async {
    try {
      final course = await getCourse(courseCode);
      if (course == null) {
        return {};
      }

      final registrations = await _registrationsCollection
          .where('course_code', isEqualTo: courseCode)
          .get();

      final registrationList = registrations.docs
          .map((doc) => CourseRegistration.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final registered = registrationList.where((reg) => reg.isRegistered).length;
      final dropped = registrationList.where((reg) => reg.isDropped).length;
      final completed = registrationList.where((reg) => reg.isCompleted).length;
      final failed = registrationList.where((reg) => reg.isFailed).length;

      return {
        'course': course.toMap(),
        'totalRegistrations': registrationList.length,
        'currentlyRegistered': registered,
        'dropped': dropped,
        'completed': completed,
        'failed': failed,
        'completionRate': registrationList.isNotEmpty ? (completed / registrationList.length) * 100 : 0,
        'dropRate': registrationList.isNotEmpty ? (dropped / registrationList.length) * 100 : 0,
        'enrollmentPercentage': course.enrollmentPercentage,
      };
    } catch (e) {
      print('Get course statistics error: $e');
      return {};
    }
  }

  // Helper methods
  Future<void> updateCourseEnrollment(String courseCode, int newEnrollment) async {
    try {
      final querySnapshot = await _coursesCollection
          .where('course_code', isEqualTo: courseCode)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'current_enrolled': newEnrollment,
        });
      }
    } catch (e) {
      print('Update course enrollment error: $e');
    }
  }

  // Migration from local storage
  Future<void> migrateFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_courses');
      
      if (localData != null) {
        List<dynamic> decoded = jsonDecode(localData);
        List<Map<String, dynamic>> localCourses = decoded
            .map((c) => Map<String, dynamic>.from(c))
            .toList();

        for (var courseData in localCourses) {
          // Create a basic course with default schedule
          final course = Course(
            courseCode: courseData['courseCode'] ?? courseData['_id'] ?? '',
            courseTitle: courseData['courseTitle'] ?? '',
            creditHours: courseData['creditHours'] ?? 3,
            instructor: courseData['instructor'] ?? '',
            semester: courseData['semester'] ?? '',
            schedule: CourseSchedule(
              dayOfWeek: 'Monday',
              startTime: '09:00',
              endTime: '10:30',
            ),
          );
          
          await addCourse(course);
        }

        // Clear local storage after migration
        await prefs.remove('local_courses');
      }
    } catch (e) {
      print('Migrate from local storage error: $e');
    }
  }
}
