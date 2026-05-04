import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealtimeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Listen for student data changes (admin -> student communication)
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToStudentData(String studentId) {
    return _firestore
        .collection('students')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null)
        .where((doc) => doc != null)
        .cast<DocumentSnapshot<Map<String, dynamic>>>();
  }

  // Listen for grade changes for a specific student
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToStudentGrades(String studentId) {
    return _firestore
        .collection('grades')
        .where('student_id', isEqualTo: studentId)
        .snapshots();
  }

  // Listen for course changes
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToCourses() {
    return _firestore.collection('courses').snapshots();
  }

  // Listen for admin notifications (student -> admin communication)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToAdminNotifications() {
    return _firestore
        .collection('notifications')
        .where('type', isEqualTo: 'admin')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Send notification from student to admin
  Future<void> sendNotificationToAdmin({
    required String title,
    required String message,
    required String studentId,
    String type = 'student_request',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'student_id': studentId,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  // Update student data with real-time sync
  Future<void> updateStudentWithSync({
    required String studentId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      // Update in Firestore
      final studentQuery = await _firestore
          .collection('students')
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        await studentQuery.docs.first.reference.update(updates);
        
        // Send notification to admin about the update
        await sendNotificationToAdmin(
          title: 'Student Profile Updated',
          message: 'Student $studentId has updated their profile',
          studentId: studentId,
          type: 'profile_update',
        );
      }
    } catch (e) {
      print('Error updating student with sync: $e');
      rethrow;
    }
  }

  // Get real-time student count (for admin dashboard)
  Stream<int> getStudentCount() {
    return _firestore.collection('students').snapshots().map((snapshot) => snapshot.docs.length);
  }

  // Get real-time course count (for admin dashboard)
  Stream<int> getCourseCount() {
    return _firestore.collection('courses').snapshots().map((snapshot) => snapshot.docs.length);
  }

  // Get real-time grade count (for admin dashboard)
  Stream<int> getGradeCount() {
    return _firestore.collection('grades').snapshots().map((snapshot) => snapshot.docs.length);
  }

  // Listen for new students (admin only)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenForNewStudents() {
    return _firestore
        .collection('students')
        .orderBy('created_at', descending: true)
        .limit(10)
        .snapshots();
  }

  // Listen for new grades (admin only)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenForNewGrades() {
    return _firestore
        .collection('grades')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  // Check if student has pending updates from admin
  Future<bool> hasPendingUpdates(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('pending_updates')
          .where('student_id', isEqualTo: studentId)
          .where('applied', isEqualTo: false)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending updates: $e');
      return false;
    }
  }

  // Mark pending update as applied
  Future<void> markUpdateAsApplied(String updateId) async {
    try {
      await _firestore
          .collection('pending_updates')
          .doc(updateId)
          .update({'applied': true});
    } catch (e) {
      print('Error marking update as applied: $e');
      rethrow;
    }
  }
}