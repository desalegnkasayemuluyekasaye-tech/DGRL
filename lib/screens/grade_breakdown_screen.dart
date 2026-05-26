import 'package:flutter/material.dart';
import '../models/grade.dart';
import '../models/course.dart';
import '../constants/theme_constants.dart';

class GradeBreakdownScreen extends StatelessWidget {
  final Grade grade;
  final Course? course;

  const GradeBreakdownScreen({super.key, required this.grade, this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Grade Breakdown'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.gradientCard,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(grade.courseCode,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text(course?.courseTitle ?? '',
                            style:
                                const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      grade.letterGrade,
                      style: TextStyle(
                        color: AppTextStyles.gradeBgColor(grade.letterGrade),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _summaryCard(
                    'Total', '${grade.totalScore.toStringAsFixed(1)}%',
                    Icons.assessment_rounded, AppColors.primary),
                const SizedBox(width: 10),
                _summaryCard('Grade', grade.letterGrade, Icons.grade_rounded,
                    AppTextStyles.gradeBgColor(grade.letterGrade)),
                const SizedBox(width: 10),
                _summaryCard('Credits', '${course?.creditHours ?? 0}',
                    Icons.school_rounded, AppColors.success),
                const SizedBox(width: 10),
                _summaryCard(
                    'Points',
                    (Grade.gradePoint(grade.letterGrade) *
                            (course?.creditHours ?? 0))
                        .toStringAsFixed(1),
                    Icons.calculate_rounded,
                    AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.whiteCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Score Breakdown', style: AppTextStyles.h3),
                  const SizedBox(height: 20),
                  _breakdownBar('Mid Exam', grade.midScore, 100, AppColors.info),
                  const SizedBox(height: 14),
                  _breakdownBar('Assignment', grade.assignmentScore, 100,
                      AppColors.success),
                  const SizedBox(height: 14),
                  _breakdownBar('Final Exam', grade.finalScore, 100,
                      AppColors.warning),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Score',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(
                          '${grade.totalScore.toStringAsFixed(1)} (${grade.letterGrade})',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.whiteCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Course Information',
                      style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _infoRow('Credit Hours', '${course?.creditHours ?? 0}'),
                  _infoRow('Instructor', course?.instructor ?? 'N/A'),
                  _infoRow('Semester', grade.semester),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(title,
                style: TextStyle(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _breakdownBar(String label, double score, double max, Color color) {
    final pct = (score / 100 * max).clamp(0.0, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            Text('${score.toStringAsFixed(1)}/${max.toInt()}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (pct / max).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
