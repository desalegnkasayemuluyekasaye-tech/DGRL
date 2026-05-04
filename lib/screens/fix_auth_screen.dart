import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FixAuthScreen extends StatefulWidget {
  const FixAuthScreen({super.key});

  @override
  State<FixAuthScreen> createState() => _FixAuthScreenState();
}

class _FixAuthScreenState extends State<FixAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _status = '';
  int _total = 0;
  int _success = 0;
  int _failed = 0;
  List<String> _errors = [];

  Future<void> _fixAllStudentAuth() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting...';
      _total = 0;
      _success = 0;
      _failed = 0;
      _errors = [];
    });

    try {
      final students = await _firestore.collection('students').get();
      setState(() {
        _total = students.docs.length;
        _status = 'Processing ${_total} students...';
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
          // Try to create Firebase Auth user
          final result = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

          if (result.user != null) {
            // Update Firestore with UID
            await _firestore.collection('students').doc(doc.id).update({
              'uid': result.user!.uid,
            });

            setState(() => _success++);
            print('Created auth for $studentId ($email)');
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // User already exists - that's OK
            setState(() => _success++);
            print('Auth already exists for $studentId ($email)');
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Student Auth'),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bulk Create Firebase Auth Users',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3949AB),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create Firebase Authentication users for all students in the database. '
              'Students who already have auth accounts will be skipped.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_total > 0) ...[
              _buildStatCard('Total Students', '$_total', Colors.blue),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Success', '$_success', Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Failed', '$_failed', Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fixAllStudentAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3949AB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Fix All Student Auth',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('Error')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status.contains('Error')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('Error')
                          ? Icons.error
                          : Icons.check_circle,
                      color: _status.contains('Error')
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('Error')
                              ? Colors.red[900]
                              : Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_errors.isNotEmpty) ...[
              const Text(
                'Errors:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _errors.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '• ${_errors[index]}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
