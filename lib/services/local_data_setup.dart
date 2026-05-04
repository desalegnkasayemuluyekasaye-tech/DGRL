import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/grade.dart';

class LocalDataSetup {
  static Future<void> initializeSampleData() async {
    try {
      print('Initializing sample data for local development...');
      
      // Clear existing data (optional)
      await clearAllData();
      
      // Add sample students
      await addSampleStudents();
      
      // Add sample courses
      await addSampleCourses();
      
      // Add sample grades
      await addSampleGrades();
      
      print('Sample data initialization completed!');
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }
  
  static Future<void> clearAllData() async {
    final firestore = FirebaseFirestore.instance;
    
    // Clear collections
    final collections = ['students', 'courses', 'grades', 'notifications'];
    
    for (final collection in collections) {
      final snapshot = await firestore.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
    
    print('Cleared all existing data');
  }
  
  static Future<void> addSampleStudents() async {
    final firestore = FirebaseFirestore.instance;
    final students = [
      // Computer Science Students
      Student(
        studentId: 'cs_student001',
        fullName: 'Alice Chen',
        email: 'alice.chen@university.edu',
        password: 'password123',
        phone: '+1234567890',
        age: 20,
        sex: 'Female',
        department: 'Computer Science',
        batch: '2025',
        photoUrl: null,
      ),
      Student(
        studentId: 'cs_student002',
        fullName: 'Bob Williams',
        email: 'bob.williams@university.edu',
        password: 'password123',
        phone: '+1234567891',
        age: 21,
        sex: 'Male',
        department: 'Computer Science',
        batch: '2025',
        photoUrl: null,
      ),
      Student(
        studentId: 'cs_student003',
        fullName: 'Carol Martinez',
        email: 'carol.martinez@university.edu',
        password: 'password123',
        phone: '+1234567892',
        age: 19,
        sex: 'Female',
        department: 'Computer Science',
        batch: '2025',
        photoUrl: null,
      ),
      Student(
        studentId: 'cs_student004',
        fullName: 'David Kim',
        email: 'david.kim@university.edu',
        password: 'password123',
        phone: '+1234567893',
        age: 22,
        sex: 'Male',
        department: 'Computer Science',
        batch: '2025',
        photoUrl: null,
      ),
      Student(
        studentId: 'cs_student005',
        fullName: 'Emma Thompson',
        email: 'emma.thompson@university.edu',
        password: 'password123',
        phone: '+1234567894',
        age: 20,
        sex: 'Female',
        department: 'Computer Science',
        batch: '2025',
        photoUrl: null,
      ),
    ];
    
    for (final student in students) {
      await firestore.collection('students').doc(student.studentId).set(student.toMap());
    }
    
    print('Added ${students.length} sample students');
  }
  
  static Future<void> addSampleCourses() async {
    final firestore = FirebaseFirestore.instance;
    final courses = [
      // Computer Science Core Courses
      Course(
        courseCode: 'CS101',
        courseTitle: 'Introduction to Computer Science',
        creditHours: 3,
        instructor: 'Dr. Alice Brown',
        semester: 'Fall 2025',
        department: 'Computer Science',
        description: 'Fundamentals of programming and computer science concepts',
        schedule: CourseSchedule(
          dayOfWeek: 'Monday',
          startTime: '09:00',
          endTime: '10:30',
          scheduleType: 'lecture',
        ),
      ),
      Course(
        courseCode: 'CS102',
        courseTitle: 'Programming Fundamentals',
        creditHours: 4,
        instructor: 'Dr. Robert Davis',
        semester: 'Fall 2025',
        department: 'Computer Science',
        description: 'Advanced programming concepts and problem-solving techniques',
        schedule: CourseSchedule(
          dayOfWeek: 'Tuesday',
          startTime: '10:00',
          endTime: '11:30',
          scheduleType: 'lecture',
        ),
      ),
      Course(
        courseCode: 'CS201',
        courseTitle: 'Data Structures and Algorithms',
        creditHours: 4,
        instructor: 'Dr. John Miller',
        semester: 'Fall 2025',
        department: 'Computer Science',
        description: 'Advanced data structures, algorithms, and complexity analysis',
        schedule: CourseSchedule(
          dayOfWeek: 'Wednesday',
          startTime: '14:00',
          endTime: '15:30',
          scheduleType: 'lecture',
        ),
      ),
      Course(
        courseCode: 'CS202',
        courseTitle: 'Computer Organization',
        creditHours: 3,
        instructor: 'Dr. Sarah Wilson',
        semester: 'Fall 2025',
        department: 'Computer Science',
        description: 'Computer architecture, assembly language, and system design',
        schedule: CourseSchedule(
          dayOfWeek: 'Thursday',
          startTime: '11:00',
          endTime: '12:30',
          scheduleType: 'lecture',
        ),
      ),
      Course(
        courseCode: 'CS301',
        courseTitle: 'Operating Systems',
        creditHours: 4,
        instructor: 'Dr. Emily Chen',
        semester: 'Fall 2025',
        department: 'Computer Science',
        description: 'Process management, memory management, and file systems',
        schedule: CourseSchedule(
          dayOfWeek: 'Friday',
          startTime: '13:00',
          endTime: '14:30',
          scheduleType: 'lecture',
        ),
      ),
      Course(
        courseCode: 'CS302',
        courseTitle: 'Database Management Systems',
        creditHours: 3,
        instructor: 'Dr. Michael Johnson',
        semester: 'Fall 2025',
        department: 'Computer Science',
        description: 'Database design, SQL, and data management principles',
        schedule: CourseSchedule(
          dayOfWeek: 'Monday',
          startTime: '15:00',
          endTime: '16:30',
          scheduleType: 'lecture',
        ),
      ),
      Course(
        courseCode: 'CS401',
        courseTitle: 'Software Engineering',
        creditHours: 4,
        instructor: 'Dr. David Lee',
        semester: 'Fall 2025',
        department: 'Computer Science',
        description: 'Software development lifecycle, design patterns, and project management',
        schedule: CourseSchedule(
          dayOfWeek: 'Tuesday',
          startTime: '16:00',
          endTime: '17:30',
          scheduleType: 'lecture',
        ),
      ),
    ];
    
    for (final course in courses) {
      await firestore.collection('courses').add(course.toMap());
    }
    
    print('Added ${courses.length} sample courses');
  }
  
  static Future<void> addSampleGrades() async {
    final firestore = FirebaseFirestore.instance;
    final grades = [
      // Alice Chen's grades
      Grade.create(
        studentId: 'cs_student001',
        courseCode: 'CS101',
        semester: 'Fall 2025',
        midScore: 92.0,
        assignmentScore: 88.0,
        finalScore: 90.0,
      ),
      Grade.create(
        studentId: 'cs_student001',
        courseCode: 'CS102',
        semester: 'Fall 2025',
        midScore: 85.0,
        assignmentScore: 87.0,
        finalScore: 86.0,
      ),
      Grade.create(
        studentId: 'cs_student001',
        courseCode: 'CS201',
        semester: 'Fall 2025',
        midScore: 88.0,
        assignmentScore: 90.0,
        finalScore: 89.0,
      ),
      Grade.create(
        studentId: 'cs_student001',
        courseCode: 'CS202',
        semester: 'Fall 2025',
        midScore: 90.0,
        assignmentScore: 92.0,
        finalScore: 91.0,
      ),
      Grade.create(
        studentId: 'cs_student001',
        courseCode: 'CS301',
        semester: 'Fall 2025',
        midScore: 86.0,
        assignmentScore: 88.0,
        finalScore: 87.0,
      ),
      Grade.create(
        studentId: 'cs_student001',
        courseCode: 'CS302',
        semester: 'Fall 2025',
        midScore: 89.0,
        assignmentScore: 91.0,
        finalScore: 90.0,
      ),
      Grade.create(
        studentId: 'cs_student001',
        courseCode: 'CS401',
        semester: 'Fall 2025',
        midScore: 93.0,
        assignmentScore: 95.0,
        finalScore: 94.0,
      ),
      
      // Bob Williams's grades
      Grade.create(
        studentId: 'cs_student002',
        courseCode: 'CS101',
        semester: 'Fall 2025',
        midScore: 78.0,
        assignmentScore: 82.0,
        finalScore: 80.0,
      ),
      Grade.create(
        studentId: 'cs_student002',
        courseCode: 'CS102',
        semester: 'Fall 2025',
        midScore: 83.0,
        assignmentScore: 85.0,
        finalScore: 84.0,
      ),
      Grade.create(
        studentId: 'cs_student002',
        courseCode: 'CS201',
        semester: 'Fall 2025',
        midScore: 81.0,
        assignmentScore: 83.0,
        finalScore: 82.0,
      ),
      Grade.create(
        studentId: 'cs_student002',
        courseCode: 'CS202',
        semester: 'Fall 2025',
        midScore: 85.0,
        assignmentScore: 87.0,
        finalScore: 86.0,
      ),
      Grade.create(
        studentId: 'cs_student002',
        courseCode: 'CS301',
        semester: 'Fall 2025',
        midScore: 79.0,
        assignmentScore: 81.0,
        finalScore: 80.0,
      ),
      Grade.create(
        studentId: 'cs_student002',
        courseCode: 'CS302',
        semester: 'Fall 2025',
        midScore: 82.0,
        assignmentScore: 84.0,
        finalScore: 83.0,
      ),
      Grade.create(
        studentId: 'cs_student002',
        courseCode: 'CS401',
        semester: 'Fall 2025',
        midScore: 87.0,
        assignmentScore: 89.0,
        finalScore: 88.0,
      ),
      
      // Carol Martinez's grades
      Grade.create(
        studentId: 'cs_student003',
        courseCode: 'CS101',
        semester: 'Fall 2025',
        midScore: 95.0,
        assignmentScore: 93.0,
        finalScore: 94.0,
      ),
      Grade.create(
        studentId: 'cs_student003',
        courseCode: 'CS102',
        semester: 'Fall 2025',
        midScore: 88.0,
        assignmentScore: 90.0,
        finalScore: 89.0,
      ),
      Grade.create(
        studentId: 'cs_student003',
        courseCode: 'CS201',
        semester: 'Fall 2025',
        midScore: 91.0,
        assignmentScore: 93.0,
        finalScore: 92.0,
      ),
      Grade.create(
        studentId: 'cs_student003',
        courseCode: 'CS202',
        semester: 'Fall 2025',
        midScore: 89.0,
        assignmentScore: 91.0,
        finalScore: 90.0,
      ),
      Grade.create(
        studentId: 'cs_student003',
        courseCode: 'CS301',
        semester: 'Fall 2025',
        midScore: 92.0,
        assignmentScore: 94.0,
        finalScore: 93.0,
      ),
      Grade.create(
        studentId: 'cs_student003',
        courseCode: 'CS302',
        semester: 'Fall 2025',
        midScore: 90.0,
        assignmentScore: 92.0,
        finalScore: 91.0,
      ),
      Grade.create(
        studentId: 'cs_student003',
        courseCode: 'CS401',
        semester: 'Fall 2025',
        midScore: 94.0,
        assignmentScore: 96.0,
        finalScore: 95.0,
      ),
      
      // David Kim's grades
      Grade.create(
        studentId: 'cs_student004',
        courseCode: 'CS101',
        semester: 'Fall 2025',
        midScore: 76.0,
        assignmentScore: 78.0,
        finalScore: 77.0,
      ),
      Grade.create(
        studentId: 'cs_student004',
        courseCode: 'CS102',
        semester: 'Fall 2025',
        midScore: 81.0,
        assignmentScore: 83.0,
        finalScore: 82.0,
      ),
      Grade.create(
        studentId: 'cs_student004',
        courseCode: 'CS201',
        semester: 'Fall 2025',
        midScore: 84.0,
        assignmentScore: 86.0,
        finalScore: 85.0,
      ),
      Grade.create(
        studentId: 'cs_student004',
        courseCode: 'CS202',
        semester: 'Fall 2025',
        midScore: 82.0,
        assignmentScore: 84.0,
        finalScore: 83.0,
      ),
      Grade.create(
        studentId: 'cs_student004',
        courseCode: 'CS301',
        semester: 'Fall 2025',
        midScore: 85.0,
        assignmentScore: 87.0,
        finalScore: 86.0,
      ),
      Grade.create(
        studentId: 'cs_student004',
        courseCode: 'CS302',
        semester: 'Fall 2025',
        midScore: 83.0,
        assignmentScore: 85.0,
        finalScore: 84.0,
      ),
      Grade.create(
        studentId: 'cs_student004',
        courseCode: 'CS401',
        semester: 'Fall 2025',
        midScore: 88.0,
        assignmentScore: 90.0,
        finalScore: 89.0,
      ),
      
      // Emma Thompson's grades
      Grade.create(
        studentId: 'cs_student005',
        courseCode: 'CS101',
        semester: 'Fall 2025',
        midScore: 91.0,
        assignmentScore: 89.0,
        finalScore: 90.0,
      ),
      Grade.create(
        studentId: 'cs_student005',
        courseCode: 'CS102',
        semester: 'Fall 2025',
        midScore: 87.0,
        assignmentScore: 89.0,
        finalScore: 88.0,
      ),
      Grade.create(
        studentId: 'cs_student005',
        courseCode: 'CS201',
        semester: 'Fall 2025',
        midScore: 90.0,
        assignmentScore: 92.0,
        finalScore: 91.0,
      ),
      Grade.create(
        studentId: 'cs_student005',
        courseCode: 'CS202',
        semester: 'Fall 2025',
        midScore: 88.0,
        assignmentScore: 90.0,
        finalScore: 89.0,
      ),
      Grade.create(
        studentId: 'cs_student005',
        courseCode: 'CS301',
        semester: 'Fall 2025',
        midScore: 91.0,
        assignmentScore: 93.0,
        finalScore: 92.0,
      ),
      Grade.create(
        studentId: 'cs_student005',
        courseCode: 'CS302',
        semester: 'Fall 2025',
        midScore: 93.0,
        assignmentScore: 95.0,
        finalScore: 94.0,
      ),
      Grade.create(
        studentId: 'cs_student005',
        courseCode: 'CS401',
        semester: 'Fall 2025',
        midScore: 95.0,
        assignmentScore: 97.0,
        finalScore: 96.0,
      ),
    ];
    
    for (final grade in grades) {
      await firestore.collection('grades').add(grade.toMap());
    }
    
    print('Added ${grades.length} sample grades');
  }
  
  static Future<void> addSampleNotifications() async {
    final firestore = FirebaseFirestore.instance;
    final notifications = [
      // Welcome notifications for CS students
      {
        'title': 'Welcome to GradeLink',
        'message': 'Welcome to Computer Science Department, Alice Chen!',
        'userId': 'cs_student001',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'system',
        'data': {'studentName': 'Alice Chen', 'department': 'Computer Science'},
      },
      {
        'title': 'Welcome to GradeLink',
        'message': 'Welcome to Computer Science Department, Bob Williams!',
        'userId': 'cs_student002',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'system',
        'data': {'studentName': 'Bob Williams', 'department': 'Computer Science'},
      },
      {
        'title': 'Welcome to GradeLink',
        'message': 'Welcome to Computer Science Department, Carol Martinez!',
        'userId': 'cs_student003',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'system',
        'data': {'studentName': 'Carol Martinez', 'department': 'Computer Science'},
      },
      {
        'title': 'Welcome to GradeLink',
        'message': 'Welcome to Computer Science Department, David Kim!',
        'userId': 'cs_student004',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'system',
        'data': {'studentName': 'David Kim', 'department': 'Computer Science'},
      },
      {
        'title': 'Welcome to GradeLink',
        'message': 'Welcome to Computer Science Department, Emma Thompson!',
        'userId': 'cs_student005',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'system',
        'data': {'studentName': 'Emma Thompson', 'department': 'Computer Science'},
      },
      
      // Course registration notifications
      {
        'title': 'Course Registration',
        'message': 'You have been registered in CS101 - Introduction to Computer Science',
        'userId': 'cs_student001',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'course_registration',
        'data': {
          'courseCode': 'CS101',
          'courseTitle': 'Introduction to Computer Science',
          'lectureName': 'Dr. Alice Brown',
        },
      },
      {
        'title': 'Course Registration',
        'message': 'You have been registered in CS102 - Programming Fundamentals',
        'userId': 'cs_student001',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'course_registration',
        'data': {
          'courseCode': 'CS102',
          'courseTitle': 'Programming Fundamentals',
          'lectureName': 'Dr. Robert Davis',
        },
      },
      
      // Grade notifications
      {
        'title': 'Grade Posted',
        'message': 'Your grade for CS101 has been posted: A- (90.0%)',
        'userId': 'cs_student001',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'grade',
        'data': {
          'courseCode': 'CS101',
          'letterGrade': 'A-',
          'totalScore': 90.0,
        },
      },
      {
        'title': 'Grade Posted',
        'message': 'Your grade for CS401 has been posted: A (96.0%)',
        'userId': 'cs_student005',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'grade',
        'data': {
          'courseCode': 'CS401',
          'letterGrade': 'A',
          'totalScore': 96.0,
        },
      },
    ];
    
    for (final notification in notifications) {
      await firestore.collection('notifications').add({
        ...notification,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    }
    
    print('Added ${notifications.length} sample notifications');
  }
}
