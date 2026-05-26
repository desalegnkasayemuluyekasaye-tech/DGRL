import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/grade.dart';
import '../../constants/theme_constants.dart';
import 'grade_breakdown_screen.dart';

class CircularGPAIndicator extends StatelessWidget {
  final double gpa;
  final String title;
  final String? subtitle;
  final double size;

  const CircularGPAIndicator({
    super.key,
    required this.gpa,
    required this.title,
    this.subtitle,
    this.size = 130,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (gpa / 4.0).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CirclePainter(progress: 0.0),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CirclePainter(progress: progress, isProgress: true),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gpa.toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final bool isProgress;

  _CirclePainter({required this.progress, this.isProgress = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isProgress && progress > 0) {
      paint.color = Colors.white;
      paint.shader = null;
      final startAngle = -90 * (3.14159 / 180);
      final sweepAngle = 360 * progress * (3.14159 / 180);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    } else if (!isProgress) {
      paint.color = Colors.white.withValues(alpha: 0.2);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GPAScreen extends StatefulWidget {
  const GPAScreen({super.key});

  @override
  State<GPAScreen> createState() => _GPAScreenState();
}

class _GPAScreenState extends State<GPAScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primary,
              child: const Row(
                children: [
                  Icon(Icons.calculate_rounded,
                      color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'GPA / CGPA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.primary,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'GPA'),
                  Tab(text: 'CGPA'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.background,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGPATab(provider),
                    _buildCGPATab(provider),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _calcGPA(List<Grade> grades, AppProvider provider) {
    if (grades.isEmpty) return 0;
    double pts = 0;
    int cr = 0;
    for (final g in grades) {
      final c = provider.getCourseInfo(g.courseCode);
      if (c != null) {
        pts += Grade.gradePoint(g.letterGrade) * c.creditHours;
        cr += c.creditHours;
      }
    }
    return cr > 0 ? pts / cr : 0;
  }

  Widget _buildGPATab(AppProvider provider) {
    final currentGPA = _calcGPA(
      provider.getGradesForSemester(provider.selectedSemester),
      provider,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: AppTheme.gradientCard,
            child: CircularGPAIndicator(
              gpa: currentGPA,
              title: 'Current GPA',
              subtitle: provider.selectedSemester.isNotEmpty
                  ? provider.selectedSemester
                  : null,
              size: 130,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.outlinedCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Semester',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: provider.semesters.isNotEmpty
                        ? provider.selectedSemester
                        : null,
                    underline: const SizedBox(),
                    isExpanded: true,
                    dropdownColor: AppColors.primary,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.white),
                    items: provider.semesters.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) provider.selectSemester(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statCard('Credits',
                  '${provider.getGradesForSemester(provider.selectedSemester).fold(0, (sum, g) {
                    final c = provider.getCourseInfo(g.courseCode);
                    return sum + (c?.creditHours ?? 0);
                  })}',
                  Icons.school_rounded, AppColors.info),
              const SizedBox(width: 10),
              _statCard('GPA', currentGPA.toStringAsFixed(2),
                  Icons.grade_rounded, AppColors.success),
              const SizedBox(width: 10),
              _statCard('Courses',
                  '${provider.getGradesForSemester(provider.selectedSemester).length}',
                  Icons.book_rounded, AppColors.warning),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Course List', style: AppTextStyles.h3),
              Text(
                '${provider.getGradesForSemester(provider.selectedSemester).length} courses',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...provider
              .getGradesForSemester(provider.selectedSemester)
              .map((grade) {
            final course = provider.getCourseInfo(grade.courseCode);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeBreakdownScreen(
                      grade: grade, course: course),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.whiteCard,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(grade.courseCode,
                              style: AppTextStyles.body),
                          Text(course?.courseTitle ?? '',
                              style: AppTextStyles.caption),
                          Text('${course?.creditHours ?? 0} Credits',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTextStyles.gradeBgColor(grade.letterGrade)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        grade.letterGrade,
                        style: AppTextStyles.gradeColor(grade.letterGrade),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textLight, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.outlinedCard,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(title,
                style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCGPATab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: AppTheme.gradientCard,
            child: CircularGPAIndicator(
              gpa: provider.cgpa,
              title: 'Cumulative GPA',
              size: 130,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statCard(
                  'Total Credits', '${provider.grades.fold<int>(0, (sum, g) {
                    final c = provider.getCourseInfo(g.courseCode);
                    return sum + (c?.creditHours ?? 3);
                  })}',
                  Icons.school_rounded, AppColors.info),
              const SizedBox(width: 10),
              _statCard('CGPA', provider.cgpa.toStringAsFixed(2),
                  Icons.grade_rounded, AppColors.success),
              const SizedBox(width: 10),
              _statCard('Courses', '${provider.grades.length}',
                  Icons.book_rounded, AppColors.warning),
            ],
          ),
          const SizedBox(height: 24),
          Text('Semester History', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          ...provider.semesters.map((semester) {
            final grades = provider.getGradesForSemester(semester);
            final gpa = _calcGPA(grades, provider);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.whiteCard,
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(semester,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gpaColor(gpa),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        gpa.toStringAsFixed(2),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
                subtitle: Text('${grades.length} courses',
                    style: AppTextStyles.caption),
                children: grades.map((grade) {
                  final course = provider.getCourseInfo(grade.courseCode);
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(grade.courseCode,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 10)),
                    ),
                    title: Text(course?.courseTitle ?? '',
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text('${course?.creditHours ?? 0} credits',
                        style: AppTextStyles.caption),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTextStyles.gradeBgColor(grade.letterGrade)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(grade.letterGrade,
                          style: AppTextStyles.gradeColor(grade.letterGrade)),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 3.7) return AppColors.gradeA;
    if (gpa >= 3.0) return AppColors.gradeB;
    if (gpa >= 2.0) return AppColors.gradeC;
    return AppColors.gradeD;
  }
}
