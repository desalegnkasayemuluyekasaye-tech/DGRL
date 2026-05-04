import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../services/student_dashboard_service.dart';
import '../services/report_generation_service.dart';
import '../models/grade.dart';
import 'login_screen.dart';
import 'semester_results_screen.dart';
import 'gpa_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'pdf_export_screen.dart';
import 'notification_screen.dart';
import 'admin_panel_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StudentDashboardService _dashboardService = StudentDashboardService();
  final ReportGenerationService _reportService = ReportGenerationService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Initialize real-time listeners for admin-student communication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.initializeRealtimeListeners();
    });
    
    // Auto-refresh data every 30 seconds to sync with admin changes
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _refreshData();
      }
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.refreshStudentData();
  }

  Future<String?> _getStudentId() async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final student = provider.currentStudent;
      return student?.studentId;
    } catch (e) {
      print('Error getting student ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          key: _scaffoldKey,
          appBar: _currentIndex == 0
              ? _buildHomeAppBar(context, provider)
              : _buildAppBar(context, provider),
          drawer: _buildDrawer(context, provider),
          body: _buildPage(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _navigateToTab,
            selectedItemColor: const Color(0xFF3949AB),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.assessment),
                label: 'Grades',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'GPA',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildHomeAppBar(
    BuildContext context,
    AppProvider provider,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFF3F51B5),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5C6BC0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'DGRL',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            );
          },
        ),
        Consumer<AppProvider>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
                if (provider.unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        provider.unreadNotificationCount > 9
                            ? '9+'
                            : provider.unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Consumer<AppProvider>(
          builder: (context, provider, _) {
            final student = provider.currentStudent;
            return Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  backgroundImage: student?.photoUrl != null && student!.photoUrl!.startsWith('http')
                      ? NetworkImage(student.photoUrl!) as ImageProvider
                      : null,
                  child: student?.photoUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
                onSelected: (value) =>
                    _handleProfileAction(context, provider, value),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'manage_info',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: Color(0xFF3F51B5)),
                        SizedBox(width: 8),
                        Text('Manage Info'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppProvider provider) {
    return AppBar(
      backgroundColor: const Color(0xFF3949AB),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'DGRL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            );
          },
        ),
        Consumer<AppProvider>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
                if (provider.unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        provider.unreadNotificationCount > 9
                            ? '9+'
                            : provider.unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Consumer<AppProvider>(
          builder: (context, provider, _) {
            final student = provider.currentStudent;
            return PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: student?.photoUrl != null && student!.photoUrl!.startsWith('http')
                    ? NetworkImage(student.photoUrl!) as ImageProvider
                    : null,
                child: student?.photoUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                    : null,
              ),
              onSelected: (value) =>
                  _handleProfileAction(context, provider, value),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'manage_info',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Color(0xFF3949AB)),
                      SizedBox(width: 8),
                      Text('Manage Info'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _handleProfileAction(
    BuildContext context,
    AppProvider provider,
    String action,
  ) async {
    switch (action) {
      case 'manage_info':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              scaffoldKey: _scaffoldKey,
              onNavigate: _navigateToTab,
            ),
          ),
        );
        break;
      case 'logout':
        await _showLogoutDialog(context, provider);
        break;
    }
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    AppProvider provider,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await provider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return Consumer<AppProvider>(
          builder: (context, provider, _) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3949AB), Color(0xFF2196F3)],
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
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3949AB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section A: Academic Overview
                            _buildSectionHeader('Academic Overview'),
                            const SizedBox(height: 12),
                            _buildAcademicOverviewCard(),
                            const SizedBox(height: 24),

                            // Section B: Quick Actions
                            _buildSectionHeader('Quick Actions'),
                            const SizedBox(height: 12),
                            _buildQuickActionsGrid(),
                            const SizedBox(height: 24),

                            // Section C: Recent Grades
                            _buildSectionHeader('Recent Grades'),
                            const SizedBox(height: 12),
                            _buildRecentGradesCard(),
                            const SizedBox(height: 24),

                            // Section D: Upcoming Assignments
                            _buildSectionHeader('Upcoming Assignments'),
                            const SizedBox(height: 12),
                            _buildUpcomingAssignmentsCard(),
                            const SizedBox(height: 24),

                            // Section E: Current Semester
                            _buildCurrentSemesterCard(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      case 1:
        return SemesterResultsScreen(
          scaffoldKey: _scaffoldKey,
          onNavigate: _navigateToTab,
        );
      case 2:
        return GPAScreen(scaffoldKey: _scaffoldKey, onNavigate: _navigateToTab);
      case 3:
        return HistoryScreen(
          scaffoldKey: _scaffoldKey,
          onNavigate: _navigateToTab,
        );
      case 4:
        return ProfileScreen(
          scaffoldKey: _scaffoldKey,
          onNavigate: _navigateToTab,
        );
      default:
        return Container(child: const Center(child: Text('Home Page')));
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF3F51B5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3F51B5),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicOverviewCard() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Academic Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewItem(
                      'Current Semester',
                      provider.selectedSemester.isNotEmpty 
                          ? provider.selectedSemester 
                          : 'Not Selected',
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOverviewItem(
                      'Registered Courses',
                      '${provider.grades.length}',
                      Icons.book,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewItem(
                      'Current GPA',
                      provider.selectedGPA.toStringAsFixed(2),
                      Icons.grade,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOverviewItem(
                      'CGPA',
                      provider.cgpa.toStringAsFixed(2),
                      Icons.school,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildQuickActionCard(
          'My Grades',
          Icons.grade,
          Colors.blue,
          'View all courses',
          () => _navigateToTab(1),
        ),
        _buildQuickActionCard(
          'GPA Calculator',
          Icons.calculate,
          Colors.green,
          'Calculate GPA',
          () => _navigateToTab(2),
        ),
        _buildQuickActionCard(
          'Past Results',
          Icons.history,
          Colors.orange,
          'View history',
          () => _navigateToTab(3),
        ),
        _buildQuickActionCard(
          'Generate Report',
          Icons.description,
          Colors.purple,
          'Create reports',
          () => _showReportOptions(),
        ),
        _buildQuickActionCard(
          'Export Data',
          Icons.file_download,
          Colors.teal,
          'Export grades',
          () => _showExportOptions(),
        ),
        _buildQuickActionCard(
          'Academic Stats',
          Icons.analytics,
          Colors.indigo,
          'View analytics',
          () => _showAcademicStats(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSemesterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.15),
                  spreadRadius: 0,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFFFF9800),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Semester',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Spring 2024',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '5 Courses Registered',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Recent Grades Card
  Widget _buildRecentGradesCard() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final recentGrades = provider.grades.take(5).toList();
        
        if (recentGrades.isEmpty) {
          return _buildEmptyCard('No recent grades available');
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...recentGrades.map((grade) => _buildGradeItemFromGrade(grade)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeItemFromGrade(Grade grade) {
    final course = Provider.of<AppProvider>(context, listen: false).getCourseInfo(grade.courseCode);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getGradeColor(grade.letterGrade),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  grade.letterGrade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    grade.courseCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    course?.courseTitle ?? 'Course Title',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  grade.totalScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  grade.semester,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Upcoming Assignments Card
  Widget _buildUpcomingAssignmentsCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getStudentId().then((studentId) => 
        studentId != null ? _dashboardService.getUpcomingAssignments(studentId) : []),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyCard('No upcoming assignments');
        }
        
        final assignments = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Assignments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3949AB),
                ),
              ),
              const SizedBox(height: 12),
              ...assignments.map((assignment) => _buildAssignmentItem(assignment)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentItem(Map<String, dynamic> assignment) {
    final title = assignment['title'] ?? '';
    final courseCode = assignment['courseCode'] ?? '';
    final dueDate = assignment['dueDate'] ?? '';
    final type = assignment['type'] ?? '';
    final weight = assignment['weight'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAssignmentTypeColor(type),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getAssignmentTypeIcon(type),
                color: Colors.white,
                size: 20,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$courseCode • ${_formatDueDate(dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$weight%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Helper methods for UI
  Color _getGradeColor(String letterGrade) {
    switch (letterGrade[0]) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.amber;
      default:
        return Colors.red;
    }
  }

  Color _getAssignmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return Colors.red;
      case 'assignment':
        return Colors.blue;
      case 'project':
        return Colors.purple;
      case 'quiz':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAssignmentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return Icons.assignment;
      case 'assignment':
        return Icons.description;
      case 'project':
        return Icons.code;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.event_note;
    }
  }

  String _formatDueDate(String dueDate) {
    try {
      final date = DateTime.parse(dueDate);
      final now = DateTime.now();
      final difference = date.difference(now);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Tomorrow';
      } else if (difference.inDays <= 7) {
        return '${difference.inDays} days';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return dueDate;
    }
  }

  // Report Generation Methods
  void _showReportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description, color: Colors.purple),
              title: const Text('Grade Report'),
              subtitle: const Text('Current semester grades'),
              onTap: () {
                Navigator.pop(context);
                _generateGradeReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.blue),
              title: const Text('Academic Transcript'),
              subtitle: const Text('Complete academic record'),
              onTap: () {
                Navigator.pop(context);
                _generateAcademicTranscript();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: const Text('Semester Report'),
              subtitle: const Text('Detailed semester analysis'),
              onTap: () {
                Navigator.pop(context);
                _generateSemesterReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.indigo),
              title: const Text('Comprehensive Report'),
              subtitle: const Text('Complete academic overview'),
              onTap: () {
                Navigator.pop(context);
                _generateComprehensiveReport();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code, color: Colors.green),
              title: const Text('JSON Format'),
              subtitle: const Text('Structured data format'),
              onTap: () {
                Navigator.pop(context);
                _exportData('json');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.blue),
              title: const Text('CSV Format'),
              subtitle: const Text('Spreadsheet compatible'),
              onTap: () {
                Navigator.pop(context);
                _exportData('csv');
              },
            ),
            ListTile(
              leading: const Icon(Icons.web, color: Colors.orange),
              title: const Text('XML Format'),
              subtitle: const Text('Web-compatible format'),
              onTap: () {
                Navigator.pop(context);
                _exportData('xml');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAcademicStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Academic Statistics'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: _getStudentId().then((studentId) => 
            studentId != null ? _dashboardService.getCGPADetails(studentId) : {}),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data available'));
            }
            
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem('Current CGPA', '${(data['currentCGPA'] ?? 0.0).toStringAsFixed(2)}'),
                  _buildStatItem('Academic Standing', data['academicStanding'] ?? 'N/A'),
                  _buildStatItem('Honor Status', data['honorStatus'] ?? 'N/A'),
                  _buildStatItem('Total Credits', '${data['totalCredits'] ?? 0}'),
                  const SizedBox(height: 16),
                  const Text('Grade Distribution:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...(data['gradeDistribution'] as Map<String, dynamic>? ?? {}).entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grade ${entry.key}:'),
                          Text('${entry.value}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF3949AB),
            ),
          ),
        ],
      ),
    );
  }

  // Report Generation Methods
  Future<void> _generateGradeReport() async {
    final studentId = await _getStudentId();
    if (studentId == null) return;
    
    try {
      final currentSemester = _getCurrentSemester();
      final report = await _reportService.generateGradeReport(studentId, currentSemester);
      
      if (report.isNotEmpty) {
        _showReportPreview(report, 'Grade Report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  Future<void> _generateAcademicTranscript() async {
    final studentId = await _getStudentId();
    if (studentId == null) return;
    
    try {
      final transcript = await _reportService.generateAcademicTranscript(studentId);
      
      if (transcript.isNotEmpty) {
        _showReportPreview(transcript, 'Academic Transcript');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating transcript: $e')),
      );
    }
  }

  Future<void> _generateSemesterReport() async {
    final studentId = await _getStudentId();
    if (studentId == null) return;
    
    try {
      final currentSemester = _getCurrentSemester();
      final report = await _reportService.generateSemesterReport(studentId, currentSemester);
      
      if (report.isNotEmpty) {
        _showReportPreview(report, 'Semester Report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating semester report: $e')),
      );
    }
  }

  Future<void> _generateComprehensiveReport() async {
    final studentId = await _getStudentId();
    if (studentId == null) return;
    
    try {
      final report = await _reportService.generateComprehensiveReport(studentId);
      
      if (report.isNotEmpty) {
        _showReportPreview(report, 'Comprehensive Report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating comprehensive report: $e')),
      );
    }
  }

  Future<void> _exportData(String format) async {
    final studentId = await _getStudentId();
    if (studentId == null) return;
    
    try {
      final exportData = await _reportService.exportStudentData(studentId, format: format);
      
      if (exportData.isNotEmpty) {
        _showExportPreview(exportData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }

  void _showReportPreview(Map<String, dynamic> report, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Generated: ${report['generatedDate'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              if (report['cgpa'] != null) Text('CGPA: ${report['cgpa']}'),
              if (report['totalCourses'] != null) Text('Total Courses: ${report['totalCourses']}'),
              if (report['academicStanding'] != null) Text('Academic Standing: ${report['academicStanding']}'),
              const SizedBox(height: 16),
              const Text('Report data is ready for download'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report downloaded successfully!')),
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showExportPreview(Map<String, dynamic> exportData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Format: ${exportData['format']}'),
            Text('Filename: ${exportData['filename']}'),
            const SizedBox(height: 16),
            Text('Data preview:'),
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  '${exportData['data'].toString().substring(0, 200)}...',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data exported successfully!')),
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  String _getCurrentSemester() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    
    if (month >= 1 && month <= 5) {
      return 'Spring $year';
    } else if (month >= 6 && month <= 8) {
      return 'Summer $year';
    } else if (month >= 9 && month <= 12) {
      return 'Fall $year';
    }
    return 'Winter $year';
  }

  Widget _buildDrawer(BuildContext context, AppProvider provider) {
    final student = provider.currentStudent;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3949AB), Color(0xFF2196F3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF3949AB)),
                ),
                const SizedBox(height: 16),
                Text(
                  student?.fullName ?? 'Student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  student?.studentId ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF3949AB)),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              _navigateToTab(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment, color: Color(0xFF3949AB)),
            title: const Text('Grades'),
            onTap: () {
              Navigator.pop(context);
              _navigateToTab(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Color(0xFF3949AB)),
            title: const Text('GPA'),
            onTap: () {
              Navigator.pop(context);
              _navigateToTab(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF3949AB)),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context);
              _navigateToTab(3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF3949AB)),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              _navigateToTab(4);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF3949AB)),
            title: const Text('PDF Report'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PdfExportScreen()),
              );
            },
          ),
          if (student?.studentId == 'ADMIN') ...[
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF3949AB),
              ),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
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
}
