import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/grade.dart';
import '../models/course.dart';
import '../services/auth_service.dart';
import '../services/grade_service.dart';
import '../services/notification_service.dart';
import '../services/realtime_service.dart';

class AppProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final GradeService _gradeService = GradeService();
  final NotificationService _notificationService = NotificationService();
  final RealtimeService _realtimeService = RealtimeService();

  Student? _currentStudent;
  List<Grade> _grades = [];
  List<String> _semesters = [];
  double _gpa = 0.0;
  double _cgpa = 0.0;
  double _selectedGPA = 0.0;
  String _selectedSemester = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;
  List<Course> _courses = [];
  List<Notification> _notifications = [];
  int _unreadNotificationCount = 0;

  Student? get currentStudent => _currentStudent;
  List<Grade> get grades => _grades;
  List<String> get semesters => _semesters;
  double get gpa => _gpa;
  double get cgpa => _cgpa;
  double get selectedGPA => _selectedGPA;
  String get selectedSemester => _selectedSemester;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  List<Course> get courses => _courses;
  List<Notification> get notifications => _notifications;
  int get unreadNotificationCount => _unreadNotificationCount;
  AuthService get authService => _authService;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();

      if (_isLoggedIn) {
        final userData = await _authService.getCurrentUser();
        if (userData != null && userData['studentId'] != null) {
          _currentStudent = Student.fromMap(userData);
          await loadStudentData();
        }
      }
    } catch (_) {
      _isLoggedIn = false;
      _currentStudent = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String id, String password, bool isAdmin) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authService.login(id, password, isAdmin);

    if (success) {
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        if (isAdmin) {
          _currentStudent = null;
        } else {
          _currentStudent = Student.fromMap(userData);
          await loadStudentData();
        }
      }
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentStudent = null;
    _grades = [];
    _semesters = [];
    _gpa = 0.0;
    _cgpa = 0.0;
    _selectedSemester = '';
    _selectedGPA = 0.0;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> loadStudentData() async {
    if (_currentStudent == null) return;

    _grades = await _gradeService.getGradesForStudent(
      _currentStudent!.studentId,
    );
    _semesters = await _gradeService.getSemesters(_currentStudent!.studentId);
    _cgpa = await _gradeService.calculateCGPA(_currentStudent!.studentId);
    _courses = await _gradeService.getAllCourses();

    if (_semesters.isNotEmpty) {
      _selectedSemester = _semesters.last;
      _selectedGPA = await _gradeService.calculateGPA(
        _currentStudent!.studentId,
        _selectedSemester,
      );
    }

    await loadNotifications();

    notifyListeners();
  }

  Future<void> loadNotifications() async {
    await _notificationService.initializeDemoNotifications();
    _notifications = await _notificationService.getNotifications();
    _unreadNotificationCount = await _notificationService.getUnreadCount();
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
    await loadNotifications();
  }

  Future<void> markAllNotificationsAsRead() async {
    await _notificationService.markAllAsRead();
    await loadNotifications();
  }

  Future<void> addNotification({
    required String title,
    required String message,
    String type = 'system',
  }) async {
    await _notificationService.addNotification(
      title: title,
      message: message,
      userId: _currentStudent?.studentId ?? 'anonymous',
      type: type,
    );
    await loadNotifications();
  }

  Future<void> selectSemester(String semester) async {
    if (_currentStudent == null) return;

    _selectedSemester = semester;
    _selectedGPA = await _gradeService.calculateGPA(
      _currentStudent!.studentId,
      semester,
    );
    notifyListeners();
  }

  List<Grade> getGradesForSemester(String semester) {
    return _grades.where((g) => g.semester == semester).toList();
  }

  Course? getCourseInfo(String courseCode) {
    try {
      return _courses.firstWhere((c) => c.courseCode == courseCode);
    } catch (_) {
      return null;
    }
  }

  Future<void> addGrade(Grade grade) async {
    await _gradeService.addGrade(grade);
    await loadStudentData();
    
    // Refresh notifications to show new grade notification
    await loadNotifications();
  }

  Future<void> addCourse(Course course) async {
    await _gradeService.addCourse(course);
    _courses = await _gradeService.getAllCourses();
    
    // Refresh notifications to show new course notification
    await loadNotifications();
    
    notifyListeners();
  }
  
  // Method to refresh all student data (called when admin adds data)
  Future<void> refreshStudentData() async {
    if (_currentStudent != null && !_isLoggedIn) return;
    
    await loadStudentData();
  }
  
  // Real-time data synchronization
  Future<void> syncWithAdmin() async {
    if (_currentStudent == null) return;
    
    // Reload grades, courses, and notifications
    await loadStudentData();
  }

  Future<void> updateStudentProfile({
    String? fullName,
    String? sex,
    String? phone,
    int? age,
    String? photoUrl,
  }) async {
    if (_currentStudent == null) {
      print('Error: No current student to update');
      return;
    }

    print(
      'Updating student profile with: fullName=$fullName, sex=$sex, phone=$phone, age=$age, photoUrl=$photoUrl',
    );

    final updatedStudent = _currentStudent!.copyWith(
      fullName: fullName,
      sex: sex,
      phone: phone,
      age: age,
      photoUrl: photoUrl,
    );

    print('Updated student object: ${updatedStudent.toMap()}');

    try {
      // Update with real-time sync
      await _realtimeService.updateStudentWithSync(
        studentId: _currentStudent!.studentId,
        updates: {
          'full_name': fullName ?? _currentStudent!.fullName,
          'sex': sex ?? _currentStudent!.sex,
          'phone': phone ?? _currentStudent!.phone,
          'age': age ?? _currentStudent!.age,
          'photo_url': photoUrl ?? _currentStudent!.photoUrl,
        },
      );
      
      _currentStudent = updatedStudent;
      notifyListeners();
      print('Student profile updated successfully with real-time sync');
    } catch (e) {
      print('Error updating student profile: $e');
      rethrow;
    }
  }

  // Real-time data sync methods
  Stream<DocumentSnapshot<Map<String, dynamic>>> getStudentDataStream() {
    if (_currentStudent == null) {
      return const Stream.empty();
    }
    return _realtimeService.listenToStudentData(_currentStudent!.studentId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentGradesStream() {
    if (_currentStudent == null) {
      return const Stream.empty();
    }
    return _realtimeService.listenToStudentGrades(_currentStudent!.studentId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCoursesStream() {
    return _realtimeService.listenToCourses();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAdminNotificationsStream() {
    return _realtimeService.listenToAdminNotifications();
  }

  Future<void> sendAdminNotification({
    required String title,
    required String message,
    String type = 'student_request',
  }) async {
    if (_currentStudent == null) return;
    
    await _realtimeService.sendNotificationToAdmin(
      title: title,
      message: message,
      studentId: _currentStudent!.studentId,
      type: type,
    );
  }

  // Check for real-time updates from admin
  Future<void> checkForAdminUpdates() async {
    if (_currentStudent == null) return;
    
    final hasUpdates = await _realtimeService.hasPendingUpdates(_currentStudent!.studentId);
    if (hasUpdates) {
      // Refresh data if there are pending updates
      await loadStudentData();
      
      // Add notification about the update
      await addNotification(
        title: 'Data Updated',
        message: 'Your academic data has been updated by the administrator',
        type: 'system_update',
      );
    }
  }

  // Initialize real-time listeners
  void initializeRealtimeListeners() {
    if (_currentStudent == null) return;
    
    // Listen for student data changes
    getStudentDataStream().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _currentStudent = Student.fromMap(data);
        notifyListeners();
      }
    });

    // Listen for grade changes
    getStudentGradesStream().listen((snapshot) async {
      _grades = await _gradeService.getGradesForStudent(_currentStudent!.studentId);
      notifyListeners();
    });

    // Listen for course changes
    getCoursesStream().listen((snapshot) async {
      _courses = await _gradeService.getAllCourses();
      notifyListeners();
    });

    // Check for admin updates periodically
    Future.delayed(const Duration(minutes: 5), () {
      checkForAdminUpdates();
    });
  }
}
