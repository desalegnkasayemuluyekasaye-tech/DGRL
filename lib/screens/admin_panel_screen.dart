import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/course_service.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';
import 'notification_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();
  final CourseService _courseService = CourseService();
  int _currentTab = 0;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _grades = [];
  bool _isLoading = false;

  // Removed HTTP API references - now using Firestore

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      // Try to fetch from Firestore first
      final students = await _firestoreService.getAllStudents();
      setState(() {
        _students = students.map((s) => s.toMap()).toList();
      });
      
      // Save to local storage as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_students', jsonEncode(_students));
      return;
    } catch (e) {
      print('Firestore fetch students error: $e');
    }

    // Fallback to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_students');
      if (localData != null) {
        final List<dynamic> data = jsonDecode(localData);
        setState(() {
          _students = data.map((s) => Map<String, dynamic>.from(s)).toList();
        });
      }
    } catch (e) {
      print('Local fetch students error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      // Fetch from Firestore using CourseService
      final courses = await _courseService.getAllCourses();
      setState(() {
        _courses = courses.map((c) => c.toMap()).toList();
      });
    } catch (e) {
      print('Firestore fetch courses error: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error fetching courses from Firestore'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _courses = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGrades() async {
    setState(() => _isLoading = true);
    try {
      // For now, use local storage as fallback until we implement grade Firestore service
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_grades');
      if (localData != null) {
        final List<dynamic> data = jsonDecode(localData);
        setState(() {
          _grades = data.map((g) => Map<String, dynamic>.from(g)).toList();
        });
      } else {
        setState(() {
          _grades = [];
        });
      }
    } catch (e) {
      print('Local fetch grades error: $e');
      setState(() {
        _grades = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchStudents();
    await _fetchCourses();
    await _fetchGrades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildAdminDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTabContent(),
              ),
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildStudentsTab();
      case 2:
        return _buildCoursesTab();
      case 3:
        return _buildGradesTab();
      case 4:
        return _buildMoreTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E88E5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Expanded(
            child: Text(
              'Admin Dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPISection(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    return Row(
      children: [
        _buildKPICard(
          '${_students.length}',
          'Students',
          const Color(0xFF1E88E5),
          () {
            setState(() => _currentTab = 1);
          },
        ),
        const SizedBox(width: 16),
        _buildKPICard(
          '${_courses.length}',
          'Courses',
          const Color(0xFF4CAF50),
          () {
            setState(() => _currentTab = 2);
          },
        ),
        const SizedBox(width: 16),
        _buildKPICard(
          '${_grades.length}',
          'Total Grades',
          const Color(0xFF9C27B0),
          () {
            setState(() => _currentTab = 3);
          },
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String number,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                number,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionTile(
              'Add Student',
              Icons.person_add,
              const Color(0xFFE3F2FD),
              const Color(0xFF1E88E5),
              _showAddStudentDialog,
            ),
            const SizedBox(width: 16),
            _buildActionTile(
              'Add Course',
              Icons.menu_book,
              const Color(0xFFE8F5E9),
              const Color(0xFF4CAF50),
              _showAddCourseDialog,
            ),
            const SizedBox(width: 16),
            _buildActionTile(
              'Add Grade',
              Icons.grade,
              const Color(0xFFFFF3E0),
              const Color(0xFFFF9800),
              _showAddGradeDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Info',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                 leading: Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: const Color(0xFF1E88E5).withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: const Icon(
                     Icons.info,
                     color: Color(0xFF1E88E5),
                     size: 20,
                   ),
                 ),
                 title: const Text('Connected to Firebase Firestore'),
                 subtitle: const Text('Database active'),
               ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
                    child: Text(
                      student['student_id'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(student['full_name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${student['student_id']} • ${student['department']}',
                      ),
                      Text('Batch: ${student['batch']}'),
                      Text(student['email'] ?? ''),
                      if (student['phone'] != null)
                        Text('Phone: ${student['phone']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditStudentDialog(student),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDeleteStudent(student['student_id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildCoursesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              final course = _courses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course['course_code'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(course['course_title'] ?? ''),
                  subtitle: Text(
                    '${course['credit_hours']} Credits • ${course['instructor'] ?? ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditCourseDialog(course),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDeleteCourse(course['course_code']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildGradesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _grades.length,
            itemBuilder: (context, index) {
              final grade = _grades[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      grade['letter_grade'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  title: Text('${grade['student_id']} - ${grade['course_code']}'),
                  subtitle: Text(
                    'Total: ${grade['total_score']} • Semester: ${grade['semester']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _confirmDeleteGrade(grade['id'] ?? grade['grade_id']),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Administration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        _buildMoreItem(
          Icons.people,
          'Manage Students',
          'View and edit student records',
          () {
            setState(() => _currentTab = 1);
          },
        ),
        _buildMoreItem(
          Icons.menu_book,
          'Manage Courses',
          'Add or update course information',
          () {
            setState(() => _currentTab = 2);
          },
        ),
        _buildMoreItem(
          Icons.assessment,
          'Grade Management',
          'View and manage grades',
          () {
            setState(() => _currentTab = 3);
          },
        ),
        const Divider(height: 32),
        const Text(
          'System',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        _buildMoreItem(
          Icons.settings,
          'Change Password',
          'Update admin credentials',
          () {
            _showChangePasswordDialog();
          },
        ),
        _buildMoreItem(
          Icons.backup,
          'Backup Data',
          'Export all data from Firestore',
          () {
            _showBackupDialog();
          },
        ),
        const Divider(height: 32),
        const Text(
          'Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        _buildMoreItem(
          Icons.help,
          'Help & Support',
          'Get help and documentation',
          () {
            _showHelpDialog();
          },
        ),
      ],
    );
  }

  Widget _buildMoreItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E88E5), size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard, 'Dashboard', 0),
          _buildNavItem(Icons.people, 'Students', 1),
          _buildNavItem(Icons.menu_book, 'Courses', 2),
          _buildNavItem(Icons.assessment, 'Grades', 3),
          _buildNavItem(Icons.more_horiz, 'More', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int tabIndex) {
    final isActive = _currentTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tabIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E88E5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFF1E88E5),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'System Administrator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'admin@dgrl.edu',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF1E88E5)),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTab = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFF1E88E5)),
            title: const Text('Students'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTab = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: Color(0xFF1E88E5)),
            title: const Text('Courses'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTab = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment, color: Color(0xFF1E88E5)),
            title: const Text('Grades'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTab = 3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final provider = Provider.of<AppProvider>(context, listen: false);
              await provider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final deptController = TextEditingController();
    final batchController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final ageController = TextEditingController();
    String? selectedSex;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Student ID*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deptController,
                decoration: const InputDecoration(
                  labelText: 'Department*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch/Year* (e.g., 2024)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password*',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map(
                      (sex) => DropdownMenuItem(value: sex, child: Text(sex)),
                    )
                    .toList(),
                onChanged: (value) => selectedSex = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            onPressed: () async {
              if (idController.text.isNotEmpty &&
                  nameController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                // Validate password length
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters long'),
                    ),
                  );
                  return;
                }
                try {
                  // Create student object
                  final student = Student(
                    studentId: idController.text,
                    fullName: nameController.text,
                    department: deptController.text,
                    batch: batchController.text,
                    email: emailController.text,
                    password: passwordController.text,
                    phone: phoneController.text,
                    age: int.tryParse(ageController.text),
                    sex: selectedSex,
                  );

                  // Add to Firestore
                  await _firestoreService.addStudent(student);
                  
                  Navigator.pop(context);
                  await _fetchStudents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student added successfully to Firestore!'),
                    ),
                  );
                  return;
                } catch (e) {
                  print('Firestore add student error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding student: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill in all required fields (ID, Name, Password)',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCourseDialog() {
    final codeController = TextEditingController();
    final titleController = TextEditingController();
    final creditsController = TextEditingController();
    final instructorController = TextEditingController();
    final semesterController = TextEditingController();
    final departmentController = TextEditingController();
    final descriptionController = TextEditingController();
    final capacityController = TextEditingController(text: '50');
    final roomController = TextEditingController();
    final buildingController = TextEditingController();
    final dayController = TextEditingController(text: 'Monday');
    final startTimeController = TextEditingController(text: '09:00');
    final endTimeController = TextEditingController(text: '10:30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: creditsController,
                decoration: const InputDecoration(
                  labelText: 'Credit Hours*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructorController,
                decoration: const InputDecoration(
                  labelText: 'Instructor*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: semesterController,
                decoration: const InputDecoration(
                  labelText: 'Semester*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Max Capacity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: buildingController,
                decoration: const InputDecoration(
                  labelText: 'Building',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: dayController,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            onPressed: () async {
              if (codeController.text.isNotEmpty &&
                  titleController.text.isNotEmpty &&
                  instructorController.text.isNotEmpty &&
                  semesterController.text.isNotEmpty) {
                try {
                  // Check if course code already exists
                  final existingCourse = await _courseService.getCourse(codeController.text);
                  if (existingCourse != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Course code already exists!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Create new course with schedule
                  final course = Course(
                    courseCode: codeController.text,
                    courseTitle: titleController.text,
                    creditHours: int.tryParse(creditsController.text) ?? 3,
                    instructor: instructorController.text,
                    semester: semesterController.text,
                    department: departmentController.text,
                    description: descriptionController.text,
                    maxCapacity: int.tryParse(capacityController.text) ?? 50,
                    room: roomController.text.isEmpty ? null : roomController.text,
                    building: buildingController.text.isEmpty ? null : buildingController.text,
                    schedule: CourseSchedule(
                      dayOfWeek: dayController.text,
                      startTime: startTimeController.text,
                      endTime: endTimeController.text,
                    ),
                  );

                  // Save to Firestore
                  final success = await _courseService.addCourse(course);
                  
                  if (success) {
                    Navigator.pop(context);
                    await _fetchCourses();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Course added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add course'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddGradeDialog() {
    final studentIdController = TextEditingController();
    final courseCodeController = TextEditingController();
    final midController = TextEditingController();
    final assignmentController = TextEditingController();
    final finalController = TextEditingController();
    final semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Grade'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: midController,
                decoration: const InputDecoration(
                  labelText: 'Mid Score (0-100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: assignmentController,
                decoration: const InputDecoration(
                  labelText: 'Assignment Score (0-100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: finalController,
                decoration: const InputDecoration(
                  labelText: 'Final Score (0-100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: semesterController,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
            ),
            onPressed: () async {
              // Save to local storage (temporary solution)
              try {
                final prefs = await SharedPreferences.getInstance();
                final localData = prefs.getString('local_grades');
                List<Map<String, dynamic>> localGrades = [];
                if (localData != null) {
                  final List<dynamic> decoded = jsonDecode(localData);
                  localGrades = decoded
                      .map((g) => Map<String, dynamic>.from(g))
                      .toList();
                }

                // Calculate total score and letter grade
                double mid = double.tryParse(midController.text) ?? 0;
                double assignment =
                    double.tryParse(assignmentController.text) ?? 0;
                double finalScore = double.tryParse(finalController.text) ?? 0;
                double totalScore = mid + assignment + finalScore;

                String letterGrade;
                if (totalScore >= 90) {
                  letterGrade = 'A+';
                } else if (totalScore >= 80)
                  letterGrade = 'A';
                else if (totalScore >= 70)
                  letterGrade = 'B';
                else if (totalScore >= 60)
                  letterGrade = 'C';
                else if (totalScore >= 50)
                  letterGrade = 'D';
                else
                  letterGrade = 'F';

                localGrades.add({
                  '_id': 'local_${DateTime.now().millisecondsSinceEpoch}',
                  'studentId': studentIdController.text,
                  'courseCode': courseCodeController.text,
                  'midScore': mid,
                  'assignmentScore': assignment,
                  'finalScore': finalScore,
                  'totalScore': totalScore,
                  'letterGrade': letterGrade,
                  'semester': semesterController.text,
                });

                await prefs.setString(
                  'local_grades',
                  jsonEncode(localGrades),
                );
                Navigator.pop(context);
                await _fetchGrades();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Grade added locally!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['fullName']);
    final deptController = TextEditingController(text: student['department']);
    final batchController = TextEditingController(text: student['batch']);
    final emailController = TextEditingController(text: student['email']);
    final phoneController = TextEditingController(text: student['phone']);
    final ageController = TextEditingController(
      text: student['age']?.toString(),
    );
    String? selectedSex = student['sex'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deptController,
                decoration: const InputDecoration(
                  labelText: 'Department*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch/Year*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedSex,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map(
                      (sex) => DropdownMenuItem(value: sex, child: Text(sex)),
                    )
                    .toList(),
                onChanged: (value) => selectedSex = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                String studentId = student['studentId'] ?? student['_id'] ?? '';
                try {
                  // Update in Firestore
                  await _firestoreService.updateStudent(studentId, {
                    'full_name': nameController.text,
                    'department': deptController.text,
                    'batch': batchController.text,
                    'email': emailController.text,
                    'phone': phoneController.text,
                    'age': int.tryParse(ageController.text),
                    'sex': selectedSex,
                  });

                  Navigator.pop(context);
                  await _fetchStudents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student updated in Firestore!'),
                    ),
                  );
                  return;
                } catch (e) {
                  print('Firestore edit student error: $e');
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStudent(String? id) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Try to delete from Firestore first
              try {
                // Find the student by studentId to get the document ID
                final students = await _firestoreService.getAllStudents();
                final studentToDelete = students.firstWhere(
                  (s) => s.studentId == id,
                  orElse: () => Student(
                    studentId: '',
                    fullName: '',
                    department: '',
                    batch: '',
                    email: '',
                    password: '',
                  ),
                );

                if (studentToDelete.studentId.isNotEmpty) {
                  await _firestoreService.deleteStudent(studentToDelete.studentId);
                  Navigator.pop(context);
                  await _fetchStudents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student deleted from Firestore!'),
                    ),
                  );
                  return;
                }
              } catch (e) {
                print('Firestore delete student error: $e');
              }

              // Fallback: Delete from local storage
              try {
                final prefs = await SharedPreferences.getInstance();
                final localData = prefs.getString('local_students');
                if (localData != null) {
                  List<dynamic> decoded = jsonDecode(localData);
                  List<Map<String, dynamic>> localStudents = decoded
                      .map((s) => Map<String, dynamic>.from(s))
                      .toList();

                  localStudents.removeWhere(
                    (s) => s['studentId'] == id || s['_id'] == id,
                  );

                  await prefs.setString(
                    'local_students',
                    jsonEncode(localStudents),
                  );
                  Navigator.pop(context);
                  await _fetchStudents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student deleted locally (offline mode)!'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(Map<String, dynamic> course) {
    final titleController = TextEditingController(text: course['course_title']);
    final creditsController = TextEditingController(
      text: course['credit_hours']?.toString(),
    );
    final instructorController = TextEditingController(
      text: course['instructor'],
    );
    final semesterController = TextEditingController(text: course['semester']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Course Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: creditsController,
              decoration: const InputDecoration(
                labelText: 'Credits',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: instructorController,
              decoration: const InputDecoration(
                labelText: 'Instructor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: semesterController,
              decoration: const InputDecoration(
                labelText: 'Semester',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            onPressed: () async {
              String courseCode = course['course_code'] ?? '';
               try {
                 // Update in Firestore (Note: This would need Firestore course service)
                 // For now, update in local storage
                 final prefs = await SharedPreferences.getInstance();
                 final localData = prefs.getString('local_courses');
                 if (localData != null) {
                   List<dynamic> decoded = jsonDecode(localData);
                   List<Map<String, dynamic>> localCourses = decoded
                       .map((c) => Map<String, dynamic>.from(c))
                       .toList();

                   int index = localCourses.indexWhere(
                     (c) => c['course_code'] == courseCode,
                   );

                   if (index != -1) {
                     localCourses[index] = {
                       ...localCourses[index],
                       'course_title': titleController.text,
                       'credit_hours': int.tryParse(creditsController.text) ?? 3,
                       'instructor': instructorController.text,
                       'semester': semesterController.text,
                     };

                    await prefs.setString(
                      'local_courses',
                      jsonEncode(localCourses),
                    );
                    Navigator.pop(context);
                    await _fetchCourses();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Course updated locally!'),
                      ),
                    );
                    return;
                  }
                }
              } catch (e) {
                print('Local edit course error: $e');
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCourse(String? id) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Delete from local storage (temporary solution)
              try {
                final prefs = await SharedPreferences.getInstance();
                final localData = prefs.getString('local_courses');
                if (localData != null) {
                  List<dynamic> decoded = jsonDecode(localData);
                  List<Map<String, dynamic>> localCourses = decoded
                      .map((c) => Map<String, dynamic>.from(c))
                      .toList();

                  localCourses.removeWhere(
                    (c) => c['courseCode'] == id || c['_id'] == id,
                  );

                  await prefs.setString(
                    'local_courses',
                    jsonEncode(localCourses),
                  );
                  Navigator.pop(context);
                  await _fetchCourses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course deleted locally!'),
                    ),
                  );
                  return;
                }
              } catch (e) {
                print('Local delete course error: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGrade(String? id) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grade'),
        content: const Text('Are you sure you want to delete this grade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Delete from local storage (temporary solution)
              try {
                final prefs = await SharedPreferences.getInstance();
                final localData = prefs.getString('local_grades');
                if (localData != null) {
                  List<dynamic> decoded = jsonDecode(localData);
                  List<Map<String, dynamic>> localGrades = decoded
                      .map((g) => Map<String, dynamic>.from(g))
                      .toList();

                  localGrades.removeWhere((g) => g['_id'] == id);

                  await prefs.setString(
                    'local_grades',
                    jsonEncode(localGrades),
                  );
                  Navigator.pop(context);
                  await _fetchGrades();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grade deleted locally!'),
                    ),
                  );
                  return;
                }
              } catch (e) {
                print('Local delete grade error: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Admin Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Old Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            onPressed: () async {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                final authService = Provider.of<AppProvider>(
                  context,
                  listen: false,
                ).authService;
                final success = await authService.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to change password. Check old password.',
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match')),
                );
              }
            },
            child: const Text('Change', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text(
          'Data is stored in MongoDB Emr-system database. Use MongoDB tools to export/backup data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For support, contact admin@dgrl.edu or visit our documentation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
