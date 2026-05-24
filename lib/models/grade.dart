class Grade {
  final String studentId;
  final String courseCode;
  final double midScore;
  final double assignmentScore;
  final double finalScore;
  final double totalScore;
  final String letterGrade;
  final String semester;

  Grade({
    required this.studentId,
    required this.courseCode,
    required this.midScore,
    required this.assignmentScore,
    required this.finalScore,
    required this.totalScore,
    required this.letterGrade,
    required this.semester,
  });

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      studentId: map['student_id'] ?? '',
      courseCode: map['course_code'] ?? '',
      midScore: (map['mid_score'] ?? 0).toDouble(),
      assignmentScore: (map['assignment_score'] ?? 0).toDouble(),
      finalScore: (map['final_score'] ?? 0).toDouble(),
      totalScore: (map['total_score'] ?? 0).toDouble(),
      letterGrade: map['letter_grade'] ?? '',
      semester: map['semester'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'course_code': courseCode,
      'mid_score': midScore,
      'assignment_score': assignmentScore,
      'final_score': finalScore,
      'total_score': totalScore,
      'letter_grade': letterGrade,
      'semester': semester,
    };
  }

  static String calculateLetterGrade(double total) {
    if (total >= 90) return 'A+';
    if (total >= 85) return 'A';
    if (total >= 80) return 'A-';
    if (total >= 75) return 'B+';
    if (total >= 70) return 'B';
    if (total >= 65) return 'B-';
    if (total >= 60) return 'C+';
    if (total >= 55) return 'C';
    if (total >= 50) return 'C-';
    if (total >= 40) return 'D';
    return 'F';
  }

  static double gradePoint(String letter) {
    switch (letter) {
      case 'A+':
      case 'A':
        return 4.0;
      case 'A-':
        return 3.75;
      case 'B+':
        return 3.5;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.75;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.75;
      case 'D':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // Factory method for creating grade with automatic calculations
  // Total Score = Mid-term + Assignment + Final Exam (each out of their max)
  factory Grade.create({
    required String studentId,
    required String courseCode,
    required double midScore,
    required double assignmentScore,
    required double finalScore,
    required String semester,
  }) {
    final totalScore = midScore + assignmentScore + finalScore;
    final letterGrade = calculateLetterGrade(totalScore);
    
    return Grade(
      studentId: studentId,
      courseCode: courseCode,
      midScore: midScore,
      assignmentScore: assignmentScore,
      finalScore: finalScore,
      totalScore: totalScore,
      letterGrade: letterGrade,
      semester: semester,
    );
  }

  // Method to update scores and recalculate
  Grade updateScores({
    double? midScore,
    double? assignmentScore,
    double? finalScore,
  }) {
    final newMidScore = midScore ?? this.midScore;
    final newAssignmentScore = assignmentScore ?? this.assignmentScore;
    final newFinalScore = finalScore ?? this.finalScore;
    
    final newTotalScore = newMidScore + newAssignmentScore + newFinalScore;
    final newLetterGrade = calculateLetterGrade(newTotalScore);
    
    return Grade(
      studentId: studentId,
      courseCode: courseCode,
      midScore: newMidScore,
      assignmentScore: newAssignmentScore,
      finalScore: newFinalScore,
      totalScore: newTotalScore,
      letterGrade: newLetterGrade,
      semester: semester,
    );
  }

  // Method to get grade color for UI
  String getGradeColor() {
    switch (letterGrade) {
      case 'A+':
      case 'A':
      case 'A-':
        return '#4CAF50'; // Green
      case 'B+':
      case 'B':
      case 'B-':
        return '#2196F3'; // Blue
      case 'C+':
      case 'C':
      case 'C-':
        return '#FF9800'; // Orange
      case 'D':
        return '#FFC107'; // Amber
      default:
        return '#F44336'; // Red
    }
  }

  // Method to get performance level
  String getPerformanceLevel() {
    if (letterGrade.startsWith('A')) return 'Excellent';
    if (letterGrade.startsWith('B')) return 'Good';
    if (letterGrade.startsWith('C')) return 'Satisfactory';
    if (letterGrade == 'D') return 'Needs Improvement';
    return 'Fail';
  }

  // Method to check if grade is passing
  bool get isPassing => letterGrade != 'F';

  // Method to get grade quality points
  double get qualityPoints => gradePoint(letterGrade);
}
