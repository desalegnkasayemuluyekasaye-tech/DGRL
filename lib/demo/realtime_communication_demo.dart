import 'package:flutter/material.dart';

class RealtimeCommunicationDemo extends StatelessWidget {
  const RealtimeCommunicationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin-Student Communication Demo'),
        backgroundColor: const Color(0xFF3949AB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '🎯 Real-time Communication System',
              'Two-way communication between Admin and Student pages',
            ),
            const SizedBox(height: 24),
            
            _buildFeatureCard(
              '📡 Admin → Student Updates',
              [
                '• Real-time student data synchronization',
                '• Automatic grade/course updates',
                '• Instant notification delivery',
                '• No manual refresh needed',
              ],
              Colors.blue,
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              '📤 Student → Admin Communication',
              [
                '• Profile update notifications',
                '• Request submission to admin',
                '• Issue reporting system',
                '• Feedback delivery',
              ],
              Colors.green,
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              '🔄 Real-time Sync Features',
              [
                '• Firebase Cloud Firestore integration',
                '• Stream-based data listeners',
                '• Automatic conflict resolution',
                '• Offline-first with online sync',
              ],
              Colors.purple,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '📊 Enhanced Student Dashboard',
              'Admin-like UI with real-time data',
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              '🎨 UI Improvements',
              [
                '• KPI cards (GPA, CGPA, Total Grades)',
                '• Quick action tiles',
                '• Recent grades display',
                '• System status panel',
                '• Professional navigation drawer',
              ],
              Colors.orange,
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              '🖼️ Image Support',
              [
                '• Profile picture upload to Firebase Storage',
                '• Image compression and validation',
                '• Gallery and camera integration',
                '• Automatic image management',
              ],
              Colors.teal,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '⚙️ How It Works',
              'Step-by-step communication flow',
            ),
            const SizedBox(height: 16),
            
            _buildStepCard(
              1,
              'Admin makes changes to student data',
              'Changes are saved to Firebase Firestore',
            ),
            _buildStepCard(
              2,
              'Firebase triggers real-time update',
              'Student app receives update via stream',
            ),
            _buildStepCard(
              3,
              'Student dashboard updates automatically',
              'No manual refresh required',
            ),
            _buildStepCard(
              4,
              'Student can send notifications to admin',
              'Requests, issues, or feedback',
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '🔧 Technical Implementation',
              'Key components and services',
            ),
            const SizedBox(height: 16),
            
            _buildTechCard(
              'RealtimeService',
              'Handles all Firebase real-time communication',
              'Stream<DocumentSnapshot>, Stream<QuerySnapshot>',
            ),
            _buildTechCard(
              'AppProvider',
              'Manages state and real-time listeners',
              'initializeRealtimeListeners(), getStudentDataStream()',
            ),
            _buildTechCard(
              'ImageUploadService',
              'Handles profile picture uploads',
              'uploadProfilePicture(), compressImageIfNeeded()',
            ),
            _buildTechCard(
              'EnhancedStudentDashboard',
              'Admin-like student interface',
              'KPI cards, quick actions, real-time updates',
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3949AB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3949AB)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Implementation Complete',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The real-time communication system has been successfully implemented. Students now receive automatic updates when admins modify their data, and admins get notifications when students update their profiles.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3949AB),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, List<String> features, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStepCard(int step, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechCard(String name, String description, String methods) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3949AB),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              methods,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}