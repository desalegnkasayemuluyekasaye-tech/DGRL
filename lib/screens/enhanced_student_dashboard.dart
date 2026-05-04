import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/grade.dart';
import 'login_screen.dart';
import 'semester_results_screen.dart';
import 'gpa_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'pdf_export_screen.dart';
import 'notification_screen.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  final int initialIndex;

  const EnhancedStudentDashboard({super.key, this.initialIndex = 0});

  @override
  State<EnhancedStudentDashboard> createState() => _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Initialize real-time listeners for admin-student communication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.initializeRealtimeListeners();
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F5F5),
          drawer: _buildStudentDrawer(context, provider),
          body: Container(
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
                  _buildHeader(context, provider),
                  Expanded(
                    child: _buildTabContent(provider),
                  ),
                  _buildBottomNavBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF3949AB),
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
              'Student Dashboard',
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

  Widget _buildTabContent(AppProvider provider) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab(provider);
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
        return _buildDashboardTab(provider);
    }
  }

  Widget _buildDashboardTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPISection(provider),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildRecentGrades(provider),
          const SizedBox(height: 32),
          _buildSystemInfo(),
        ],
      ),
    );
  }

  Widget _buildKPISection(AppProvider provider) {
    return Row(
      children: [
        _buildKPICard(
          provider.selectedGPA.toStringAsFixed(2),
          'Current GPA',
          const Color(0xFF1E88E5),
          () {
            setState(() => _currentIndex = 2);
          },
        ),
        const SizedBox(width: 16),
        _buildKPICard(
          provider.cgpa.toStringAsFixed(2),
          'CGPA',
          const Color(0xFF4CAF50),
          () {
            setState(() => _currentIndex = 2);
          },
        ),
        const SizedBox(width: 16),
        _buildKPICard(
          '${provider.grades.length}',
          'Total Grades',
          const Color(0xFF9C27B0),
          () {
            setState(() => _currentIndex = 1);
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
                color: Colors.grey.withValues(alpha: 0.1),
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
              'View Grades',
              Icons.grade,
              const Color(0xFFE3F2FD),
              const Color(0xFF1E88E5),
              () => _navigateToTab(1),
            ),
            const SizedBox(width: 16),
            _buildActionTile(
              'GPA Calculator',
              Icons.calculate,
              const Color(0xFFE8F5E9),
              const Color(0xFF4CAF50),
              () => _navigateToTab(2),
            ),
            const SizedBox(width: 16),
            _buildActionTile(
              'Export Report',
              Icons.description,
              const Color(0xFFFFF3E0),
              const Color(0xFFFF9800),
              () => _showExportOptions(),
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

  Widget _buildRecentGrades(AppProvider provider) {
    final recentGrades = provider.grades.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Grades',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        if (recentGrades.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No grades available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...recentGrades.map((grade) => _buildGradeItem(grade, provider)),
      ],
    );
  }

  Widget _buildGradeItem(Grade grade, AppProvider provider) {
    final course = provider.getCourseInfo(grade.courseCode);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getGradeColor(grade.letterGrade).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            grade.letterGrade,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getGradeColor(grade.letterGrade),
              fontSize: 16,
            ),
          ),
        ),
        title: Text(course?.courseTitle ?? grade.courseCode),
        subtitle: Text(
          'Total: ${grade.totalScore} • Semester: ${grade.semester}',
        ),
        trailing: Text(
          '${grade.totalScore}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getGradeColor(String letterGrade) {
    switch (letterGrade) {
      case 'A+':
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

  Widget _buildSystemInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Status',
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
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cloud,
                    color: Color(0xFF1E88E5),
                    size: 20,
                  ),
                ),
                title: const Text('Connected to Firebase'),
                subtitle: const Text('Real-time sync active'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sync,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                title: const Text('Admin Updates'),
                subtitle: const Text('Receiving real-time updates'),
              ),
            ],
          ),
        ),
      ],
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
            color: Colors.grey.withValues(alpha: 0.3),
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
          _buildNavItem(Icons.assessment, 'Grades', 1),
          _buildNavItem(Icons.calculate, 'GPA', 2),
          _buildNavItem(Icons.history, 'History', 3),
          _buildNavItem(Icons.person, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int tabIndex) {
    final isActive = _currentIndex == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = tabIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFF3949AB),
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

  Widget _buildStudentDrawer(BuildContext context, AppProvider provider) {
    final student = provider.currentStudent;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF3949AB)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  backgroundImage: student?.photoUrl != null && student!.photoUrl!.startsWith('http')
                      ? NetworkImage(student.photoUrl!) as ImageProvider
                      : null,
                  child: student?.photoUrl == null
                      ? const Icon(
                          Icons.person,
                          color: Color(0xFF3949AB),
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(height: 10),
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
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF3949AB)),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.grade, color: Color(0xFF3949AB)),
            title: const Text('Grades'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate, color: Color(0xFF3949AB)),
            title: const Text('GPA Calculator'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF3949AB)),
            title: const Text('Academic History'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF3949AB)),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFF3949AB)),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Color(0xFF3949AB)),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog();
            },
          ),
          const Divider(),
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

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PdfExportScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.blue),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportAsExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.green),
              title: const Text('Export as Text'),
              onTap: () {
                Navigator.pop(context);
                _exportAsText();
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

  void _exportAsExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel export feature coming soon!')),
    );
  }

  void _exportAsText() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text export feature coming soon!')),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Student Dashboard Help',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Dashboard: View your academic overview and quick actions'),
              Text('• Grades: View all your course grades and semester results'),
              Text('• GPA Calculator: Calculate your GPA and CGPA'),
              Text('• History: View your academic history and past results'),
              Text('• Profile: Update your personal information and photo'),
              SizedBox(height: 16),
              Text(
                'Real-time Features',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Automatic updates when admin changes your data'),
              Text('• Real-time grade notifications'),
              Text('• Sync with admin panel for latest information'),
            ],
          ),
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