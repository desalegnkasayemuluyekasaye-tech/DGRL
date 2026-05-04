import '../services/grade_service.dart';
import '../services/course_service.dart';
import '../services/student_dashboard_service.dart';
import '../models/grade.dart';
import '../models/course_registration.dart';

class ReportGenerationService {
  final GradeService _gradeService = GradeService();
  final CourseService _courseService = CourseService();
  final StudentDashboardService _dashboardService = StudentDashboardService();

  // PDF Grade Reports
  Future<Map<String, dynamic>> generateGradeReport(String studentId, String semester) async {
    try {
      final grades = await _gradeService.getGradesForSemester(studentId, semester);
      final cgpa = await _gradeService.calculateGPA(studentId, semester);
      final statistics = await _gradeService.getGradeStatistics(studentId);
      
      // Calculate semester statistics
      final semesterGrades = grades.where((g) => g.semester == semester).toList();
      final semesterAvg = semesterGrades.isNotEmpty
          ? semesterGrades.map((g) => g.totalScore).reduce((a, b) => a + b) / semesterGrades.length
          : 0.0;
      
      // Get course details
      final courseDetails = <Map<String, dynamic>>[];
      for (var grade in semesterGrades) {
        final course = await _courseService.getCourse(grade.courseCode);
        courseDetails.add({
          'grade': grade.toMap(),
          'course': course?.toMap() ?? {},
          'performanceLevel': grade.getPerformanceLevel(),
          'gradeColor': grade.getGradeColor(),
        });
      }
      
      return {
        'studentId': studentId,
        'semester': semester,
        'reportType': 'grade_report',
        'generatedDate': DateTime.now().toIso8601String(),
        'cgpa': cgpa,
        'semesterAverage': semesterAvg,
        'totalCourses': semesterGrades.length,
        'courseDetails': courseDetails,
        'gradeDistribution': statistics['gradeDistribution'] ?? {},
        'academicStanding': _getAcademicStanding(cgpa),
        'recommendations': _generateRecommendations(semesterGrades),
      };
    } catch (e) {
      print('Generate grade report error: $e');
      return {};
    }
  }

  // Academic Transcripts
  Future<Map<String, dynamic>> generateAcademicTranscript(String studentId) async {
    try {
      final allGrades = await _gradeService.getGradesForStudent(studentId);
      final statistics = await _gradeService.getGradeStatistics(studentId);
      final cgpa = await _gradeService.calculateCGPA(studentId);
      final registrations = await _courseService.getStudentRegistrations(studentId);
      
      // Group grades by semester
      final semesterGrades = <String, List<Grade>>{};
      for (var grade in allGrades) {
        semesterGrades.putIfAbsent(grade.semester, () => []).add(grade);
      }
      
      // Generate transcript data for each semester
      final transcriptData = <Map<String, dynamic>>[];
      int totalCredits = 0;
      double cumulativeGPA = 0.0;
      
      for (String semester in semesterGrades.keys.toList()..sort()) {
        final grades = semesterGrades[semester]!;
        final semesterGPA = await _gradeService.calculateGPA(studentId, semester);
        final semesterCredits = grades.length * 3; // Assuming 3 credits per course
        
        totalCredits += semesterCredits;
        cumulativeGPA = (cumulativeGPA * (totalCredits - semesterCredits) + semesterGPA * semesterCredits) / totalCredits;
        
        transcriptData.add({
          'semester': semester,
          'gpa': semesterGPA,
          'credits': semesterCredits,
          'courses': grades.map((grade) => {
            'courseCode': grade.courseCode,
            'courseTitle': grade.courseCode, // Use courseCode as title for now
            'creditHours': 3, // Standard credit hours
            'grade': grade.letterGrade,
            'score': grade.totalScore,
            'performanceLevel': grade.getPerformanceLevel(),
          }).toList(),
        });
      }
      
      return {
        'studentId': studentId,
        'reportType': 'academic_transcript',
        'generatedDate': DateTime.now().toIso8601String(),
        'finalCGPA': cgpa,
        'cumulativeGPA': cumulativeGPA,
        'totalCredits': totalCredits,
        'totalCourses': allGrades.length,
        'academicStanding': _getAcademicStanding(cgpa),
        'honorStatus': _getHonorStatus(cgpa),
        'semesters': transcriptData,
        'gradeDistribution': statistics['gradeDistribution'] ?? {},
        'completionDate': _getEstimatedCompletionDate(registrations),
      };
    } catch (e) {
      print('Generate academic transcript error: $e');
      return {};
    }
  }

  // Semester Reports
  Future<Map<String, dynamic>> generateSemesterReport(String studentId, String semester) async {
    try {
      final grades = await _gradeService.getGradesForSemester(studentId, semester);
      final registrations = await _courseService.getStudentRegistrations(studentId, semester: semester);
      final cgpa = await _gradeService.calculateGPA(studentId, semester);
      final performanceTrends = await _dashboardService.getPerformanceTrends(studentId);
      
      // Get course details
      final courseDetails = <Map<String, dynamic>>[];
      for (var registration in registrations) {
        final course = await _courseService.getCourse(registration.courseCode);
        final grade = grades.firstWhere(
          (g) => g.courseCode == registration.courseCode,
          orElse: () => Grade.create(
            studentId: studentId,
            courseCode: registration.courseCode,
            midScore: 0,
            assignmentScore: 0,
            finalScore: 0,
            semester: semester,
          ),
        );
        
        courseDetails.add({
          'course': course?.toMap() ?? {},
          'grade': grade.toMap(),
          'registration': registration.toMap(),
          'attendance': _generateMockAttendance(registration.courseCode),
          'participation': _generateMockParticipation(registration.courseCode),
        });
      }
      
      return {
        'studentId': studentId,
        'semester': semester,
        'reportType': 'semester_report',
        'generatedDate': DateTime.now().toIso8601String(),
        'gpa': cgpa,
        'totalCredits': registrations.length * 3,
        'totalCourses': registrations.length,
        'courseDetails': courseDetails,
        'performanceTrend': performanceTrends['semesterPerformance'][semester] ?? {},
        'semesterRanking': _generateMockRanking(cgpa),
        'extracurricularActivities': _generateMockActivities(),
        'facultyFeedback': _generateMockFacultyFeedback(courseDetails),
        'recommendations': _generateSemesterRecommendations(grades),
      };
    } catch (e) {
      print('Generate semester report error: $e');
      return {};
    }
  }

  // Export Functionality
  Future<Map<String, dynamic>> exportStudentData(String studentId, {String format = 'json'}) async {
    try {
      final grades = await _gradeService.getGradesForStudent(studentId);
      final registrations = await _courseService.getStudentRegistrations(studentId);
      final statistics = await _gradeService.getGradeStatistics(studentId);
      final cgpa = await _gradeService.calculateCGPA(studentId);
      
      final exportData = {
        'studentId': studentId,
        'exportDate': DateTime.now().toIso8601String(),
        'format': format,
        'academicSummary': {
          'totalGrades': grades.length,
          'cgpa': cgpa,
          'totalCredits': registrations.length * 3,
          'academicStanding': _getAcademicStanding(cgpa),
          'gradeDistribution': statistics['gradeDistribution'] ?? {},
        },
        'grades': grades.map((g) => g.toMap()).toList(),
        'registrations': registrations.map((r) => r.toMap()).toList(),
        'statistics': statistics,
      };
      
      if (format == 'csv') {
        return {
          'data': _convertToCSV(exportData),
          'filename': 'student_data_${DateTime.now().millisecondsSinceEpoch}.csv',
          'mimeType': 'text/csv',
        };
      } else if (format == 'xml') {
        return {
          'data': _convertToXML(exportData),
          'filename': 'student_data_${DateTime.now().millisecondsSinceEpoch}.xml',
          'mimeType': 'application/xml',
        };
      } else {
        return {
          'data': exportData,
          'filename': 'student_data_${DateTime.now().millisecondsSinceEpoch}.json',
          'mimeType': 'application/json',
        };
      }
    } catch (e) {
      print('Export student data error: $e');
      return {};
    }
  }

  // Comprehensive Student Report
  Future<Map<String, dynamic>> generateComprehensiveReport(String studentId) async {
    try {
      final gradeOverview = await _dashboardService.getGradeOverview(studentId);
      final cgpaDetails = await _dashboardService.getCGPADetails(studentId);
      final performanceTrends = await _dashboardService.getPerformanceTrends(studentId);
      final scheduleOverview = await _dashboardService.getScheduleOverview(studentId);
      
      return {
        'studentId': studentId,
        'reportType': 'comprehensive_report',
        'generatedDate': DateTime.now().toIso8601String(),
        'gradeOverview': gradeOverview,
        'cgpaDetails': cgpaDetails,
        'performanceTrends': performanceTrends,
        'scheduleOverview': scheduleOverview,
        'recommendations': _generateComprehensiveRecommendations(gradeOverview, performanceTrends),
        'achievements': _generateAchievements(cgpaDetails),
        'goals': _generateAcademicGoals(gradeOverview),
      };
    } catch (e) {
      print('Generate comprehensive report error: $e');
      return {};
    }
  }

  // Helper methods
  String _getAcademicStanding(double cgpa) {
    if (cgpa >= 3.5) return 'Excellent';
    if (cgpa >= 3.0) return 'Good';
    if (cgpa >= 2.0) return 'Satisfactory';
    if (cgpa >= 1.0) return 'Probation';
    return 'At Risk';
  }

  String _getHonorStatus(double cgpa) {
    if (cgpa >= 3.8) return 'Summa Cum Laude';
    if (cgpa >= 3.6) return 'Magna Cum Laude';
    if (cgpa >= 3.4) return 'Cum Laude';
    if (cgpa >= 3.0) return 'Dean\'s List';
    return 'No Honors';
  }

  List<String> _generateRecommendations(List<Grade> grades) {
    final recommendations = <String>[];
    
    final failingGrades = grades.where((g) => !g.isPassing).toList();
    if (failingGrades.isNotEmpty) {
      recommendations.add('Focus on improving performance in: ${failingGrades.map((g) => g.courseCode).join(', ')}');
    }
    
    final excellentGrades = grades.where((g) => g.letterGrade.startsWith('A')).toList();
    if (excellentGrades.isNotEmpty) {
      recommendations.add('Consider advanced studies in: ${excellentGrades.map((g) => g.courseCode).join(', ')}');
    }
    
    if (grades.length < 4) {
      recommendations.add('Consider taking more courses to increase academic exposure');
    }
    
    return recommendations;
  }

  String _getEstimatedCompletionDate(List<CourseRegistration> registrations) {
    // Simple estimation - in real app, this would be more complex
    final currentCredits = registrations.length * 3;
    final remainingCredits = 120 - currentCredits; // Assuming 120 credits needed
    final semestersRemaining = (remainingCredits / 15).ceil(); // 15 credits per semester
    
    final estimatedDate = DateTime.now().add(Duration(days: semestersRemaining * 180));
    return '${estimatedDate.month}/${estimatedDate.year}';
  }

  Map<String, dynamic> _generateMockAttendance(String courseCode) {
    return {
      'totalClasses': 42,
      'attended': 38,
      'percentage': 90.5,
      'status': 'Good',
    };
  }

  Map<String, dynamic> _generateMockParticipation(String courseCode) {
    return {
      'participationScore': 85,
      'contributions': 12,
      'engagementLevel': 'High',
    };
  }

  String _generateMockRanking(double gpa) {
    if (gpa >= 3.8) return 'Top 5%';
    if (gpa >= 3.5) return 'Top 10%';
    if (gpa >= 3.0) return 'Top 25%';
    if (gpa >= 2.5) return 'Top 50%';
    return 'Average';
  }

  List<Map<String, dynamic>> _generateMockActivities() {
    return [
      {
        'activity': 'Student Government',
        'role': 'Member',
        'duration': '2023-2024',
        'achievements': 'Organized 3 campus events',
      },
      {
        'activity': 'Computer Science Club',
        'role': 'Treasurer',
        'duration': '2022-2024',
        'achievements': 'Managed club budget successfully',
      },
    ];
  }

  List<String> _generateMockFacultyFeedback(List<Map<String, dynamic>> courseDetails) {
    return [
      'Shows strong analytical skills in problem-solving',
      'Active participant in class discussions',
      'Demonstrates leadership potential in group projects',
      'Could improve time management skills',
    ];
  }

  List<String> _generateSemesterRecommendations(List<Grade> grades) {
    final recommendations = <String>[];
    
    final avgScore = grades.map((g) => g.totalScore).reduce((a, b) => a + b) / grades.length;
    
    if (avgScore < 70) {
      recommendations.add('Consider meeting with academic advisor for improvement strategies');
    }
    
    if (avgScore > 85) {
      recommendations.add('Excellent performance! Consider honors program opportunities');
    }
    
    recommendations.add('Continue regular attendance and participation');
    recommendations.add('Utilize office hours for additional support when needed');
    
    return recommendations;
  }

  List<String> _generateComprehensiveRecommendations(Map<String, dynamic> gradeOverview, Map<String, dynamic> performanceTrends) {
    final recommendations = <String>[];
    
    final cgpa = gradeOverview['averageScore'] ?? 0.0;
    final trend = performanceTrends['overallTrend'] ?? 'stable';
    
    if (trend == 'declining') {
      recommendations.add('Academic performance shows declining trend - seek academic support');
    }
    
    if (cgpa < 2.0) {
      recommendations.add('Consider reducing course load to focus on academic improvement');
    }
    
    if (cgpa > 3.5) {
      recommendations.add('Strong academic performance - consider research opportunities');
    }
    
    return recommendations;
  }

  List<Map<String, dynamic>> _generateAchievements(Map<String, dynamic> cgpaDetails) {
    final achievements = <Map<String, dynamic>>[];
    
    if ((cgpaDetails['currentCGPA'] ?? 0.0) >= 3.5) {
      achievements.add({
        'title': 'Dean\'s List',
        'description': 'Achieved GPA of 3.5 or higher',
        'date': DateTime.now().toIso8601String(),
      });
    }
    
    achievements.add({
      'title': 'Active Student',
      'description': 'Maintained good academic standing',
      'date': DateTime.now().toIso8601String(),
    });
    
    return achievements;
  }

  List<String> _generateAcademicGoals(Map<String, dynamic> gradeOverview) {
    final goals = <String>[];
    
    final currentCGPA = gradeOverview['averageScore'] ?? 0.0;
    
    if (currentCGPA < 3.0) {
      goals.add('Achieve GPA of 3.0 or higher');
    }
    
    if (currentCGPA < 3.5) {
      goals.add('Qualify for Dean\'s List');
    }
    
    goals.add('Complete all courses with passing grades');
    goals.add('Maintain regular attendance and participation');
    
    return goals;
  }

  String _convertToCSV(Map<String, dynamic> data) {
    // Simple CSV conversion - in real app, use proper CSV library
    final buffer = StringBuffer();
    
    // Headers
    buffer.writeln('Student ID,Export Date,Total Grades,CGPA,Total Credits');
    
    // Data
    buffer.writeln('${data['studentId']},${data['exportDate']},${data['academicSummary']['totalGrades']},${data['academicSummary']['cgpa']},${data['academicSummary']['totalCredits']}');
    
    return buffer.toString();
  }

  String _convertToXML(Map<String, dynamic> data) {
    // Simple XML conversion - in real app, use proper XML library
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<studentData>');
    buffer.writeln('  <studentId>${data['studentId']}</studentId>');
    buffer.writeln('  <exportDate>${data['exportDate']}</exportDate>');
    buffer.writeln('  <academicSummary>');
    buffer.writeln('    <totalGrades>${data['academicSummary']['totalGrades']}</totalGrades>');
    buffer.writeln('    <cgpa>${data['academicSummary']['cgpa']}</cgpa>');
    buffer.writeln('    <totalCredits>${data['academicSummary']['totalCredits']}</totalCredits>');
    buffer.writeln('  </academicSummary>');
    buffer.writeln('</studentData>');
    
    return buffer.toString();
  }
}
