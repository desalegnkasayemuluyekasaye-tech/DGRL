# Local Firebase Development Setup

## 🚀 Quick Start Guide

### Option 1: Automatic Setup (Recommended)
```bash
# Run the setup script
dart run setup_local_firebase.dart

# Start Firebase emulators
firebase emulators:start --import=./sample_data

# Run your Flutter app
flutter run
```

### Option 2: Manual Setup

#### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

#### 2. Initialize Firebase in Project
```bash
firebase init emulators
```

#### 3. Start Emulators
```bash
firebase emulators:start --import=./sample_data
```

#### 4. Run Flutter App
```bash
flutter run
```

## 📱 How It Works

### Development Mode (Debug)
- ✅ Automatically connects to Firebase emulators
- ✅ Loads sample data automatically
- ✅ No internet connection required
- ✅ Fast data operations
- ✅ Data persists across sessions

### Production Mode (Release)
- ✅ Connects to live Firebase project
- ✅ Uses real authentication
- ✅ Production data handling

## 🔧 Configuration Files

### `lib/main.dart`
- Handles Firebase initialization
- Detects development vs production mode
- Connects to emulators in debug mode
- Initializes sample data automatically

### `lib/services/local_data_setup.dart`
- Creates sample students, courses, and grades
- Sets up notifications
- Clears existing data (optional)

### `firebase_emulator_setup.md`
- Detailed setup instructions
- Configuration examples
- Troubleshooting guide

## 🎯 Sample Data Included

### Computer Science Students (5)
- Alice Chen (20, Female) - cs_student001@university.edu
- Bob Williams (21, Male) - cs_student002@university.edu  
- Carol Martinez (19, Female) - cs_student003@university.edu
- David Kim (22, Male) - cs_student004@university.edu
- Emma Thompson (20, Female) - cs_student005@university.edu

### Computer Science Courses (7)
- CS101: Introduction to Computer Science (3 credits) - Dr. Alice Brown
- CS102: Programming Fundamentals (4 credits) - Dr. Robert Davis
- CS201: Data Structures and Algorithms (4 credits) - Dr. John Miller
- CS202: Computer Organization (3 credits) - Dr. Sarah Wilson
- CS301: Operating Systems (4 credits) - Dr. Emily Chen
- CS302: Database Management Systems (3 credits) - Dr. Michael Johnson
- CS401: Software Engineering (4 credits) - Dr. David Lee

### Grades (35)
- All 5 CS students enrolled in Fall 2025
- Each student taking all 7 courses
- Grade ranges: 76-97% (C+ to A+)
- Letter grades: A-, A, A+, etc.

### Test Accounts:
- **alice.chen@university.edu** - Password: any (local auth bypass)
- **bob.williams@university.edu** - Password: any (local auth bypass)
- **carol.martinez@university.edu** - Password: any (local auth bypass)
- **david.kim@university.edu** - Password: any (local auth bypass)
- **emma.thompson@university.edu** - Password: any (local auth bypass)

## 🌐 Emulator URLs

When emulators are running, access at:
- **Firestore Emulator**: http://localhost:8080
- **Auth Emulator**: http://localhost:9099
- **Storage Emulator**: http://localhost:9199
- **Functions Emulator**: http://localhost:5001
- **Emulator UI**: http://localhost:4000

## 📱 Testing Features

### With Local Data, You Can Test:
✅ **Student Login** - Use any sample student email
✅ **Grade Viewing** - All grades are pre-loaded
✅ **GPA Calculation** - Automatic calculation from grades
✅ **Course Management** - View all courses
✅ **History Tracking** - Semester-by-semester history
✅ **Profile Management** - Edit student information
✅ **Notifications** - Sample notifications included

### Test Accounts:
- **Email**: john.doe@university.edu
- **Email**: jane.smith@university.edu  
- **Email**: mike.johnson@university.edu
- **Password**: Any password (local auth bypass)

## 🔄 Switching Modes

### To Development Mode:
```bash
flutter run --debug
```

### To Production Mode:
```bash
flutter run --release
```

## 🛠️ Troubleshooting

### Emulator Won't Start:
```bash
# Check Firebase CLI version
firebase --version

# Re-initialize emulators
firebase emulators:start --import=./sample_data

# Clear emulator data
firebase emulators:clear
```

### Connection Issues:
```bash
# Check if emulators are running
firebase emulators:list

# Restart emulators
firebase emulators:start
```

### Sample Data Issues:
```bash
# Re-initialize sample data
dart run lib/services/local_data_setup.dart
```

## 💡 Development Tips

1. **Hot Reload Works**: Changes to code reflect immediately
2. **Data Persistence**: Sample data persists across app restarts
3. **No Internet**: Completely offline development possible
4. **Fast Testing**: No network latency for data operations
5. **Easy Debugging**: View data in emulator UI at localhost:4000

## 🎉 You're Ready!

Once Firebase emulators are running, your Flutter app will:
- Connect automatically in debug mode
- Load sample data on first run
- Provide full offline functionality
- Allow testing of all features

Start developing with confidence! 🚀
