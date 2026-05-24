import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/theme_constants.dart';
import '../services/firestore_service.dart';
import '../services/course_service.dart';
import '../services/grade_service.dart';
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
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Admin Panel',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 20),
          Row(
            children: [
              _kpiCard('${_students.length}', 'Students',
                  Icons.people_rounded, AppColors.info, () {
                setState(() => _currentTab = 1);
              }),
              const SizedBox(width: 12),
              _kpiCard('${_courses.length}', 'Courses',
                  Icons.menu_book_rounded, AppColors.success, () {
                setState(() => _currentTab = 2);
              }),
              const SizedBox(width: 12),
              _kpiCard('${_grades.length}', 'Grades',
                  Icons.assessment_rounded, AppColors.warning, () {
                setState(() => _currentTab = 3);
              }),
            ],
          ),
          const SizedBox(height: 32),
          Text('Quick Actions', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          Row(
            children: [
              _actionCard(
                  'Add Student', Icons.person_add_rounded, AppColors.info,
                  () {
                setState(() => _currentTab = 1);
                _showAddStudentDialog();
              }),
              const SizedBox(width: 12),
              _actionCard('Add Course', Icons.menu_book_rounded,
                  AppColors.success, () {
                setState(() => _currentTab = 2);
                _showAddCourseDialog();
              }),
              const SizedBox(width: 12),
              _actionCard('Add Grade', Icons.grade_rounded, AppColors.warning,
                  () {
                setState(() => _currentTab = 3);
                _showAddGradeDialog();
              }),
            ],
          ),
          const SizedBox(height: 32),
          Text('Recent Activity', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.whiteCard,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Firestore Connected',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_students.length} students, ${_courses.length} courses',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String value, String label, IconData icon, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.outlinedCard,
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: AppTheme.outlinedCard,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
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
                child: Text('Student Records',
                    style: AppTextStyles.h3),
              ),
              _smallBtn('Add', Icons.add_rounded, AppColors.info,
                  _showAddStudentDialog),
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
            child: Text(s.studentId.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                    '${s.studentId} • ${s.department} • Batch ${s.batch}',
                    style: AppTextStyles.caption),
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
                  child: Row(children: [
                    Icon(Icons.edit, size: 18, color: AppColors.info),
                    SizedBox(width: 8),
                    Text('Edit')
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete')
                  ])),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(idC, 'Student ID*'),
              const SizedBox(height: 10),
              _field(nameC, 'Full Name*'),
              const SizedBox(height: 10),
              _field(deptC, 'Department*'),
              const SizedBox(height: 10),
              _field(batchC, 'Batch*'),
              const SizedBox(height: 10),
              _field(emailC, 'Email*'),
              const SizedBox(height: 10),
              _field(passC, 'Password*', obscure: true),
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
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (idC.text.isEmpty || nameC.text.isEmpty || emailC.text.isEmpty ||
                  passC.text.isEmpty) {
                _snack('Fill required fields');
                return;
              }
              try {
                await _firestoreService.addStudent(Student(
                  studentId: idC.text,
                  fullName: nameC.text,
                  department: deptC.text,
                  batch: batchC.text,
                  email: emailC.text,
                  password: passC.text,
                  phone: phoneC.text,
                  age: int.tryParse(ageC.text),
                  sex: sex,
                ));
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info, foregroundColor: Colors.white),
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
              child: const Text('Cancel')),
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
                  child: Text('Course Records', style: AppTextStyles.h3)),
              _smallBtn('Add', Icons.add_rounded, AppColors.success,
                  _showAddCourseDialog),
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
            child: Text(c.courseCode,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: 12)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.courseTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                    '${c.creditHours} Credits • ${c.instructor} • ${c.semester}',
                    style: AppTextStyles.caption),
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
                  child: Row(children: [
                    Icon(Icons.edit, size: 18, color: AppColors.info),
                    SizedBox(width: 8),
                    Text('Edit')
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete')
                  ])),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, foregroundColor: Colors.white),
            onPressed: () async {
              if (codeC.text.isEmpty || titleC.text.isEmpty ||
                  instrC.text.isEmpty || semC.text.isEmpty) {
                _snack('Fill required fields');
                return;
              }
              final ok = await _courseService.addCourse(Course(
                courseCode: codeC.text,
                courseTitle: titleC.text,
                creditHours: int.tryParse(creditsC.text) ?? 3,
                instructor: instrC.text,
                semester: semC.text,
                department: deptC.text,
                schedule: CourseSchedule(
                    dayOfWeek: 'Monday',
                    startTime: '09:00',
                    endTime: '10:30'),
              ));
              Navigator.pop(ctx);
              if (ok) {
                await _loadCourses();
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
    final creditsC =
        TextEditingController(text: c.creditHours.toString());
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info, foregroundColor: Colors.white),
            onPressed: () async {
              if (docId != null) {
                await _courseService.updateCourse(docId, Course(
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
                ));
              }
              _snack('Course updated', ok: true);
              Navigator.pop(ctx);
              await _loadCourses();
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
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (docId != null) {
                await _courseService.deleteCourse(docId);
              }
              _snack('Course deleted');
              Navigator.pop(ctx);
              await _loadCourses();
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
                      child: Text('Grade Management',
                          style: AppTextStyles.h3)),
                  _smallBtn('Add', Icons.add_rounded, AppColors.warning,
                      _showAddGradeDialog),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedStudentId,
                decoration: _inputDec('Select Student'),
                items: _students
                    .map((s) => DropdownMenuItem(
                        value: s.studentId,
                        child: Text('${s.fullName} (${s.studentId})')))
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
              color: AppTextStyles.gradeBgColor(g['letter_grade'] ?? '')
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(g['letter_grade'] ?? '',
                style: AppTextStyles.gradeColor(g['letter_grade'] ?? '')),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g['course_code'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Total: ${(g['total_score'] as num).toStringAsFixed(1)} • ${g['semester']}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
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
      registrations = await _courseService.getStudentRegistrations(_selectedStudentId!);
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
                      value: selectedRegCourse,
                      decoration: _inputDec('Course Code*'),
                      isExpanded: true,
                      items: registrations.map((reg) {
                        String title = reg.courseCode;
                        final idx = _courses.indexWhere((c) => c.courseCode == reg.courseCode);
                        if (idx != -1) {
                          title = '${_courses[idx].courseCode} - ${_courses[idx].courseTitle}';
                        }
                        return DropdownMenuItem(value: reg.courseCode, child: Text(title));
                      }).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          selectedRegCourse = v;
                          courseC.text = v ?? '';
                          if (v != null) {
                            final regIdx = registrations.indexWhere((r) => r.courseCode == v);
                            if (regIdx != -1 && registrations[regIdx].semester.isNotEmpty && semC.text.isEmpty) {
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning, foregroundColor: Colors.white),
                onPressed: () async {
                  if (studentC.text.isEmpty || courseC.text.isEmpty ||
                      semC.text.isEmpty) {
                    _snack('Fill required fields');
                    return;
                  }
                  final grade = Grade.create(
                    studentId: studentC.text,
                    courseCode: courseC.text,
                    midScore: double.tryParse(midC.text) ?? 0,
                    assignmentScore: double.tryParse(assignC.text) ?? 0,
                    finalScore: double.tryParse(finalC.text) ?? 0,
                    semester: semC.text,
                  );
                  final ok = await _gradeService.addGrade(grade);
                  Navigator.pop(ctx);
                  if (ok) {
                    await _loadGrades();
                    _snack('Grade added', ok: true);
                    // Refresh provider so student sees it
                    if (mounted) {
                      Provider.of<AppProvider>(context, listen: false)
                          .refreshStudentData();
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
              child: const Text('Cancel')),
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
                  Provider.of<AppProvider>(context, listen: false)
                      .refreshStudentData();
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.dashboard_rounded, 'Dashboard', 0),
          _navItem(Icons.people_rounded, 'Students', 1),
          _navItem(Icons.menu_book_rounded, 'Courses', 2),
          _navItem(Icons.assessment_rounded, 'Grades', 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF1E88E5).withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? Colors.white : Colors.white54, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontSize: 10,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal)),
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
                  child: Icon(Icons.admin_panel_settings_rounded,
                      color: Color(0xFF1E88E5), size: 30),
                ),
                SizedBox(height: 14),
                Text('System Administrator',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('admin@dgrl.edu',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
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
            title: const Text('Logout',
                style: TextStyle(color: AppColors.error)),
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

  // ─── HELPERS ────────────────────────────────────────────────

  Widget _field(TextEditingController c, String label,
      {bool obscure = false, bool num = false}) {
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _smallBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
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
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, color: color)),
          ],
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }
}
