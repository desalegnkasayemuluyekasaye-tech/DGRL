import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/theme_constants.dart';
import 'login_screen.dart';
import 'semester_results_screen.dart';
import 'gpa_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'pdf_export_screen.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  final int initialIndex;
  const EnhancedStudentDashboard({super.key, this.initialIndex = 0});

  @override
  State<EnhancedStudentDashboard> createState() =>
      _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard> {
  late int _currentIndex;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).initializeRealtimeListeners();
    });
  }

  void _navigateToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: _buildDrawer(context, provider),
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, provider),
                Expanded(child: _buildTabContent(provider)),
                _buildBottomNav(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
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
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'DGRL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                if (provider.unreadNotificationCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        provider.unreadNotificationCount > 9
                            ? '9+'
                            : '${provider.unreadNotificationCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(AppProvider provider) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab(provider);
      case 1:
        return const SemesterResultsScreen();
      case 2:
        return GPAScreen();
      case 3:
        return HistoryScreen();
      case 4:
        return ProfileScreen();
      default:
        return _buildDashboardTab(provider);
    }
  }

  Widget _buildDashboardTab(AppProvider provider) {
    final student = provider.currentStudent;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            student?.fullName ?? 'Student',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 24),
          _buildGradientCard(provider),
          const SizedBox(height: 24),
          Text('Quick Actions', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          _buildQuickActions(),
          const SizedBox(height: 24),
          Text('Recent Grades', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          _buildRecentGrades(provider),
        ],
      ),
    );
  }

  Widget _buildGradientCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientCard,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Overview',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.selectedSemester.isNotEmpty
                          ? provider.selectedSemester
                          : 'Current Semester',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.grades.length} Courses',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _overviewItem('GPA', provider.selectedGPA.toStringAsFixed(2), Icons.grade),
              const SizedBox(width: 12),
              _overviewItem('CGPA', provider.cgpa.toStringAsFixed(2), Icons.school),
              const SizedBox(width: 12),
              _overviewItem('Credits', '${provider.grades.fold<int>(0, (sum, g) {
                final c = provider.getCourseInfo(g.courseCode);
                return sum + (c?.creditHours ?? 3);
              })}', Icons.book),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionTile('Grades', Icons.assessment_rounded, AppColors.gradeB, 1),
        const SizedBox(width: 12),
        _actionTile('GPA', Icons.calculate_rounded, AppColors.success, 2),
        const SizedBox(width: 12),
        _actionTile('Report', Icons.description_rounded, AppColors.warning, null, onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PdfExportScreen()),
            )),
      ],
    );
  }

  Widget _actionTile(String label, IconData icon, Color color, int? tab, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () {
          if (tab != null) _navigateToTab(tab);
        },
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

  Widget _buildRecentGrades(AppProvider provider) {
    final recent = provider.grades.take(4).toList();
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.whiteCard,
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No grades yet', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );
    }
    return Column(
      children: recent
          .map((g) => _gradeItem(g, provider.getCourseInfo(g.courseCode)?.courseTitle ?? g.courseCode))
          .toList(),
    );
  }

  Widget _gradeItem(dynamic grade, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.whiteCard,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTextStyles.gradeBgColor(grade.letterGrade).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                grade.letterGrade,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTextStyles.gradeBgColor(grade.letterGrade),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grade.courseCode, style: AppTextStyles.body),
                Text(title, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            grade.totalScore.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

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
          _navItem(Icons.dashboard_rounded, 'Home', 0),
          _navItem(Icons.assessment_rounded, 'Grades', 1),
          _navItem(Icons.calculate_rounded, 'GPA', 2),
          _navItem(Icons.history_rounded, 'History', 3),
          _navItem(Icons.person_rounded, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => _navigateToTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : Colors.white54,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppProvider provider) {
    final student = provider.currentStudent;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      student?.photoUrl?.startsWith('http') == true
                          ? NetworkImage(student!.photoUrl!)
                          : null,
                  child: student?.photoUrl?.startsWith('http') == true
                      ? null
                      : const Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  student?.fullName ?? 'Student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${student?.studentId ?? 'N/A'}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
          _drawerItem(Icons.assessment_rounded, 'Grades', 1),
          _drawerItem(Icons.calculate_rounded, 'GPA Calculator', 2),
          _drawerItem(Icons.history_rounded, 'Academic History', 3),
          _drawerItem(Icons.person_rounded, 'Profile', 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),
          _drawerItem(Icons.notifications_outlined, 'Notifications', null, onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              )),
          _drawerItem(Icons.picture_as_pdf_rounded, 'Export PDF', null, onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PdfExportScreen()),
              )),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Logout',
                style: TextStyle(color: AppColors.error)),
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

  Widget _drawerItem(IconData icon, String label, int? tab, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        (onTap ?? () {
          if (tab != null) _navigateToTab(tab);
        })();
      },
    );
  }
}
