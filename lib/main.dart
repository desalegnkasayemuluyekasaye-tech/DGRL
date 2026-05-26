import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/local_data_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  if (const bool.fromEnvironment('USE_FIREBASE_EMULATOR') == true) {
    try {
      // Connect to Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

      // Connect to Auth emulator
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

      print('Connected to Firebase emulators for local development');

      // Initialize sample data for testing
      await LocalDataSetup.initializeSampleData();
    } catch (e) {
      print('Failed to connect to emulators: $e');
    }
  }

  runApp(const DGRLApp());
}

// Helper function to fix auth for a specific student (call from anywhere)
Future<bool> fixStudentAuth(String studentId, String password) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final studentDoc = await firestore
        .collection('students')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();

    if (studentDoc.docs.isEmpty) {
      print('Student not found: $studentId');
      return false;
    }

    final data = studentDoc.docs.first.data();
    final email = data['email'] as String? ?? '';

    if (email.isEmpty) {
      print('No email for student: $studentId');
      return false;
    }

    try {
      final result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await firestore.collection('students').doc(studentDoc.docs.first.id).update({
          'uid': result.user!.uid,
        });
        print('Auth fixed for $studentId');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('Auth already exists for $studentId');
        return true;
      }
      print('Error fixing auth: $e');
      return false;
    }

    return false;
  } catch (e) {
    print('Error: $e');
    return false;
  }
}

class DGRLApp extends StatelessWidget {
  const DGRLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Digital Grade-Report Locker',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
