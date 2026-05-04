import 'package:flutter/material.dart';
import '../models/grade.dart';
import '../models/course.dart';

class GradeBreakdownScreen extends StatelessWidget {
  final Grade grade;
  final Course? course;

  const GradeBreakdownScreen({super.key, required this.grade, this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Grade Breakdown'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3949AB), Color(0xFF2196F3)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grade.courseCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          course?.courseTitle ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      grade.letterGrade,
                      style: TextStyle(
                        color: _getGradeColor(grade.letterGrade),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                          'Total Marks',
                          '${grade.totalScore.toStringAsFixed(1)}%',
                          Icons.assessment,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryItem(
                          'Grade',
                          grade.letterGrade,
                          Icons.grade,
                          _getGradeColor(grade.letterGrade),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryItem(
                          'Credit Hours',
                          '${course?.creditHours ?? 0}',
                          Icons.school,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryItem(
                          'Grade Points',
                          (Grade.gradePoint(grade.letterGrade) * (course?.creditHours ?? 0)).toStringAsFixed(2),
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
            
            // Breakdown Section with Pie Chart
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
                    'Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Pie Chart and Breakdown List
                  Row(
                    children: [
                      // Pie Chart
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 200,
                          child: CustomPaint(
                            painter: PieChartPainter([
                              grade.midScore,
                              grade.assignmentScore,
                              grade.finalScore,
                            ]),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '100%',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3949AB),
                                    ),
                                  ),
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      
                      // Breakdown List
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildBreakdownItem(
                              'Mid Term',
                              grade.midScore,
                              '${(grade.midScore * 0.25).toStringAsFixed(1)}%',
                              Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildBreakdownItem(
                              'Assignments',
                              grade.assignmentScore,
                              '${(grade.assignmentScore * 0.25).toStringAsFixed(1)}%',
                              Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildBreakdownItem(
                              'Final Term',
                              grade.finalScore,
                              '${(grade.finalScore * 0.50).toStringAsFixed(1)}%',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Last Updated
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Last Updated:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Score Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3949AB),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildScoreSection(),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Grade Distribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3949AB),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildGradeDistribution(),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Course Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3949AB),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow('Credit Hours', '${course?.creditHours ?? 0}'),
                  _buildInfoRow('Instructor', course?.instructor ?? 'N/A'),
                  _buildInfoRow('Semester', grade.semester),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildScoreItem('Mid', grade.midScore, 0.25)),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey.withOpacity(0.3),
              ),
              Expanded(
                child: _buildScoreItem(
                  'Assignment',
                  grade.assignmentScore,
                  0.20,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey.withOpacity(0.3),
              ),
              Expanded(child: _buildScoreItem('Final', grade.finalScore, 0.55)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${grade.totalScore.toStringAsFixed(2)} (${grade.letterGrade})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, double score, double weight) {
    return Column(
      children: [
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3949AB),
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          '${(weight * 100).toInt()}%',
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildGradeDistribution() {
    final midPercent = (grade.midScore / 100 * 25).clamp(0, 25).toDouble();
    final assignPercent = (grade.assignmentScore / 100 * 20)
        .clamp(0, 20)
        .toDouble();
    final finalPercent = (grade.finalScore / 100 * 55).clamp(0, 55).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBar('Mid Exam (25%)', midPercent, 25),
          const SizedBox(height: 16),
          _buildBar('Assignment (20%)', assignPercent, 20),
          const SizedBox(height: 16),
          _buildBar('Final Exam (55%)', finalPercent, 55),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double value, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(
              '${value.toStringAsFixed(1)}/${max.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: (value / max).clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3949AB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
  
  // New helper methods for enhanced design
  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String title, double score, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  '${score.toStringAsFixed(1)} marks',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<double> values;

  PieChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    final colors = [Colors.blue, Colors.green, Colors.orange];
    final percentages = [0.25, 0.25, 0.50]; // Mid, Assignment, Final weights
    
    double startAngle = -90 * (3.14159 / 180);
    
    for (int i = 0; i < values.length; i++) {
      final sweepAngle = 360 * percentages[i] * (3.14159 / 180);
      
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
