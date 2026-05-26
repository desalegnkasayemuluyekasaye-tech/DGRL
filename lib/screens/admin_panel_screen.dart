import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../constants/theme_constants.dart';
import '../services/firestore_service.dart';
import '../services/course_service.dart';
import '../services/grade_service.dart';
import '../services/excel_import_service.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/grade.dart';
import '../models/course_registration.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestoreService = FirestoreService();
  final _courseService = CourseService();
  final _gradeService = GradeService();

  int _currentTab = 0;
  bool _loading = false;
  String _appTheme = 'system';

  List<Student> _students = [];
  List<Course> _courses = [];
  List<String> _courseDocIds = [];
  List<Map<String, dynamic>> _grades = [];
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadStudents(), _loadCourses(), _loadGrades()]);
    setState(() => _loading = false);
  }

  Future<void> _loadStudents() async {
    final s = await _firestoreService.getAllStudents();
    setState(() => _students = s);
  }

  Future<void> _loadCourses() async {
    final coursesWithIds = await _courseService.getAllCoursesWithIds();
    final courseList = <Course>[];
    final idList = <String>[];
    for (final map in coursesWithIds) {
      courseList.add(Course.fromMap(map));
      idList.add(map['_id'] as String);
    }
    setState(() {
      _courses = courseList;
      _courseDocIds = idList;
    });
  }

  Future<void> _loadGrades() async {
    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      setState(() => _grades = []);
      return;
    }
    final g = await _gradeService.getGradesWithIds(_selectedStudentId!);
    setState(() => _grades = g);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              // preserve navigation/notification intent (placeholder)
              ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAll,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentTab) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildStudentsTab();
      case 2:
        return _buildCoursesTab();
      case 3:
        return _buildGradesTab();
      case 4:
        return _buildMoreTab();
      default:
        return _buildDashboard();
    }
  }

  // ─── DASHBOARD ──────────────────────────────────────────────

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          // Top overview metric cards (4 columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kpiCard(
                '${_students.length}',
                'Students',
                Icons.people_alt_outlined,
                const Color(0xFF1E88E5),
                () => setState(() => _currentTab = 1),
              ),
              const SizedBox(width: 12),
              _kpiCard(
                '${_courses.length}',
                'Courses',
                Icons.menu_book_outlined,
                const Color(0xFF4CAF50),
                () => setState(() => _currentTab = 2),
              ),
              const SizedBox(width: 12),
              _kpiCard(
                '5',
                'Semesters',
                Icons.trending_up_rounded,
                const Color(0xFF00BFA5),
                () {},
              ),
              const SizedBox(width: 12),
              _kpiCard(
                '320',
                'Total Grades',
                Icons.bar_chart_rounded,
                const Color(0xFFFF9800),
                () => setState(() => _currentTab = 3),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Quick Actions', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          Row(
            children: [
              _quickActionCard(
                'Add Student',
                Icons.person_add_alt_1_rounded,
                const Color(0xFF1E88E5),
                const Color(0xFFE3F2FD),
                () {
                  setState(() => _currentTab = 1);
                  _showAddStudentDialog();
                },
              ),
              const SizedBox(width: 12),
              _quickActionCard(
                'Add Course',
                Icons.library_books_rounded,
                const Color(0xFF4CAF50),
                const Color(0xFFE8F5E9),
                () {
                  setState(() => _currentTab = 2);
                  _showAddCourseDialog();
                },
              ),
              const SizedBox(width: 12),
              _quickActionCard(
                'Upload Grades',
                Icons.cloud_upload_rounded,
                const Color(0xFF00BFA5),
                const Color(0xFFE0F2F1),
                () {
                  setState(() => _currentTab = 3);
                  _showAddGradeDialog();
                },
              ),
              const SizedBox(width: 12),
              _quickActionCard(
                'View Reports',
                Icons.description_rounded,
                const Color(0xFF9C27B0),
                const Color(0xFFF3E5F5),
                () {
                  setState(() => _currentTab = 3);
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Recent Activity', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.whiteCard,
            child: Column(
              children: [
                _activityItem(
                  Icons.description_outlined,
                  'Grades uploaded for Spring 2024',
                  '12 May 2024',
                ),
                const Divider(height: 8),
                _activityItem(
                  Icons.person_outline_rounded,
                  'New student registered',
                  '11 May 2024',
                ),
                const Divider(height: 8),
                _activityItem(
                  Icons.edit_note_rounded,
                  'Course updated: CS-302',
                  '10 May 2024',
                ),
                const Divider(height: 8),
                _activitySystemItem(
                  Icons.cloud_done_outlined,
                  'Firestore Connected',
                  '${_students.length} students, ${_courses.length} courses',
                  '5 May 2024',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    String value,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionCard(
    String label,
    IconData icon,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityItem(IconData icon, String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.body)),
          const SizedBox(width: 8),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _activitySystemItem(
    IconData icon,
    String title,
    String subtitle,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  void _showAccountSettings() {
    final p = Provider.of<AppProvider>(context, listen: false);
    final String adminEmail = p.currentStudent?.email ?? 'admin@dgrl.edu';

    final currentPassC = TextEditingController();
    final newPassC = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.whiteCard,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(Icons.person, color: Color(0xFF616161)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          adminEmail,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: currentPassC,
              obscureText: true,
              decoration: _inputDec('Current password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPassC,
              obscureText: true,
              decoration: _inputDec('New password'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final oldP = currentPassC.text.trim();
                      final np = newPassC.text.trim();
                      if (oldP.isEmpty) {
                        _snack('Enter current password');
                        return;
                      }
                      if (np.isEmpty || np.length < 6) {
                        _snack('New password must be at least 6 characters');
                        return;
                      }
                      final ok = await _changePassword(oldP, np);
                      if (ok) {
                        currentPassC.clear();
                        newPassC.clear();
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack('Password updated successfully', ok: true);
                      }
                    },
                    child: const Text('Save New Password'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<bool> _changePassword(String oldPassword, String newPassword) async {
    final p = Provider.of<AppProvider>(context, listen: false);
    _snack('Updating password...');
    try {
      final ok = await p.authService.changePassword(oldPassword, newPassword);
      if (ok) return true;
      _snack('Failed to update password');
      return false;
    } catch (e) {
      _snack('Failed to update password: $e');
      return false;
    }
  }

  // Theme selection dialog
  void _showThemeDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        String tmp = _appTheme;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('App System Theme'),
            content: RadioGroup<String>(
              groupValue: tmp,
              onChanged: (v) => setDialogState(() => tmp = v ?? 'system'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('System Default'),
                    value: 'system',
                  ),
                  RadioListTile<String>(
                    title: const Text('Light Theme'),
                    value: 'light',
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark Theme'),
                    value: 'dark',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() => _appTheme = tmp);
                  final p = Provider.of<AppProvider>(context, listen: false);
                  try {
                    p.setTheme(_appTheme);
                  } catch (_) {}
                  Navigator.pop(ctx);
                  _snack('Theme updated', ok: true);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Help & Support docs dialog
  void _showHelpDocs() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'How to register a new student',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '1. Click the Add Student button on the Students tab.\n2. Fill required fields: Student ID, Full Name, Email, Password.\n3. Click Save to persist the student.',
              ),
              SizedBox(height: 12),
              Text(
                'How to modify existing course records',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '1. Open the Courses tab.\n2. Tap the More menu on a course and choose Edit.\n3. Update fields and click Update to save changes.',
              ),
              SizedBox(height: 12),
              Text(
                'Grade evaluation criteria guidelines',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Grades are computed from Mid, Assignment and Final scores. Ensure totals are normalized to the 0-100 scale before saving.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─── MORE TAB ─────────────────────────────────────────────

  Widget _buildMoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.person, color: Color(0xFF616161)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'admin@dgrl.edu',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            decoration: AppTheme.whiteCard,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text('Account Settings'),
                  onTap: _showAccountSettings,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.palette_outlined,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text('App System Theme'),
                  onTap: _showThemeDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.file_upload_outlined,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text('Import from Excel'),
                  subtitle: const Text('Students, Courses, or Grades'),
                  onTap: _showImportDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.cached_rounded,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text('Clear Database Cache'),
                  onTap: () async {
                    _snack('Clearing cache...');
                    await Future.delayed(const Duration(milliseconds: 400));
                    _snack('Cache cleared', ok: true);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text('Help & Support Documentation'),
                  onTap: _showHelpDocs,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text('About DGRL Platform'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'DGRL Platform',
                      applicationVersion: '1.0.0',
                      children: const [
                        Text('Academic result management system.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final p = Provider.of<AppProvider>(context, listen: false);
              await p.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.logout_rounded, color: AppColors.error),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sign Out',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STUDENTS TAB ───────────────────────────────────────────

  Widget _buildStudentsTab() {
    return Column(
      children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Student Records', style: AppTextStyles.h3),
                ),
                _smallBtn(
                  'Import',
                  Icons.file_upload_outlined,
                  AppColors.success,
                  () => _importStudents(),
                ),
                const SizedBox(width: 8),
                _smallBtn(
                  'Add',
                  Icons.add_rounded,
                  AppColors.info,
                  () => _showAddStudentDialog(),
                ),
              ],
            ),
          ),
        Expanded(
          child: _students.isEmpty
              ? _emptyState('No students yet')
              : RefreshIndicator(
                  onRefresh: _loadStudents,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _students.length,
                    itemBuilder: (_, i) => _studentCard(_students[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _studentCard(Student s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.whiteCard,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              s.studentId.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${s.studentId} • ${s.department} • Batch ${s.batch}',
                  style: AppTextStyles.caption,
                ),
                Text(s.email, style: AppTextStyles.caption),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (v) {
              if (v == 'edit') _showEditStudentDialog(s);
              if (v == 'delete') _confirmDeleteStudent(s.studentId);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: AppColors.info),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    final idC = TextEditingController();
    final nameC = TextEditingController();
    final deptC = TextEditingController();
    final batchC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final phoneC = TextEditingController();
    final ageC = TextEditingController();
    String? sex;

    void _autoFill() {
      final raw = idC.text.trim();
      if (raw.isNotEmpty) {
        final normalized = _normalizeStudentId(raw);
        if (normalized != raw) {
          idC.text = normalized;
          idC.selection = TextSelection.fromPosition(
            TextPosition(offset: normalized.length),
          );
        }
        emailC.text = '$normalized@bdu.edu.et';
        passC.text = normalized;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idC,
                decoration: _inputDec('Student ID* (e.g. bdu12345)'),
                onChanged: (_) => _autoFill(),
              ),
              const SizedBox(height: 10),
              _field(nameC, 'Full Name*'),
              const SizedBox(height: 10),
              _field(deptC, 'Department*'),
              const SizedBox(height: 10),
              _field(batchC, 'Batch*'),
              const SizedBox(height: 10),
              TextField(
                controller: emailC,
                readOnly: true,
                decoration: _inputDec('Email (auto-generated)'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passC,
                readOnly: true,
                obscureText: true,
                decoration: _inputDec('Password (auto-set to Student ID)'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              _field(phoneC, 'Phone'),
              const SizedBox(height: 10),
              _field(ageC, 'Age', num: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: _inputDec('Sex'),
                items: ['Male', 'Female', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => sex = v,
              ),
              const SizedBox(height: 6),
              Text(
                'Student ID must start with "bdu" prefix.\nEmail & password are auto-generated from Student ID.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final normalizedId = _normalizeStudentId(idC.text);
              if (normalizedId.isEmpty || nameC.text.trim().isEmpty) {
                _snack('Student ID and Full Name are required');
                return;
              }
              try {
                await _firestoreService.addStudent(
                  Student(
                    studentId: normalizedId,
                    fullName: nameC.text.trim(),
                    department: deptC.text.trim(),
                    batch: batchC.text.trim().isNotEmpty
                        ? batchC.text.trim()
                        : '2024',
                    email: '$normalizedId@bdu.edu.et',
                    password: normalizedId,
                    phone: phoneC.text.trim().isNotEmpty
                        ? phoneC.text.trim()
                        : null,
                    age: int.tryParse(ageC.text.trim()),
                    sex: sex,
                  ),
                );
                Navigator.pop(ctx);
                await _loadStudents();
                _snack('Student added successfully', ok: true);
              } catch (e) {
                _snack('Error: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(Student s) {
    final nameC = TextEditingController(text: s.fullName);
    final deptC = TextEditingController(text: s.department);
    final batchC = TextEditingController(text: s.batch);
    final emailC = TextEditingController(text: s.email);
    final phoneC = TextEditingController(text: s.phone ?? '');
    final ageC = TextEditingController(text: s.age?.toString() ?? '');
    String? sex = s.sex;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameC, 'Full Name*'),
              const SizedBox(height: 10),
              _field(deptC, 'Department*'),
              const SizedBox(height: 10),
              _field(batchC, 'Batch*'),
              const SizedBox(height: 10),
              _field(emailC, 'Email*'),
              const SizedBox(height: 10),
              _field(phoneC, 'Phone'),
              const SizedBox(height: 10),
              _field(ageC, 'Age', num: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: sex,
                decoration: _inputDec('Sex'),
                items: ['Male', 'Female', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => sex = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _firestoreService.updateStudent(s.studentId, {
                'full_name': nameC.text,
                'department': deptC.text,
                'batch': batchC.text,
                'email': emailC.text,
                'phone': phoneC.text,
                'age': int.tryParse(ageC.text),
                'sex': sex,
              });
              Navigator.pop(ctx);
              await _loadStudents();
              _snack('Student updated', ok: true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStudent(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Remove student "$id"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await _firestoreService.deleteStudent(id);
              Navigator.pop(ctx);
              await _loadStudents();
              _snack('Student deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── COURSES TAB ────────────────────────────────────────────

  Widget _buildCoursesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text('Course Records', style: AppTextStyles.h3),
              ),
              _smallBtn(
                'Import',
                Icons.file_upload_outlined,
                AppColors.info,
                () => _importCourses(),
              ),
              const SizedBox(width: 8),
              _smallBtn(
                'Add',
                Icons.add_rounded,
                AppColors.success,
                () => _showAddCourseDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _courses.isEmpty
              ? _emptyState('No courses yet')
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _courses.length,
                    itemBuilder: (_, i) => _courseCard(_courses[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _courseCard(Course c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.whiteCard,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              c.courseCode,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.courseTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${c.creditHours} Credits • ${c.instructor} • ${c.semester}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (v) {
              if (v == 'edit') _showEditCourseDialog(c);
              if (v == 'delete') _confirmDeleteCourse(c.courseCode);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: AppColors.info),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCourseDialog() {
    final codeC = TextEditingController();
    final titleC = TextEditingController();
    final creditsC = TextEditingController(text: '3');
    final instrC = TextEditingController();
    final semC = TextEditingController();
    final deptC = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(codeC, 'Course Code*'),
              const SizedBox(height: 10),
              _field(titleC, 'Course Title*'),
              const SizedBox(height: 10),
              _field(creditsC, 'Credit Hours*', num: true),
              const SizedBox(height: 10),
              _field(instrC, 'Instructor*'),
              const SizedBox(height: 10),
              _field(semC, 'Semester*'),
              const SizedBox(height: 10),
              _field(deptC, 'Department'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (codeC.text.isEmpty ||
                  titleC.text.isEmpty ||
                  instrC.text.isEmpty ||
                  semC.text.isEmpty) {
                _snack('Fill required fields');
                return;
              }
              final ok = await _courseService.addCourse(
                Course(
                  courseCode: codeC.text,
                  courseTitle: titleC.text,
                  creditHours: int.tryParse(creditsC.text) ?? 3,
                  instructor: instrC.text,
                  semester: semC.text,
                  department: deptC.text,
                  schedule: CourseSchedule(
                    dayOfWeek: 'Monday',
                    startTime: '09:00',
                    endTime: '10:30',
                  ),
                ),
              );
              Navigator.pop(ctx);
              if (ok) {
                await _loadCourses();
                if (mounted) {
                  Provider.of<AppProvider>(context, listen: false)
                      .refreshStudentData();
                }
                _snack('Course added', ok: true);
              } else {
                _snack('Failed to add course');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(Course c) {
    final idx = _courses.indexWhere((crs) => crs.courseCode == c.courseCode);
    final docId = idx >= 0 ? _courseDocIds[idx] : null;

    final titleC = TextEditingController(text: c.courseTitle);
    final creditsC = TextEditingController(text: c.creditHours.toString());
    final instrC = TextEditingController(text: c.instructor);
    final semC = TextEditingController(text: c.semester);
    final deptC = TextEditingController(text: c.department);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titleC, 'Course Title*'),
              const SizedBox(height: 10),
              _field(creditsC, 'Credit Hours*', num: true),
              const SizedBox(height: 10),
              _field(instrC, 'Instructor*'),
              const SizedBox(height: 10),
              _field(semC, 'Semester*'),
              const SizedBox(height: 10),
              _field(deptC, 'Department'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (docId != null) {
                await _courseService.updateCourse(
                  docId,
                  Course(
                    courseCode: c.courseCode,
                    courseTitle: titleC.text,
                    creditHours: int.tryParse(creditsC.text) ?? 3,
                    instructor: instrC.text,
                    semester: semC.text,
                    department: deptC.text,
                    schedule: c.schedule,
                    isActive: c.isActive,
                    maxCapacity: c.maxCapacity,
                    currentEnrolled: c.currentEnrolled,
                    prerequisites: c.prerequisites,
                    room: c.room,
                    building: c.building,
                  ),
                );
              }
              _snack('Course updated', ok: true);
              Navigator.pop(ctx);
              await _loadCourses();
              if (mounted) {
                Provider.of<AppProvider>(context, listen: false)
                    .refreshStudentData();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCourse(String code) {
    final idx = _courses.indexWhere((c) => c.courseCode == code);
    final docId = idx >= 0 ? _courseDocIds[idx] : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Remove course "$code"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (docId != null) {
                await _courseService.deleteCourse(docId);
              }
              _snack('Course deleted');
              Navigator.pop(ctx);
              await _loadCourses();
              if (mounted) {
                Provider.of<AppProvider>(context, listen: false)
                    .refreshStudentData();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── GRADES TAB ─────────────────────────────────────────────

  Widget _buildGradesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Grade Management', style: AppTextStyles.h3),
                  ),
                  _smallBtn(
                    'Import',
                    Icons.file_upload_outlined,
                    AppColors.success,
                    () => _importGrades(),
                  ),
                  const SizedBox(width: 8),
                  _smallBtn(
                    'Add',
                    Icons.add_rounded,
                    AppColors.warning,
                    () => _showAddGradeDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedStudentId,
                decoration: _inputDec('Select Student'),
                items: _students
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.studentId,
                        child: Text('${s.fullName} (${s.studentId})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedStudentId = v);
                  _loadGrades();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _grades.isEmpty
              ? _emptyState('Select a student to view grades')
              : RefreshIndicator(
                  onRefresh: _loadGrades,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _grades.length,
                    itemBuilder: (_, i) => _gradeCard(_grades[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _gradeCard(Map<String, dynamic> g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.whiteCard,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTextStyles.gradeBgColor(
                g['letter_grade'] ?? '',
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              g['letter_grade'] ?? '',
              style: AppTextStyles.gradeColor(g['letter_grade'] ?? ''),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g['course_code'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Total: ${(g['total_score'] as num).toStringAsFixed(1)} • ${g['semester']}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: () => _confirmDeleteGrade(g),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGradeDialog() async {
    final studentC = TextEditingController(text: _selectedStudentId ?? '');
    final courseC = TextEditingController();
    final midC = TextEditingController();
    final assignC = TextEditingController();
    final finalC = TextEditingController();
    final semC = TextEditingController();

    // Load registered courses for the selected student
    List<CourseRegistration> registrations = [];
    if (_selectedStudentId != null && _selectedStudentId!.isNotEmpty) {
      registrations = await _courseService.getStudentRegistrations(
        _selectedStudentId!,
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        String? selectedRegCourse;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Grade'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(studentC, 'Student ID*'),
                  const SizedBox(height: 10),
                  if (registrations.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selectedRegCourse,
                      decoration: _inputDec('Course Code*'),
                      isExpanded: true,
                      items: registrations.map((reg) {
                        String title = reg.courseCode;
                        final idx = _courses.indexWhere(
                          (c) => c.courseCode == reg.courseCode,
                        );
                        if (idx != -1) {
                          title =
                              '${_courses[idx].courseCode} - ${_courses[idx].courseTitle}';
                        }
                        return DropdownMenuItem(
                          value: reg.courseCode,
                          child: Text(title),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          selectedRegCourse = v;
                          courseC.text = v ?? '';
                          if (v != null) {
                            final regIdx = registrations.indexWhere(
                              (r) => r.courseCode == v,
                            );
                            if (regIdx != -1 &&
                                registrations[regIdx].semester.isNotEmpty &&
                                semC.text.isEmpty) {
                              semC.text = registrations[regIdx].semester;
                            }
                          }
                        });
                      },
                    )
                  else
                    _field(courseC, 'Course Code*'),
                  const SizedBox(height: 10),
                  _field(midC, 'Mid Score (0-100)*', num: true),
                  const SizedBox(height: 10),
                  _field(assignC, 'Assignment Score (0-100)*', num: true),
                  const SizedBox(height: 10),
                  _field(finalC, 'Final Score (0-100)*', num: true),
                  const SizedBox(height: 10),
                  _field(semC, 'Semester*'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final sid = _normalizeStudentId(studentC.text);
                  final ccode = courseC.text.trim();
                  final sem = semC.text.trim();

                  if (sid.isEmpty || ccode.isEmpty || sem.isEmpty) {
                    _snack('Fill required fields');
                    return;
                  }

                  // Cross-check student exists
                  final sExists = await _studentExists(sid);
                  if (!sExists) {
                    _snack('Student "$sid" not found in database');
                    return;
                  }

                  // Cross-check course exists
                  final cExists = await _courseExists(ccode);
                  if (!cExists) {
                    _snack('Course "$ccode" not found in database');
                    return;
                  }

                  // Prevent duplicate
                  final dup = await _hasDuplicateGrade(sid, ccode, sem);
                  if (dup) {
                    _snack('Duplicate: "$sid" already has a grade for "$ccode" in "$sem"');
                    return;
                  }

                  final grade = Grade.create(
                    studentId: sid,
                    courseCode: ccode,
                    midScore: double.tryParse(midC.text) ?? 0,
                    assignmentScore: double.tryParse(assignC.text) ?? 0,
                    finalScore: double.tryParse(finalC.text) ?? 0,
                    semester: sem,
                  );
                  final ok = await _gradeService.addGrade(grade);
                  Navigator.pop(ctx);
                  if (ok) {
                    await _loadGrades();
                    _snack('Grade added', ok: true);
                    if (mounted) {
                      Provider.of<AppProvider>(
                        context,
                        listen: false,
                      ).refreshStudentData();
                    }
                  } else {
                    _snack('Failed to add grade');
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteGrade(Map<String, dynamic> g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Grade'),
        content: Text('Remove grade for ${g['course_code']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final gradeId = g['_id'] as String?;
              if (gradeId == null || gradeId.isEmpty) {
                _snack('Cannot delete: missing document ID');
                Navigator.pop(ctx);
                return;
              }
              final ok = await _gradeService.deleteGrade(gradeId);
              Navigator.pop(ctx);
              if (ok) {
                await _loadGrades();
                _snack('Grade deleted', ok: true);
                if (mounted) {
                  Provider.of<AppProvider>(
                    context,
                    listen: false,
                  ).refreshStudentData();
                }
              } else {
                _snack('Failed to delete grade');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1A1A2E),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_rounded),
              label: 'Grades',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  // ─── DRAWER ─────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFF1E88E5),
                    size: 30,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'System Administrator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'admin@dgrl.edu',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
          _drawerItem(Icons.people_rounded, 'Students', 1),
          _drawerItem(Icons.menu_book_rounded, 'Courses', 2),
          _drawerItem(Icons.assessment_rounded, 'Grades', 3),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              Navigator.pop(context);
              final p = Provider.of<AppProvider>(context, listen: false);
              await p.logout();
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

  Widget _drawerItem(IconData icon, String label, int tab) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E88E5)),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentTab = tab);
      },
    );
  }

  // ─── VALIDATION HELPERS ────────────────────────────────────

  String _normalizeStudentId(String id) {
    final trimmed = id.trim().toLowerCase();
    if (trimmed.startsWith('bdu')) return trimmed;
    return 'bdu$trimmed';
  }

  Future<bool> _studentExists(String studentId) async {
    try {
      final s = await _firestoreService.getStudentById(studentId);
      return s != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _courseExists(String courseCode) async {
    try {
      final c = await _courseService.getCourse(courseCode);
      return c != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasDuplicateGrade(
      String studentId, String courseCode, String semester) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('grades')
          .where('student_id', isEqualTo: studentId)
          .where('course_code', isEqualTo: courseCode)
          .where('semester', isEqualTo: semester)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ─── EXCEL IMPORT (staging preview then submit) ─────────────

  /// Called from More tab — asks user which type to import
  Future<void> _showImportDialog() async {
    final importType = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import from Excel'),
        content: const Text('Select the type of data to import:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'students'),
            child: const Text('Students'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'courses'),
            child: const Text('Courses'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'grades'),
            child: const Text('Grades'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (importType == null) return;
    await _runImport(importType);
  }

  /// Direct import from Students tab
  Future<void> _importStudents() => _runImport('students');

  /// Direct import from Courses tab
  Future<void> _importCourses() => _runImport('courses');

  /// Direct import from Grades tab
  Future<void> _importGrades() => _runImport('grades');

  Future<void> _runImport(String importType) async {
    if (!mounted) return;

    final service = ExcelImportService();
    final file = await service.pickExcelFile();
    if (file == null || file.path == null) return;

    if (!mounted) return;
    _snack('Parsing file...');

    // Parse into staging rows (no DB writes yet)
    ParseResult? parseResult;
    try {
      parseResult = switch (importType) {
        'students' => service.parseStudents(file.path!),
        'courses' => service.parseCourses(file.path!),
        'grades' => service.parseGrades(file.path!),
        _ => null,
      };
    } catch (e) {
      _snack('Parse failed: $e');
      return;
    }

    if (parseResult == null || !mounted) return;

    if (parseResult.rows.isEmpty) {
      _snack('No valid rows found in file');
      return;
    }

    // Show staging preview dialog
    final confirmed = await _showStagingPreviewDialog(
      importType: importType,
      parseResult: parseResult,
      service: service,
    );

    if (confirmed == true && mounted) {
      await _loadAll();
    }
  }

  Future<bool?> _showStagingPreviewDialog({
    required String importType,
    required ParseResult parseResult,
    required ExcelImportService service,
  }) {
    final rowsNotifier = ValueNotifier<List<dynamic>>(List.from(parseResult.rows));

    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool submitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final rows = rowsNotifier.value;

            return AlertDialog(
              title: Text('Preview: ${importType[0].toUpperCase()}${importType.substring(1)} Import'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${rows.length} rows loaded from file'),
                    if (parseResult.errors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Parse warnings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ...parseResult.errors.map(
                        (e) => Text('Row ${e.row}: ${e.message}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Editable preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: rows.length.clamp(0, 50),
                        itemBuilder: (context, i) {
                          final row = rows[i];
                          return _buildEditableRow(importType, row, i);
                        },
                      ),
                    ),
                    if (rows.length > 50)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Showing first 50 of ${rows.length} rows', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    if (submitting)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          setDialogState(() => submitting = true);
                          SubmitResult result;
                          try {
                            result = switch (importType) {
                              'students' => await service.submitStudents(
                                  rowsNotifier.value.cast<StagedStudentRow>(),
                                ),
                              'courses' => await service.submitCourses(
                                  rowsNotifier.value.cast<StagedCourseRow>(),
                                ),
                              'grades' => await service.submitGrades(
                                  rowsNotifier.value.cast<StagedGradeRow>(),
                                ),
                              _ => SubmitResult(
                                  successCount: 0,
                                  errorCount: 0,
                                  errors: ['Invalid type'],
                                ),
                            };
                          } catch (e) {
                            setDialogState(() => submitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Submit failed: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                            return;
                          }

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx, true);

                          // Show result dialog
                          showDialog(
                            context: ctx,
                            builder: (rctx) => AlertDialog(
                              title: Text(
                                result.hasErrors
                                    ? 'Completed with Errors'
                                    : 'Import Successful',
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Submitted: ${result.successCount}'),
                                    Text('Errors: ${result.errorCount}'),
                                    if (result.hasErrors) ...[
                                      const SizedBox(height: 12),
                                      const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      ...result.errors.map(
                                        (e) => Text(e, style: const TextStyle(fontSize: 11, color: Colors.red)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(rctx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEditableRow(String importType, dynamic row, int index) {
    // Controllers are stored per row instance
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}.',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: switch (importType) {
              'students' => _studentRowPreview(row as StagedStudentRow),
              'courses' => _courseRowPreview(row as StagedCourseRow),
              'grades' => _gradeRowPreview(row as StagedGradeRow),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  Widget _studentRowPreview(StagedStudentRow s) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _previewField(s.studentId, 90),
          _previewField(s.fullName, 120),
          _previewField(s.department, 100),
          _previewField(s.batch, 50),
          _previewField(s.phone, 100),
          _previewField(s.ageStr, 40),
          _previewField(s.sex, 60),
        ],
      ),
    );
  }

  Widget _courseRowPreview(StagedCourseRow c) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _previewField(c.courseCode, 90),
          _previewField(c.courseTitle, 120),
          _previewField(c.creditHoursStr, 40),
          _previewField(c.instructor, 100),
          _previewField(c.semester, 80),
          _previewField(c.department, 100),
        ],
      ),
    );
  }

  Widget _gradeRowPreview(StagedGradeRow g) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _previewField(g.studentId, 90),
          _previewField(g.courseCode, 90),
          _previewField(g.midStr, 40),
          _previewField(g.assignmentStr, 40),
          _previewField(g.finalStr, 40),
          _previewField(g.semester, 80),
        ],
      ),
    );
  }

  Widget _previewField(String value, double width) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────

  Widget _field(
    TextEditingController c,
    String label, {
    bool obscure = false,
    bool num = false,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: num ? TextInputType.number : TextInputType.text,
      decoration: _inputDec(label),
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _smallBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }
}
