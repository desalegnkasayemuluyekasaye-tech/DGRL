import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login with email and password
  Future<UserCredential?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Log successful login
      await logSecurityEvent('login_success', {
        'email': email,
        'timestamp': Timestamp.now(),
      });

      return userCredential;
    } catch (e) {
      print('Login error: $e');

      // Log failed login
      await _firestore.collection('failed_login_attempts').add({
        'email': email,
        'timestamp': Timestamp.now(),
        'error': e.toString(),
      });

      return null;
    }
  }

  // Register with email and password
  Future<UserCredential?> register(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Store additional user data in Firestore
      if (userCredential.user != null) {
        await _firestore
            .collection('students')
            .doc(userCredential.user!.uid)
            .set({
          ...userData,
          'uid': userCredential.user!.uid,
          'email': email,
          'createdAt': Timestamp.now(),
        });
      }

      return userCredential;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // Password Reset via Email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      // Log the password reset request
      await _firestore.collection('password_reset_requests').add({
        'email': email,
        'timestamp': Timestamp.now(),
        'status': 'sent',
      });
      
      return true;
    } catch (e) {
      print('Send password reset email error: $e');
      return false;
    }
  }

  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      
      // Log successful password reset
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('password_resets').add({
          'userId': user.uid,
          'email': user.email,
          'timestamp': Timestamp.now(),
          'status': 'completed',
        });
      }
      
      return true;
    } catch (e) {
      print('Confirm password reset error: $e');
      return false;
    }
  }

  // Email Verification
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        
        // Log email verification request
        await _firestore.collection('email_verification_requests').add({
          'userId': user.uid,
          'email': user.email,
          'timestamp': Timestamp.now(),
          'status': 'sent',
        });
        
        return true;
      }
      return false;
    } catch (e) {
      print('Send email verification error: $e');
      return false;
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      print('Check email verification error: $e');
      return false;
    }
  }

  // Multi-Factor Authentication
  Future<bool> enableMultiFactorAuthentication() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // For SMS MFA (you'll need to set up phone number)
        // This is a simplified version - in production, you'd use proper MFA setup
        await _firestore.collection('user_mfa_settings').doc(user.uid).set({
          'mfaEnabled': true,
          'mfaType': 'sms',
          'phoneNumber': user.phoneNumber ?? '',
          'enabledAt': Timestamp.now(),
        });
        
        return true;
      }
      return false;
    } catch (e) {
      print('Enable MFA error: $e');
      return false;
    }
  }

  Future<bool> disableMultiFactorAuthentication() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('user_mfa_settings').doc(user.uid).update({
          'mfaEnabled': false,
          'disabledAt': Timestamp.now(),
        });
        
        return true;
      }
      return false;
    } catch (e) {
      print('Disable MFA error: $e');
      return false;
    }
  }

  Future<bool> isMultiFactorEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('user_mfa_settings').doc(user.uid).get();
        return doc.exists && doc['mfaEnabled'] == true;
      }
      return false;
    } catch (e) {
      print('Check MFA status error: $e');
      return false;
    }
  }

  // Account Recovery
  Future<bool> initiateAccountRecovery(String email) async {
    try {
      // Check if email exists in the system
      final userDoc = await _firestore
          .collection('students')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data();
        
        // Create recovery token
        final recoveryToken = _generateRecoveryToken();
        
        // Store recovery request
        await _firestore.collection('account_recovery').add({
          'userId': userDoc.docs.first.id,
          'email': email,
          'token': recoveryToken,
          'timestamp': Timestamp.now(),
          'status': 'pending',
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        });
        
        // Send recovery email (in production, you'd use a proper email service)
        await _sendRecoveryEmail(email, recoveryToken, userData['student_id'] ?? '');
        
        return true;
      }
      return false;
    } catch (e) {
      print('Initiate account recovery error: $e');
      return false;
    }
  }

  Future<bool> validateRecoveryToken(String token) async {
    try {
      final recoveryDoc = await _firestore
          .collection('account_recovery')
          .where('token', isEqualTo: token)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      
      if (recoveryDoc.docs.isNotEmpty) {
        final recoveryData = recoveryDoc.docs.first.data();
        final expiresAt = recoveryData['expiresAt'] as Timestamp;
        
        // Check if token is still valid
        if (expiresAt.toDate().isAfter(DateTime.now())) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Validate recovery token error: $e');
      return false;
    }
  }

  Future<bool> completeAccountRecovery(String token, String newPassword) async {
    try {
      final recoveryDoc = await _firestore
          .collection('account_recovery')
          .where('token', isEqualTo: token)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      
      if (recoveryDoc.docs.isNotEmpty) {
        final recoveryData = recoveryDoc.docs.first.data();
        final userId = recoveryData['userId'];
        final expiresAt = recoveryData['expiresAt'] as Timestamp;
        
        // Check if token is still valid
        if (expiresAt.toDate().isAfter(DateTime.now())) {
          // Update user password (this would require admin privileges or proper auth flow)
          await _firestore.collection('students').doc(userId).update({
            'password': newPassword, // In production, hash this properly
            'lastPasswordReset': Timestamp.now(),
          });
          
          // Mark recovery as completed
          await recoveryDoc.docs.first.reference.update({
            'status': 'completed',
            'completedAt': Timestamp.now(),
          });
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Complete account recovery error: $e');
      return false;
    }
  }

  // Security Settings
  Future<Map<String, dynamic>> getSecuritySettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final mfaDoc = await _firestore.collection('user_mfa_settings').doc(user.uid).get();
        final securityDoc = await _firestore.collection('user_security_settings').doc(user.uid).get();
        
        return {
          'emailVerified': user.emailVerified,
          'mfaEnabled': mfaDoc.exists ? mfaDoc['mfaEnabled'] : false,
          'lastPasswordChange': securityDoc.exists ? securityDoc['lastPasswordChange'] : null,
          'loginAttempts': securityDoc.exists ? securityDoc['loginAttempts'] : 0,
          'lastLogin': securityDoc.exists ? securityDoc['lastLogin'] : null,
        };
      }
      return {};
    } catch (e) {
      print('Get security settings error: $e');
      return {};
    }
  }

  Future<bool> updateSecuritySettings(Map<String, dynamic> settings) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('user_security_settings').doc(user.uid).set({
          ...settings,
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
        
        return true;
      }
      return false;
    } catch (e) {
      print('Update security settings error: $e');
      return false;
    }
  }

  // Session Management
  Future<void> logSecurityEvent(String eventType, Map<String, dynamic> details) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('security_events').add({
          'userId': user.uid,
          'eventType': eventType,
          'details': details,
          'timestamp': Timestamp.now(),
          'ipAddress': details['ipAddress'] ?? 'unknown',
          'userAgent': details['userAgent'] ?? 'unknown',
        });
      }
    } catch (e) {
      print('Log security event error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSecurityHistory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final events = await _firestore
            .collection('security_events')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        
        return events.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      }
      return [];
    } catch (e) {
      print('Get security history error: $e');
      return [];
    }
  }

  // Helper Methods
  String _generateRecoveryToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().hashCode;
    return '$timestamp-$random';
  }

  Future<void> _sendRecoveryEmail(String email, String token, String studentId) async {
    // In production, use a proper email service like SendGrid, Mailgun, etc.
    print('Recovery email sent to: $email');
    print('Recovery token: $token');
    print('Student ID: $studentId');
    
    // Store email log for debugging
    await _firestore.collection('email_logs').add({
      'email': email,
      'type': 'account_recovery',
      'token': token,
      'studentId': studentId,
      'timestamp': Timestamp.now(),
      'status': 'sent',
    });
  }

  Future<bool> validatePasswordStrength(String password) async {
    // Basic password strength validation
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    return true;
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Reauthenticate user first
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        
        // Log password update
        await logSecurityEvent('password_updated', {
          'timestamp': Timestamp.now(),
        });
        
        return true;
      }
      return false;
    } catch (e) {
      print('Update password error: $e');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Log account deletion
        await logSecurityEvent('account_deleted', {
          'email': user.email,
          'timestamp': Timestamp.now(),
        });
        
        // Delete user data from Firestore
        await _firestore.collection('students').doc(user.uid).delete();
        await _firestore.collection('user_security_settings').doc(user.uid).delete();
        await _firestore.collection('user_mfa_settings').doc(user.uid).delete();
        
        // Delete user account
        await user.delete();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Delete account error: $e');
      return false;
    }
  }
}
