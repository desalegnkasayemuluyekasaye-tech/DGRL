# Firebase Emulator Setup for Local Development

## Prerequisites
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install Java JDK 11 or later
3. Android Studio with latest SDK

## Setup Steps

### 1. Initialize Firebase Emulators
```bash
cd your_project_directory
firebase init emulators
```

### 2. Start Emulators
```bash
firebase emulators:start --import=./sample_data
```

### 3. Default Emulator Ports
- Firestore: 8080
- Auth: 9099
- Storage: 9199
- Functions: 5001

### 4. Flutter Configuration
Add to your `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123",
  
  // Local emulator configuration
  host: 'localhost',
  port: 8080,
  databaseURL: 'http://localhost:8080',
);
```

### 5. Initialize Firebase with Emulator
In your `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connect to Firebase emulators
  if (kDebugMode) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Connect to Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      
      // Connect to Auth emulator
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      
      print('Connected to Firebase emulators');
    } catch (e) {
      print('Failed to connect to emulators: $e');
    }
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(const MyApp());
}
```

## Benefits
- ✅ Offline development
- ✅ No internet connection needed
- ✅ Fast data operations
- ✅ Free development
- ✅ Data persistence across sessions
