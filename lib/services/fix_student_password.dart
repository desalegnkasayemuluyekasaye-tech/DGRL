import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FixStudentPassword {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fix all student passwords by creating/updating Firebase Auth users
  Future<Map<String, dynamic>> fixAllStudentPasswords(String defaultPassword) async {
    final results = {
      'total': 0,
      'success': 0,
      'failed': 0,
      'errors': <String>[],
    };

    try {
      final students = await _firestore.collection('students').get();
      results['total'] = students.docs.length;

      for (final doc in students.docs) {
        final data = doc.data();
        final email = data['email'] as String?;
        final studentId = data['student_id'] as String?;

        if (email == null || studentId == null) {
          results['failed'] = (results['failed'] as int) + 1;
          (results['errors'] as List<String>).add('Missing email/ID for ${doc.id}');
          continue;
        }

        try {
          // Try to sign in first to check if user exists
          try {
            await _auth.signInWithEmailAndPassword(
              email: email,
              password: defaultPassword,
            );
            // If successful, user exists and password is correct
            results['success'] = (results['success'] as int) + 1;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-not-found') {
              // Create user
              final result = await _auth.createUserWithEmailAndPassword(
                email: email,
                password: defaultPassword,
              );

              if (result.user != null) {
                // Update Firestore with UID
                await _firestore.collection('students').doc(doc.id).update({
                  'uid': result.user!.uid,
                  'password': defaultPassword,
                });
                results['success'] = (results['success'] as int) + 1;
              }
            } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
              // Update password (requires admin SDK or re-authentication)
              results['failed'] = (results['failed'] as int) + 1;
              (results['errors'] as List<String>).add(
                  'Password mismatch for $studentId - needs manual update');
            }
          }
        } catch (e) {
          results['failed'] = (results['failed'] as int) + 1;
          (results['errors'] as List<String>).add('Error for $studentId: $e');
        }
      }
    } catch (e) {
      (results['errors'] as List<String>).add('General error: $e');
    }

    return results;
  }

  // Fix single student password
  Future<bool> fixStudentPassword(String studentId, String newPassword) async {
    try {
      final studentDoc = await _firestore
          .collection('students')
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();

      if (studentDoc.docs.isEmpty) {
        print('Student not found: $studentId');
        return false;
      }

      final data = studentDoc.docs.first.data();
      final email = data['email'] as String?;

      if (email == null) {
        print('Student email not found');
        return false;
      }

      // Create or update Firebase Auth user
      try {
        final result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: newPassword,
        );

        if (result.user != null) {
          await _firestore
              .collection('students')
              .doc(studentDoc.docs.first.id)
              .update({
            'uid': result.user!.uid,
            'password': newPassword,
          });
          print('Created Firebase Auth user for $studentId');
          return true;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // User exists, try to update password
          print('User already exists for $studentId - need admin SDK to update password');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error fixing password for $studentId: $e');
      return false;
    }
  }
}
