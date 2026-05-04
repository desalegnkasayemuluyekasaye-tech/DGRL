import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAuthUsers {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> createAuthForAllStudents() async {
    final results = <String, dynamic>{
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
        final email = data['email'] as String? ?? '';
        final studentId = data['student_id'] as String? ?? '';
        final password = data['password'] as String? ?? 'password123';

        if (email.isEmpty) {
          (results['errors'] as List<String>).add('No email for $studentId');
          results['failed'] = (results['failed'] as int) + 1;
          continue;
        }

        try {
          // Try to create Firebase Auth user
          final result = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (result.user != null) {
            // Update Firestore with UID
            await _firestore.collection('students').doc(doc.id).update({
              'uid': result.user!.uid,
              'password': password,
            });
            results['success'] = (results['success'] as int) + 1;
            print('Created auth for $studentId ($email)');
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // User already exists in Firebase Auth
            results['success'] = (results['success'] as int) + 1;
            print('Auth already exists for $studentId ($email)');
          } else {
            (results['errors'] as List<String>).add('$studentId: ${e.message}');
            results['failed'] = (results['failed'] as int) + 1;
          }
        } catch (e) {
          (results['errors'] as List<String>).add('$studentId: $e');
          results['failed'] = (results['failed'] as int) + 1;
        }
      }
    } catch (e) {
      (results['errors'] as List<String>).add('General error: $e');
    }

    return results;
  }

  Future<void> printAllStudents() async {
    try {
      final students = await _firestore.collection('students').get();
      print('Total students: ${students.docs.length}');
      for (final doc in students.docs) {
        final data = doc.data();
        print('ID: ${data['student_id']}, Email: ${data['email']}, Password: ${data['password']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
