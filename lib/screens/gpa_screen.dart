import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/grade.dart';
import 'grade_breakdown_screen.dart';

class CircularGPAIndicator extends StatelessWidget {
  const CircularGPAIndicator({
    super.key,
    required this.gpa,
    required this.title,
    this.subtitle,
    this.size = 150.0,
  });

  final double gpa;
  final String title;
  final String? subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = (gpa / 4.0).clamp(0.0, 1.0);
    final isFullCircle = gpa >= 4.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: CirclePainter(
                progress: 0.0,
                backgroundColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: CirclePainter(
                progress: progress,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFullCircle ? 'Full Circle' : gpa.toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isFullCircle ? 18 : 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isFullCircle) ...[
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter({
    required this.progress,
    this.backgroundColor = Colors.transparent,
  });

  final double progress;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 12.0;

    // Draw background circle
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, backgroundPaint);
    }

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final startAngle = -90 * (3.14159 / 180); // Start from top
      final sweepAngle = 360 * progress * (3.14159 / 180);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class GPAScreen extends StatefulWidget {
  const GPAScreen({super.key, this.scaffoldKey, this.onNavigate});

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Function(int)? onNavigate;

  @override
  State<GPAScreen> createState() => _GPAScreenState();
}

class _GPAScreenState extends State<GPAScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSemester = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Helper method to group semesters by academic year
  Map<String, List<String>> _groupSemestersByYear(List<String> semesters) {
    final Map<String, List<String>> yearMap = {};

    for (final semester in semesters) {
      final parts = semester.split(' ');
      if (parts.length >= 2) {
        final season = parts[0];
        final year = parts[1];

        // Academic year spans from Fall to Spring
        String academicYear;
        if (season == 'Fall') {
          academicYear = '$year-${(int.parse(year) + 1).toString()}';
        } else if (season == 'Spring') {
          academicYear = '${(int.parse(year) - 1).toString()}-$year';
        } else {
          academicYear = year;
        }

        if (!yearMap.containsKey(academicYear)) {
          yearMap[academicYear] = [];
        }
        yearMap[academicYear]!.add(semester);
      }
    }

    // Sort semesters within each year (Fall first, then Spring)
    for (final year in yearMap.keys) {
      yearMap[year]!.sort((a, b) {
        final aSeason = a.split(' ')[0];
        final bSeason = b.split(' ')[0];
        if (aSeason == 'Fall' && bSeason == 'Spring') return -1;
        if (aSeason == 'Spring' && bSeason == 'Fall') return 1;
        return a.compareTo(b);
      });
    }

    return yearMap;
  }

  // Get current academic year
  String _getCurrentAcademicYear(List<String> semesters) {
    if (semesters.isEmpty) return '';
    final yearMap = _groupSemestersByYear(semesters);
    final years = yearMap.keys.toList()..sort();
    return years.isNotEmpty ? years.last : '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (_selectedSemester.isEmpty && provider.semesters.isNotEmpty) {
          _selectedSemester = provider.semesters.last;
        }

        final currentGPA = _calculateCurrentSemesterGPA(provider);

        return Container(
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                  top: 40,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                color: const Color(0xFF3949AB),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'GPA / CGPA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: const Color(0xFF3949AB),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'GPA Calculator'),
                    Tab(text: 'CGPA Calculator'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGPACalculatorTab(currentGPA, provider),
                    _buildCGPACalculatorTab(provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGPACalculatorTab(double currentGPA, AppProvider provider) {
    final yearMap = _groupSemestersByYear(provider.semesters);
    final currentAcademicYear = _getCurrentAcademicYear(provider.semesters);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Color(0xFF3949AB)),
                    SizedBox(width: 12),
                    Text(
                      'Academic Year',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3949AB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (yearMap.isNotEmpty) ...[
                  Text(
                    currentAcademicYear,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3949AB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: provider.semesters.isNotEmpty
                                ? provider.selectedSemester
                                : null,
                            underline: const SizedBox(),
                            dropdownColor: const Color(0xFF3949AB),
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                            isExpanded: true,
                            items:
                                yearMap[currentAcademicYear]?.map((semester) {
                                  return DropdownMenuItem(
                                    value: semester,
                                    child: Text(
                                      semester,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList() ??
                                [],
                            onChanged: (value) {
                              if (value != null) provider.selectSemester(value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'No semesters available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3949AB), Color(0xFF2196F3)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircularGPAIndicator(
                  gpa: currentGPA,
                  title: 'Current GPA',
                  subtitle: provider.selectedSemester.isNotEmpty
                      ? provider.selectedSemester
                      : null,
                  size: 120.0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Summary Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3949AB),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Credit Hours',
                        _calculateTotalCredits(provider),
                        Icons.school,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Grade Points',
                        _calculateTotalGradePoints(provider),
                        Icons.grade,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        'GPA',
                        currentGPA,
                        Icons.calculate,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Course List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3949AB),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...provider.getGradesForSemester(provider.selectedSemester).map((
            grade,
          ) {
            final course = provider.getCourseInfo(grade.courseCode);
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GradeBreakdownScreen(
                      grade: grade,
                      course: course,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grade.courseCode,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            course?.courseTitle ?? 'Course Title',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${course?.creditHours ?? 0} Credits',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getGradeColor(grade.letterGrade),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        grade.letterGrade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCGPACalculatorTab(AppProvider provider) {
    final yearMap = _groupSemestersByYear(provider.semesters);
    final sortedYears = yearMap.keys.toList()..sort((a, b) => a.compareTo(b));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3949AB), Color(0xFF2196F3)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircularGPAIndicator(
                  gpa: provider.cgpa,
                  title: 'Cumulative GPA',
                  size: 120.0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // CGPA Summary Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cumulative Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3949AB),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Credit Hours',
                        _calculateCumulativeCredits(provider),
                        Icons.school,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Grade Points',
                        _calculateCumulativeGradePoints(provider),
                        Icons.grade,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        'CGPA',
                        provider.cgpa,
                        Icons.calculate,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...sortedYears.map((academicYear) {
            final semesters = yearMap[academicYear]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3949AB).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school, color: Color(0xFF3949AB)),
                        const SizedBox(width: 8),
                        Text(
                          'Academic Year $academicYear',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3949AB),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${semesters.length} Semesters',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...semesters.map((semester) {
                    final grades = provider.getGradesForSemester(semester);
                    final gpa = _calculateGPA(grades, provider);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  semester,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${grades.length} Courses',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getGradeColor(_getLetterGrade(gpa)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              gpa.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  double _calculateCurrentSemesterGPA(AppProvider provider) {
    final grades = provider.getGradesForSemester(provider.selectedSemester);
    return _calculateGPA(grades, provider);
  }

  double _calculateGPA(List<Grade> grades, AppProvider provider) {
    if (grades.isEmpty) return 0.0;
    double totalPoints = 0;
    int totalCredits = 0;
    for (final grade in grades) {
      final course = provider.getCourseInfo(grade.courseCode);
      if (course != null) {
        totalPoints += Grade.gradePoint(grade.letterGrade) * course.creditHours;
        totalCredits += course.creditHours;
      }
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  Color _getGradeColor(String letterGrade) {
    switch (letterGrade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'A-':
        return Colors.teal;
      case 'B+':
      case 'B':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getLetterGrade(double gpa) {
    if (gpa >= 3.7) return 'A';
    if (gpa >= 3.3) return 'A-';
    if (gpa >= 3.0) return 'B+';
    if (gpa >= 2.7) return 'B';
    if (gpa >= 2.3) return 'B-';
    return 'C';
  }
  
  // Helper methods for summary section
  Widget _buildSummaryItem(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value is double ? value.toStringAsFixed(2) : value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  int _calculateTotalCredits(AppProvider provider) {
    final grades = provider.getGradesForSemester(provider.selectedSemester);
    int totalCredits = 0;
    for (final grade in grades) {
      final course = provider.getCourseInfo(grade.courseCode);
      if (course != null) {
        totalCredits += course.creditHours;
      }
    }
    return totalCredits;
  }
  
  double _calculateTotalGradePoints(AppProvider provider) {
    final grades = provider.getGradesForSemester(provider.selectedSemester);
    double totalPoints = 0;
    for (final grade in grades) {
      final course = provider.getCourseInfo(grade.courseCode);
      if (course != null) {
        totalPoints += Grade.gradePoint(grade.letterGrade) * course.creditHours;
      }
    }
    return totalPoints;
  }
  
  // Cumulative calculation methods
  int _calculateCumulativeCredits(AppProvider provider) {
    int totalCredits = 0;
    for (final grade in provider.grades) {
      final course = provider.getCourseInfo(grade.courseCode);
      if (course != null) {
        totalCredits += course.creditHours;
      }
    }
    return totalCredits;
  }
  
  double _calculateCumulativeGradePoints(AppProvider provider) {
    double totalPoints = 0;
    for (final grade in provider.grades) {
      final course = provider.getCourseInfo(grade.courseCode);
      if (course != null) {
        totalPoints += Grade.gradePoint(grade.letterGrade) * course.creditHours;
      }
    }
    return totalPoints;
  }
}
