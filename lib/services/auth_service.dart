import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class AuthService {
  static const String _loggedInKey = 'logged_in_student';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<bool> login(String id, String password, bool isAdmin) async {
    try {
      if (isAdmin && id == 'ADMIN' && password == 'ADMIN123') {
        // Admin login - create user if doesn't exist, then sign in
        try {
          // Try to sign in first
          final result = await _auth.signInWithEmailAndPassword(
            email: 'admin@grade.com',
            password: 'ADMIN123',
          );
          
          if (result.user != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              _loggedInKey,
              jsonEncode({'username': 'ADMIN', 'role': 'admin', 'uid': result.user!.uid}),
            );
            return true;
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            // Create admin user if it doesn't exist
            try {
              final result = await _auth.createUserWithEmailAndPassword(
                email: 'admin@grade.com',
                password: 'ADMIN123',
              );
              
              if (result.user != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  _loggedInKey,
                  jsonEncode({'username': 'ADMIN', 'role': 'admin', 'uid': result.user!.uid}),
                );
                return true;
              }
            } on FirebaseAuthException catch (createError) {
              print('Error creating admin user: $createError');
            }
          } else {
            print('Admin login error: $e');
          }
        }
    } else {
        // Student login - check Firestore first
        print('Attempting student login for ID: $id');
        final studentDoc = await _firestore
            .collection('students')
            .where('student_id', isEqualTo: id)
            .limit(1)
            .get();

        // Also try email lookup if input contains @
        QuerySnapshot? emailDoc;
        if (id.contains('@')) {
          emailDoc = await _firestore
              .collection('students')
              .where('email', isEqualTo: id)
              .limit(1)
              .get();
        }

        final targetDoc = studentDoc.docs.isNotEmpty
            ? studentDoc.docs.first
            : (emailDoc != null && emailDoc.docs.isNotEmpty)
                ? emailDoc.docs.first
                : null;

        print('Found student: ${targetDoc != null}');

        if (targetDoc != null) {
          final studentData = targetDoc.data() as Map<String, dynamic>;
          final email = studentData['email'] as String?;
          final storedPassword = studentData['password'] as String?;

          print('Student data - Email: $email');
          print('Password match: ${storedPassword == password}');

          if (email != null && storedPassword == password) {
            try {
              // Try to sign in with Firebase Auth
              final result = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );

              if (result.user != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  _loggedInKey,
                  jsonEncode({
                    ...studentData,
                    'role': 'student',
                    'uid': result.user!.uid,
                  }),
                );
                return true;
              }
            } on FirebaseAuthException catch (e) {
              // Handle both 'user-not-found' and 'invalid-credential'
              if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
                // Create Firebase Auth user for student if it doesn't exist
                try {
                  final result = await _auth.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  if (result.user != null) {
                    // Update Firestore with the UID
                    await _firestore
                        .collection('students')
                        .doc(targetDoc.id)
                        .update({'uid': result.user!.uid});

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      _loggedInKey,
                      jsonEncode({
                        ...studentData,
                        'role': 'student',
                        'uid': result.user!.uid,
                      }),
                    );
                    return true;
                  }
                } on FirebaseAuthException catch (createError) {
                  print('Error creating student Firebase user: $createError');
                  if (createError.code == 'weak-password') {
                    print('Password is too weak for Firebase Auth.');
                  }
                }
              } else {
                print('Student login Firebase error: $e');
              }
            }
          } else {
            print('Password mismatch for student: $id');
          }
        } else {
          print('No student found with ID/email: $id');
        }
      }
    } catch (e) {
      print('Firebase login error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Firebase logout error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
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
    final token = await getToken();
    return token != null;
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
        await _firestore
            .collection('students')
            .doc(userData!['student_id'])
            .update({'password': newPassword});
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
  Future<bool> createAuthForExistingStudent(String studentId, String newPassword) async {
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
