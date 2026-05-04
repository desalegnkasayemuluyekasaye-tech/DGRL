import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/grade.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.scaffoldKey, this.onNavigate});

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Function(int)? onNavigate;

  @override
  Widget build(BuildContext context) {
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
                // Header with Overall Statistics
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Academic History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3949AB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Overall Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Semesters',
                              '${provider.semesters.length}',
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Overall CGPA',
                              provider.cgpa.toStringAsFixed(2),
                              Icons.grade,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total Courses',
                              '${provider.grades.length}',
                              Icons.book,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Semester History List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.semesters.length,
                    itemBuilder: (context, index) {
                      final semester = provider.semesters[index];
                      final grades = provider.getGradesForSemester(semester);
                      final gpa = _calculateGPA(grades, provider);
                      final totalCredits = _calculateTotalCredits(grades, provider);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 2,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  semester,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF3949AB),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getGPAColor(gpa),
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
                          subtitle: Text(
                            '${grades.length} courses • $totalCredits credits',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          children: [
                            // Semester Summary
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Semester Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3949AB),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryItem(
                                          'GPA',
                                          gpa.toStringAsFixed(2),
                                          Icons.grade,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildSummaryItem(
                                          'Credits',
                                          '$totalCredits',
                                          Icons.school,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildSummaryItem(
                                          'Courses',
                                          '${grades.length}',
                                          Icons.book,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Course List
                            ...grades.map((grade) {
                              final course = provider.getCourseInfo(
                                grade.courseCode,
                              );
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3949AB,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    grade.courseCode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3949AB),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(course?.courseTitle ?? ''),
                                subtitle: Text(
                                  '${course?.creditHours ?? 0} credits • ${grade.totalScore.toStringAsFixed(1)}%',
                                ),
                                trailing: Container(
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
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  double _calculateGPA(List<Grade> grades, AppProvider provider) {
    if (grades.isEmpty) return 0.0;
    
    double totalPoints = 0.0;
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

  int _calculateTotalCredits(List<Grade> grades, AppProvider provider) {
    int totalCredits = 0;
    for (final grade in grades) {
      final course = provider.getCourseInfo(grade.courseCode);
      if (course != null) {
        totalCredits += course.creditHours;
      }
    }
    return totalCredits;
  }

  Color _getGPAColor(double gpa) {
    if (gpa >= 3.7) return Colors.green;
    if (gpa >= 3.3) return Colors.teal;
    if (gpa >= 3.0) return Colors.blue;
    if (gpa >= 2.7) return Colors.orange;
    return Colors.red;
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
}
