import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Notification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'lecture', 'grade', 'system'

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'system',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'system',
    );
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _notificationsKey = 'notifications';

  // Enhanced Notification class with additional fields
  Future<void> addNotification({
    required String title,
    required String message,
    required String userId,
    String type = 'system',
    Map<String, dynamic>? data,
    bool isRead = false,
  }) async {
    try {
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'message': message,
        'userId': userId,
        'timestamp': Timestamp.now(),
        'isRead': isRead,
        'type': type,
        'data': data ?? {},
        'priority': _getPriority(type),
      };

      await _firestore
          .collection('notifications')
          .doc(notification['id'] as String)
          .set(notification);

      // Also save to local storage as fallback
      await _saveToLocalStorage(notification);
    } catch (e) {
      print('Add notification error: $e');
      // Fallback to local storage only
      await _addNotificationLocal(title, message, type, data);
    }
  }

  // Specific notification methods
  Future<void> notifyCourseRegistration({
    required String studentId,
    required String courseCode,
    required String courseTitle,
    required String lectureName,
  }) async {
    await addNotification(
      title: 'Course Registered',
      message: 'You have been registered in $courseCode - $courseTitle. Lecture: $lectureName',
      userId: studentId,
      type: 'course_registration',
      data: {
        'courseCode': courseCode,
        'courseTitle': courseTitle,
        'lectureName': lectureName,
      },
    );
  }

  Future<void> notifyGradeAdded({
    required String studentId,
    required String courseCode,
    required String courseTitle,
    required String letterGrade,
    required double totalScore,
  }) async {
    await addNotification(
      title: 'Grade Posted',
      message: 'Your grade for $courseCode has been posted: $letterGrade ($totalScore%)',
      userId: studentId,
      type: 'grade',
      data: {
        'courseCode': courseCode,
        'courseTitle': courseTitle,
        'letterGrade': letterGrade,
        'totalScore': totalScore,
      },
    );
  }

  Future<void> notifyStudentAdded({
    required String studentId,
    required String studentName,
  }) async {
    await addNotification(
      title: 'Welcome to GradeLink',
      message: 'Your account has been created successfully. Welcome, $studentName!',
      userId: studentId,
      type: 'system',
      data: {
        'studentName': studentName,
      },
    );
  }

  Future<void> notifyLectureUpdate({
    required String studentId,
    required String courseCode,
    required String lectureName,
    required String updateType,
    required String updateDetails,
  }) async {
    await addNotification(
      title: 'Lecture Update',
      message: '$updateType for $courseCode - $lectureName: $updateDetails',
      userId: studentId,
      type: 'lecture',
      data: {
        'courseCode': courseCode,
        'lectureName': lectureName,
        'updateType': updateType,
        'updateDetails': updateDetails,
      },
    );
  }

  Future<void> addNotificationModel(Notification notification, {String? userId}) async {
    try {
      final notificationData = {
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'userId': userId ?? 'anonymous',
        'timestamp': Timestamp.fromDate(notification.timestamp),
        'isRead': notification.isRead,
        'type': notification.type,
        'data': {},
        'priority': _getPriority(notification.type),
      };

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notificationData);

      // Also save to local storage as fallback
      await _saveToLocalStorage(notificationData);
    } catch (e) {
      print('Add notification model error: $e');
      // Fallback to local storage only
      await _addNotificationLocal(notification.title, notification.message, notification.type);
    }
  }

  Future<List<Notification>> getNotifications({String? userId}) async {
    try {
      Query query = _firestore.collection('notifications');
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Notification(
          id: data['id'],
          title: data['title'],
          message: data['message'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isRead: data['isRead'] ?? false,
          type: data['type'] ?? 'system',
        );
      }).toList();

      // Merge with local storage notifications
      final localNotifications = await _getNotificationsLocal();
      final mergedNotifications = [...notifications, ...localNotifications];
      
      // Remove duplicates and sort
      final seenIds = <String>{};
      final uniqueNotifications = <Notification>[];
      
      for (var notification in mergedNotifications) {
        if (!seenIds.contains(notification.id)) {
          seenIds.add(notification.id);
          uniqueNotifications.add(notification);
        }
      }
      
      uniqueNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return uniqueNotifications.take(50).toList();
    } catch (e) {
      print('Get notifications error: $e');
      // Fallback to local storage
      return await _getNotificationsLocal();
    }
  }

  Future<int> getUnreadCount({String? userId}) async {
    try {
      Query query = _firestore.collection('notifications');
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      final snapshot = await query.where('isRead', isEqualTo: false).get();
      
      // Count local unread notifications
      final localUnread = (await _getNotificationsLocal())
          .where((n) => !n.isRead)
          .length;
      
      return snapshot.docs.length + localUnread;
    } catch (e) {
      print('Get unread count error: $e');
      // Fallback to local storage
      final notifications = await _getNotificationsLocal();
      return notifications.where((n) => !n.isRead).length;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Also update local storage
      await _markAsReadLocal(notificationId);
    } catch (e) {
      print('Mark as read error: $e');
      // Fallback to local storage
      await _markAsReadLocal(notificationId);
    }
  }

  Future<void> markAllAsRead({String? userId}) async {
    try {
      Query query = _firestore.collection('notifications');
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      final snapshot = await query.where('isRead', isEqualTo: false).get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Also update local storage
      await _markAllAsReadLocal();
    } catch (e) {
      print('Mark all as read error: $e');
      // Fallback to local storage
      await _markAllAsReadLocal();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      
      // Also delete from local storage
      await _deleteNotificationLocal(notificationId);
    } catch (e) {
      print('Delete notification error: $e');
      // Fallback to local storage
      await _deleteNotificationLocal(notificationId);
    }
  }

  Future<void> clearAllNotifications({String? userId}) async {
    try {
      Query query = _firestore.collection('notifications');
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      final snapshot = await query.get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Also clear local storage
      await _clearAllNotificationsLocal();
    } catch (e) {
      print('Clear all notifications error: $e');
      // Fallback to local storage
      await _clearAllNotificationsLocal();
    }
  }

  // Advanced notification methods
  Future<List<Notification>> getNotificationsByType(String type, {String? userId}) async {
    try {
      Query query = _firestore.collection('notifications').where('type', isEqualTo: type);
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Notification(
          id: data['id'],
          title: data['title'],
          message: data['message'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isRead: data['isRead'] ?? false,
          type: data['type'] ?? 'system',
        );
      }).toList();
    } catch (e) {
      print('Get notifications by type error: $e');
      return [];
    }
  }

  Future<List<Notification>> getUnreadNotifications({String? userId}) async {
    try {
      Query query = _firestore.collection('notifications').where('isRead', isEqualTo: false);
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Notification(
          id: data['id'],
          title: data['title'],
          message: data['message'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isRead: data['isRead'] ?? false,
          type: data['type'] ?? 'system',
        );
      }).toList();
    } catch (e) {
      print('Get unread notifications error: $e');
      return [];
    }
  }

  Future<void> sendGradeNotification(String studentId, String courseCode, String grade) async {
    await addNotification(
      title: 'Grade Posted',
      message: 'Your grade for $courseCode has been posted: $grade',
      userId: studentId,
      type: 'grade',
      data: {'courseCode': courseCode, 'grade': grade},
    );
  }

  Future<void> sendAssignmentNotification(String studentId, String courseCode, String assignmentTitle, DateTime dueDate) async {
    await addNotification(
      title: 'Assignment Due',
      message: '$assignmentTitle for $courseCode is due on ${dueDate.toString().split(' ')[0]}',
      userId: studentId,
      type: 'assignment',
      data: {'courseCode': courseCode, 'assignmentTitle': assignmentTitle, 'dueDate': dueDate.toIso8601String()},
    );
  }

  Future<void> sendSystemNotification(String title, String message, {String? userId}) async {
    await addNotification(
      title: title,
      message: message,
      userId: userId ?? 'all',
      type: 'system',
    );
  }

  Future<Map<String, dynamic>> getNotificationStats({String? userId}) async {
    try {
      Query query = _firestore.collection('notifications');
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      final snapshot = await query.get();
      
      final notifications = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      final total = notifications.length;
      final unread = notifications.where((n) => !(n['isRead'] ?? false)).length;
      
      final typeStats = <String, int>{};
      for (var notification in notifications) {
        final type = notification['type'] as String? ?? 'system';
        typeStats[type] = (typeStats[type] ?? 0) + 1;
      }
      
      return {
        'total': total,
        'unread': unread,
        'read': total - unread,
        'typeStats': typeStats,
        'lastNotification': notifications.isNotEmpty 
            ? (notifications.first['timestamp'] as Timestamp).toDate()
            : null,
      };
    } catch (e) {
      print('Get notification stats error: $e');
      return {
        'total': 0,
        'unread': 0,
        'read': 0,
        'typeStats': {},
        'lastNotification': null,
      };
    }
  }

  // Local storage fallback methods
  Future<void> _addNotificationLocal(String title, String message, String type, [Map<String, dynamic>? data]) async {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );

    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    List<Notification> notifications = [];

    if (notificationsJson != null) {
      final List<dynamic> list = jsonDecode(notificationsJson);
      notifications = list.map((n) => Notification.fromMap(n)).toList();
    }

    notifications.insert(0, notification);

    await prefs.setString(
      _notificationsKey,
      jsonEncode(notifications.map((n) => n.toMap()).toList()),
    );
  }

  Future<List<Notification>> _getNotificationsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson == null) return [];

    final List<dynamic> list = jsonDecode(notificationsJson);
    return list.map((n) => Notification.fromMap(n)).toList();
  }

  Future<void> _markAsReadLocal(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson == null) return;

    final List<dynamic> list = jsonDecode(notificationsJson);
    final notifications = list.map((n) => Notification.fromMap(n)).toList();

    for (int i = 0; i < notifications.length; i++) {
      if (notifications[i].id == notificationId) {
        notifications[i] = Notification(
          id: notifications[i].id,
          title: notifications[i].title,
          message: notifications[i].message,
          timestamp: notifications[i].timestamp,
          isRead: true,
          type: notifications[i].type,
        );
        break;
      }
    }

    await prefs.setString(
      _notificationsKey,
      jsonEncode(notifications.map((n) => n.toMap()).toList()),
    );
  }

  Future<void> _markAllAsReadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson == null) return;

    final List<dynamic> list = jsonDecode(notificationsJson);
    final notifications = list.map((n) => Notification.fromMap(n)).toList();

    final updatedNotifications = notifications
        .map(
          (n) => Notification(
            id: n.id,
            title: n.title,
            message: n.message,
            timestamp: n.timestamp,
            isRead: true,
            type: n.type,
          ),
        )
        .toList();

    await prefs.setString(
      _notificationsKey,
      jsonEncode(updatedNotifications.map((n) => n.toMap()).toList()),
    );
  }

  Future<void> _deleteNotificationLocal(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson == null) return;

    final List<dynamic> list = jsonDecode(notificationsJson);
    final notifications = list.map((n) => Notification.fromMap(n)).toList();

    notifications.removeWhere((n) => n.id == notificationId);

    await prefs.setString(
      _notificationsKey,
      jsonEncode(notifications.map((n) => n.toMap()).toList()),
    );
  }

  Future<void> _clearAllNotificationsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  Future<void> _saveToLocalStorage(Map<String, dynamic> notificationData) async {
    final notification = Notification(
      id: notificationData['id'],
      title: notificationData['title'],
      message: notificationData['message'],
      timestamp: (notificationData['timestamp'] as Timestamp).toDate(),
      isRead: notificationData['isRead'] ?? false,
      type: notificationData['type'] ?? 'system',
    );

    await _addNotificationLocal(notification.title, notification.message, notification.type);
  }

  static String _getPriority(String type) {
    switch (type) {
      case 'grade':
        return 'high';
      case 'assignment':
        return 'medium';
      case 'lecture':
        return 'low';
      default:
        return 'normal';
    }
  }

  // Demo notifications for testing
  Future<void> initializeDemoNotifications() async {
    try {
      final notifications = await getNotifications();
      
      if (notifications.isEmpty) {
        final demoNotifications = [
          {
            'title': 'New Lecture Posted',
            'message': 'Dr. Smith posted a new lecture for CS101: Introduction to Programming',
            'type': 'lecture',
            'userId': 'demo_user',
          },
          {
            'title': 'Grade Updated',
            'message': 'Your grade for MATH201: Calculus I has been updated',
            'type': 'grade',
            'userId': 'demo_user',
          },
          {
            'title': 'Assignment Due',
            'message': 'CS102: Data Structures assignment is due tomorrow',
            'type': 'assignment',
            'userId': 'demo_user',
          },
        ];

        for (final notification in demoNotifications) {
          await addNotification(
            title: notification['title'] ?? '',
            message: notification['message'] ?? '',
            userId: notification['userId'] ?? '',
            type: notification['type'] ?? 'system',
          );
        }
      }
    } catch (e) {
      print('Initialize demo notifications error: $e');
    }
  }
}
