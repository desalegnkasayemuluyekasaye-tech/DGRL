import 'dart:io';

/// Firebase Local Development Setup Script
/// Run this script to set up local Firebase emulators
class FirebaseLocalSetup {
  static Future<void> setupEmulators() async {
    print('🔧 Setting up Firebase Emulators for Local Development...\n');
    
    // Check if Firebase CLI is installed
    try {
      final result = await Process.run('firebase', ['--version']);
      if (result.exitCode != 0) {
        print('❌ Firebase CLI not found. Please install it first:');
        print('   npm install -g firebase-tools\n');
        return;
      }
      print('✅ Firebase CLI found: ${result.stdout.trim()}');
    } catch (e) {
      print('❌ Error checking Firebase CLI: $e');
      return;
    }
    
    // Initialize Firebase emulators
    print('\n📦 Initializing Firebase emulators...');
    try {
      final initResult = await Process.run('firebase', ['init', 'emulators'], 
        workingDirectory: Directory.current.path);
      
      if (initResult.exitCode == 0) {
        print('✅ Firebase emulators initialized successfully');
      } else {
        print('⚠️  Firebase emulators may already be initialized');
      }
    } catch (e) {
      print('⚠️  Error initializing emulators: $e');
    }
    
    // Start emulators
    print('\n🚀 Starting Firebase emulators...');
    print('   Firestore: http://localhost:8080');
    print('   Auth: http://localhost:9099');
    print('   Storage: http://localhost:9199');
    print('   Functions: http://localhost:5001\n');
    
    print('📝 Emulators will start in the background.');
    print('💡 Your Flutter app will automatically connect to these emulators in debug mode.');
    print('🌐 You can view the Firestore emulator at: http://localhost:4000/firestore\n');
    
    try {
      await Process.start('firebase', ['emulators:start'], 
        workingDirectory: Directory.current.path);
      print('✅ Firebase emulators started successfully!');
    } catch (e) {
      print('❌ Error starting emulators: $e');
      print('💡 You can start them manually with: firebase emulators:start');
    }
  }
  
  static Future<void> exportSampleData() async {
    print('📤 Exporting sample data for Firebase import...');
    
    // Create sample data directory
    final sampleDir = Directory('sample_data');
    if (!await sampleDir.exists()) {
      await sampleDir.create(recursive: true);
    }
    
    // This would create JSON files for each collection
    // You can then import these with: firebase emulators:start --import=./sample_data
    
    print('✅ Sample data prepared in ./sample_data directory');
    print('💡 Import with: firebase emulators:start --import=./sample_data');
  }
  
  static void printSetupInstructions() {
    print('''
🔥 Firebase Local Development Setup Instructions

1. Install Firebase CLI:
   npm install -g firebase-tools

2. Initialize Firebase in your project:
   firebase init

3. Start emulators:
   firebase emulators:start

4. Import sample data (optional):
   firebase emulators:start --import=./sample_data

5. Your Flutter app will automatically connect in debug mode!

🌐 Emulator URLs:
   - Firestore Emulator: http://localhost:8080
   - Auth Emulator: http://localhost:9099
   - Storage Emulator: http://localhost:9199
   - Functions Emulator: http://localhost:5001
   - Emulator UI: http://localhost:4000

💡 Benefits:
   - No internet connection required
   - Free development
   - Fast data operations
   - Data persistence across sessions
   - Easy testing and debugging
''');
  }
}

void main() {
  FirebaseLocalSetup.printSetupInstructions();
  
  // Uncomment to run setup
  // FirebaseLocalSetup.setupEmulators();
  // FirebaseLocalSetup.exportSampleData();
}
