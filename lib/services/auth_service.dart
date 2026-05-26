import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class AuthService {
  static const String _loggedInKey = 'logged_in_student';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _sessionUserData;

  Future<String?> _tryCachedLogin(String id, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_loggedInKey);
    if (userJson == null) return null;

    final data = jsonDecode(userJson) as Map<String, dynamic>;
    final cachedId = data['student_id'] as String?;
    final cachedEmail = data['email'] as String?;
    final cachedPassword = data['password'] as String?;
    final role = data['role'] as String?;

    final idMatches = id == cachedId || id == cachedEmail;
    if (idMatches && password == cachedPassword && role != null) {
      return role;
    }
    return null;
  }

  /// Unified login — auto-detects admin vs student.
  /// Returns 'student', 'admin', or null on failure.
  Future<String?> login(
    String id,
    String password, {
    bool remember = false,
  }) async {
    // Offline fallback: check cached credentials first
    final cached = await _tryCachedLogin(id, password);
    if (cached != null) return cached;

    try {
      // Admin: exact match on ADMIN/ADMIN123
      if (id == 'ADMIN' && password == 'ADMIN123') {
        try {
          await _auth.createUserWithEmailAndPassword(
            email: 'admin@grade.com',
            password: 'ADMIN123',
          );
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
        }

        final result = await _auth.signInWithEmailAndPassword(
          email: 'admin@grade.com',
          password: 'ADMIN123',
        );
        if (result.user != null) {
          _sessionUserData = {
            'username': 'ADMIN',
            'role': 'admin',
            'uid': result.user!.uid,
            'password': password,
          };

          final prefs = await SharedPreferences.getInstance();
          if (remember) {
            await prefs.setString(_loggedInKey, jsonEncode(_sessionUserData));
          } else {
            await prefs.remove(_loggedInKey);
          }
          return 'admin';
        }
        return null;
      }

      // Student: look up by student_id or email
      final studentQuery = await _firestore
          .collection('students')
          .where('student_id', isEqualTo: id)
          .limit(1)
          .get();

      QuerySnapshot? emailQuery;
      if (id.contains('@')) {
        emailQuery = await _firestore
            .collection('students')
            .where('email', isEqualTo: id)
            .limit(1)
            .get();
      }

      final targetDoc = studentQuery.docs.isNotEmpty
          ? studentQuery.docs.first
          : (emailQuery != null && emailQuery.docs.isNotEmpty)
          ? emailQuery.docs.first
          : null;

      if (targetDoc == null) return null;

      final studentData = targetDoc.data() as Map<String, dynamic>;
      final email = studentData['email'] as String?;
      final storedPassword = studentData['password'] as String?;

      if (email == null || storedPassword != password) return null;

      // Ensure Firebase Auth user exists
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (_) {}

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user == null) return null;

      await _firestore.collection('students').doc(targetDoc.id).update({
        'uid': result.user!.uid,
      });

      _sessionUserData = {
        ...studentData,
        'role': 'student',
        'uid': result.user!.uid,
        'password': password,
      };

      final prefs = await SharedPreferences.getInstance();
      if (remember) {
        await prefs.setString(_loggedInKey, jsonEncode(_sessionUserData));
      } else {
        await prefs.remove(_loggedInKey);
      }
      return 'student';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        try {
          await _auth.sendPasswordResetEmail(email: 'admin@grade.com');
        } catch (_) {}
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        rethrow;
      }
      return null;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unknownhost') ||
          msg.contains('unable to resolve host')) {
        rethrow;
      }
      return null;
    }
  }

  Future<void> logout() async {
    _sessionUserData = null;
    try {
      await _auth.signOut();
    } catch (e) {
      print('Firebase logout error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_sessionUserData != null) return _sessionUserData;
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_loggedInKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  Future<String?> getToken() async {
    final user = _auth.currentUser;
    return user?.getIdToken();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_loggedInKey);
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      // Update password in Firestore for students
      final userData = await getCurrentUser();
      if (userData?['role'] == 'student') {
        final studentId = userData!['student_id'] as String?;
        if (studentId != null) {
          await _firestore
              .collection('students')
              .doc(studentId)
              .update({'password': newPassword});
        }
      }

      return true;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }

  Future<bool> updateStudent(Student updatedStudent) async {
    try {
      await _firestore
          .collection('students')
          .doc(updatedStudent.studentId)
          .update(updatedStudent.toMap());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loggedInKey, jsonEncode(updatedStudent.toMap()));
      return true;
    } catch (e) {
      print('Update student error: $e');
      return false;
    }
  }

  // Create Firebase Auth user for existing student (fix login issues)
  Future<bool> createAuthForExistingStudent(
    String studentId,
    String newPassword,
  ) async {
    try {
      final studentDoc = await _firestore
          .collection('students')
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();

      if (studentDoc.docs.isEmpty) {
        print('Student not found');
        return false;
      }

      final studentData = studentDoc.docs.first.data();
      final email = studentData['email'] as String?;

      if (email == null) {
        print('Student email not found');
        return false;
      }

      // Create Firebase Auth user
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: newPassword,
      );

      if (result.user != null) {
        // Update password in Firestore
        await studentDoc.docs.first.reference.update({
          'password': newPassword,
          'uid': result.user!.uid,
        });
        print('Firebase Auth user created for student $studentId');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('Error creating auth for existing student: $e');
      return false;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
