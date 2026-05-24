import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/grade.dart';
import '../constants/theme_constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
                  Icon(Icons.history_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Academic History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.background,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        _statCard(
                            'Semesters',
                            '${provider.semesters.length}',
                            Icons.calendar_today_rounded,
                            AppColors.info),
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
                      final grades =
                          provider.getGradesForSemester(semester);
                      final gpa = _calcGPA(grades, provider);
                      final credits = grades.fold<int>(
                          0,
                          (sum, g) => sum +
                              (provider.getCourseInfo(g.courseCode)
                                      ?.creditHours ??
                                  0));
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: AppTheme.whiteCard,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_month_rounded,
                                color: AppColors.primary, size: 22),
                          ),
                          title: Text(semester,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          subtitle: Text('$credits credits',
                              style: AppTextStyles.caption),
                          trailing: Container(
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.grey.shade50,
                              child: Row(
                                children: [
                                  _summaryItem('GPA',
                                      gpa.toStringAsFixed(2), Icons.grade),
                                  _summaryItem(
                                      'Credits', '$credits', Icons.school),
                                  _summaryItem('Courses',
                                      '${grades.length}', Icons.book),
                                ],
                              ),
                            ),
                            ...grades.map((grade) {
                              final course = provider
                                  .getCourseInfo(grade.courseCode);
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    grade.courseCode,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 10),
                                  ),
                                ),
                                title: Text(course?.courseTitle ?? '',
                                    style: const TextStyle(fontSize: 13)),
                                subtitle: Text(
                                    '${course?.creditHours ?? 0} credits • ${grade.totalScore.toStringAsFixed(1)}%',
                                    style: AppTextStyles.caption),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTextStyles.gradeBgColor(
                                            grade.letterGrade)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(grade.letterGrade,
                                      style: AppTextStyles.gradeColor(
                                          grade.letterGrade)),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
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

  Widget _summaryItem(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          Text(title, style: AppTextStyles.caption),
        ],
      ),
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

  Color _gpaColor(double gpa) {
    if (gpa >= 3.7) return AppColors.gradeA;
    if (gpa >= 3.0) return AppColors.gradeB;
    if (gpa >= 2.0) return AppColors.gradeC;
    return AppColors.gradeD;
  }
}
