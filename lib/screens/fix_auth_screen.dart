import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/theme_constants.dart';

class FixAuthScreen extends StatefulWidget {
  const FixAuthScreen({super.key});

  @override
  State<FixAuthScreen> createState() => _FixAuthScreenState();
}

class _FixAuthScreenState extends State<FixAuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  String _status = '';
  int _total = 0, _success = 0, _failed = 0;
  final List<String> _errors = [];

  Future<void> _fixAll() async {
    setState(() {
      _loading = true;
      _status = 'Starting...';
      _total = 0;
      _success = 0;
      _failed = 0;
      _errors.clear();
    });

    try {
      final students = await _firestore.collection('students').get();
      setState(() {
        _total = students.docs.length;
        _status = 'Processing $_total students...';
      });

      for (final doc in students.docs) {
        final data = doc.data();
        final email = data['email'] as String? ?? '';
        final studentId = data['student_id'] as String? ?? '';
        final password = data['password'] as String? ?? 'password123';

        if (email.isEmpty) {
          setState(() {
            _failed++;
            _errors.add('No email for $studentId');
          });
          continue;
        }

        try {
          final result = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          if (result.user != null) {
            await _firestore.collection('students').doc(doc.id).update({
              'uid': result.user!.uid,
            });
            setState(() => _success++);
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            setState(() => _success++);
          } else {
            setState(() {
              _failed++;
              _errors.add('$studentId: ${e.message}');
            });
          }
        } catch (e) {
          setState(() {
            _failed++;
            _errors.add('$studentId: $e');
          });
        }
      }

      setState(() {
        _status = 'Completed! Success: $_success, Failed: $_failed';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fix Student Auth'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Create Firebase Auth Users',
                style: AppTextStyles.h2),
            const SizedBox(height: 12),
            const Text(
              'Create Firebase Auth accounts for all students in Firestore. Existing accounts will be skipped.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 32),
            if (_total > 0) ...[
              Row(
                children: [
                  _statCard('Total', '$_total', AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                        'Success', '$_success', AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        _statCard('Failed', '$_failed', AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _fixAll,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('FIX ALL STUDENT AUTH',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1)),
              ),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('Error')
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _status.contains('Error')
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('Error')
                          ? Icons.error_rounded
                          : Icons.check_circle_rounded,
                      color: _status.contains('Error')
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(_status,
                            style: TextStyle(
                              color: _status.contains('Error')
                                  ? AppColors.error
                                  : AppColors.success,
                            ))),
                  ],
                ),
              ),
            ],
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.error)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: _errors.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• ${_errors[i]}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.error)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(title, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
