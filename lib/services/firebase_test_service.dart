import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class FirebaseTestService {
  static Future<bool> testFirebaseConnection() async {
    try {
      // Test Firebase initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
      
      // Test Firestore connection
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get();
      print('✅ Firestore connection successful');
      
      // Test Auth connection
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      print('✅ Firebase Auth connection successful');
      print('Current user: ${currentUser?.email ?? "Not logged in"}');
      
      return true;
    } catch (e) {
      print('❌ Firebase connection error: $e');
      return false;
    }
  }

  static Future<void> createAdminUser() async {
    try {
      final auth = FirebaseAuth.instance;
      
      // Create admin user if it doesn't exist
      try {
        await auth.createUserWithEmailAndPassword(
          email: 'admin@grade.com',
          password: 'ADMIN123',
        );
        print('✅ Admin user created successfully');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print('✅ Admin user already exists');
        } else {
          print('❌ Error creating admin user: $e');
        }
      }
    } catch (e) {
      print('❌ Error in createAdminUser: $e');
    }
  }

  static Future<void> setupSampleData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Create sample student data
      final sampleStudent = {
        'student_id': 'TEST001',
        'full_name': 'Test Student',
        'department': 'Computer Science',
        'batch': '2023',
        'email': 'test@grade.com',
        'password': 'test123',
        'sex': 'Male',
        'phone': '+1234567890',
        'age': 20,
        'photo_url': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      // Add sample student if it doesn't exist
      final existingDoc = await firestore
          .collection('students')
          .where('student_id', isEqualTo: 'TEST001')
          .get();
      
      if (existingDoc.docs.isEmpty) {
        await firestore.collection('students').add(sampleStudent);
        print('✅ Sample student data created');
      } else {
        print('✅ Sample student data already exists');
      }
    } catch (e) {
      print('❌ Error setting up sample data: $e');
    }
  }
}
