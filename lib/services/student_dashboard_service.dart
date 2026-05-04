import '../services/grade_service.dart';
import '../services/course_service.dart';
import '../models/grade.dart';
import '../models/course.dart';

class StudentDashboardService {
  final GradeService _gradeService = GradeService();
  final CourseService _courseService = CourseService();

  // Grade Overview
  Future<Map<String, dynamic>> getGradeOverview(String studentId) async {
    try {
      final statistics = await _gradeService.getGradeStatistics(studentId);
      final grades = await _gradeService.getGradesForStudent(studentId);
      
      // Calculate additional metrics
      final totalGrades = grades.length;
      final passingGrades = grades.where((g) => g.isPassing).length;
      final excellentGrades = grades.where((g) => g.letterGrade.startsWith('A')).length;
      final failingGrades = grades.where((g) => !g.isPassing).length;
      
      // Get recent grades (last 5)
      final recentGrades = await _gradeService.getSortedGrades(
        studentId, 
        sortBy: 'total_score', 
        ascending: false
      );
      final topRecentGrades = recentGrades.take(5).toList();
      
      return {
        ...statistics,
        'totalGrades': totalGrades,
        'passingGrades': passingGrades,
        'excellentGrades': excellentGrades,
        'failingGrades': failingGrades,
        'passRate': totalGrades > 0 ? (passingGrades / totalGrades) * 100 : 0,
        'excellenceRate': totalGrades > 0 ? (excellentGrades / totalGrades) * 100 : 0,
        'recentGrades': topRecentGrades.map((g) => g.toMap()).toList(),
      };
    } catch (e) {
      print('Get grade overview error: $e');
      return {};
    }
  }

  // CGPA Display
  Future<Map<String, dynamic>> getCGPADetails(String studentId) async {
    try {
      final cgpa = await _gradeService.calculateCGPA(studentId);
      final registrations = await _courseService.getStudentRegistrations(studentId);
      
      // Calculate semester-wise GPA
      final semesterGPAs = <String, double>{};
      final semesters = await _gradeService.getSemesters(studentId);
      
      for (String semester in semesters) {
        final semesterGPA = await _gradeService.calculateGPA(studentId, semester);
        semesterGPAs[semester] = semesterGPA;
      }
      
      // Get grade distribution
      final gradeCounts = await _gradeService.getGradeCountByLetter(studentId);
      
      return {
        'currentCGPA': cgpa,
        'semesterGPAs': semesterGPAs,
        'totalCredits': registrations.length * 3, // Assuming 3 credits per course
        'gradeDistribution': gradeCounts,
        'academicStanding': _getAcademicStanding(cgpa),
        'honorStatus': _getHonorStatus(cgpa),
      };
    } catch (e) {
      print('Get CGPA details error: $e');
      return {};
    }
  }

  // Recent Grades
  Future<List<Map<String, dynamic>>> getRecentGrades(String studentId, {int limit = 10}) async {
    try {
      final grades = await _gradeService.getSortedGrades(
        studentId, 
        sortBy: 'total_score', 
        ascending: false
      );
      
      return grades.take(limit).map((grade) => {
        ...grade.toMap(),
        'performanceLevel': grade.getPerformanceLevel(),
        'gradeColor': grade.getGradeColor(),
        'isImproving': _isImprovingGrade(grade),
      }).toList();
    } catch (e) {
      print('Get recent grades error: $e');
      return [];
    }
  }

  // Upcoming Assignments
  Future<List<Map<String, dynamic>>> getUpcomingAssignments(String studentId) async {
    try {
      final registrations = await _courseService.getStudentRegistrations(studentId);
      final currentSemester = _getCurrentSemester();
      
      // Get courses for current semester
      final currentRegistrations = registrations
          .where((reg) => reg.semester == currentSemester && reg.isRegistered)
          .toList();
      
      final upcomingAssignments = <Map<String, dynamic>>[];
      
      for (var registration in currentRegistrations) {
        final course = await _courseService.getCourse(registration.courseCode);
        if (course != null) {
          // Simulate upcoming assignments (in real app, this would come from assignments collection)
          final assignments = _generateMockAssignments(course);
          upcomingAssignments.addAll(assignments);
        }
      }
      
      // Sort by due date
      upcomingAssignments.sort((a, b) => a['dueDate'].compareTo(b['dueDate']));
      
      return upcomingAssignments.take(10).toList();
    } catch (e) {
      print('Get upcoming assignments error: $e');
      return [];
    }
  }

  // Academic Performance Trends
  Future<Map<String, dynamic>> getPerformanceTrends(String studentId) async {
    try {
      final grades = await _gradeService.getGradesForStudent(studentId);
      final semesters = await _gradeService.getSemesters(studentId);
      
      final semesterPerformance = <String, Map<String, dynamic>>{};
      
      for (String semester in semesters) {
        final semesterGrades = grades.where((g) => g.semester == semester).toList();
        if (semesterGrades.isNotEmpty) {
          final avgScore = semesterGrades
              .map((g) => g.totalScore)
              .reduce((a, b) => a + b) / semesterGrades.length;
          final gpa = await _gradeService.calculateGPA(studentId, semester);
          
          semesterPerformance[semester] = {
            'averageScore': avgScore,
            'gpa': gpa,
            'gradeCount': semesterGrades.length,
            'trend': _calculateTrend(semesterGrades),
          };
        }
      }
      
      return {
        'semesterPerformance': semesterPerformance,
        'overallTrend': _calculateOverallTrend(grades),
        'improvementAreas': _getImprovementAreas(grades),
        'strengthAreas': _getStrengthAreas(grades),
      };
    } catch (e) {
      print('Get performance trends error: $e');
      return {};
    }
  }

  // Course Schedule Overview
  Future<Map<String, dynamic>> getScheduleOverview(String studentId) async {
    try {
      final currentSemester = _getCurrentSemester();
      final schedule = await _courseService.getStudentSchedule(studentId, currentSemester);
      final registrations = await _courseService.getStudentRegistrations(studentId, semester: currentSemester);
      
      final todaySchedule = _getTodaySchedule(schedule);
      final weeklyOverview = _getWeeklyOverview(schedule);
      
      return {
        'todaySchedule': todaySchedule,
        'weeklySchedule': schedule,
        'weeklyOverview': weeklyOverview,
        'totalCourses': registrations.length,
        'totalCredits': registrations.length * 3,
        'scheduleDensity': _calculateScheduleDensity(schedule),
      };
    } catch (e) {
      print('Get schedule overview error: $e');
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

  bool _isImprovingGrade(Grade grade) {
    // Simple logic - in real app, compare with previous performance
    return grade.totalScore >= 75;
  }

  String _getCurrentSemester() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    
    if (month >= 1 && month <= 5) {
      return 'Spring $year';
    } else if (month >= 6 && month <= 8) {
      return 'Summer $year';
    } else if (month >= 9 && month <= 12) {
      return 'Fall $year';
    }
    return 'Winter $year';
  }

  List<Map<String, dynamic>> _generateMockAssignments(Course course) {
    final now = DateTime.now();
    return [
      {
        'id': '${course.courseCode}_midterm',
        'title': '${course.courseTitle} Midterm Exam',
        'courseCode': course.courseCode,
        'courseTitle': course.courseTitle,
        'type': 'Exam',
        'dueDate': now.add(const Duration(days: 7)).toIso8601String(),
        'weight': 30,
        'status': 'upcoming',
      },
      {
        'id': '${course.courseCode}_final',
        'title': '${course.courseTitle} Final Exam',
        'courseCode': course.courseCode,
        'courseTitle': course.courseTitle,
        'type': 'Exam',
        'dueDate': now.add(const Duration(days: 30)).toIso8601String(),
        'weight': 40,
        'status': 'upcoming',
      },
      {
        'id': '${course.courseCode}_assignment1',
        'title': '${course.courseTitle} Assignment 1',
        'courseCode': course.courseCode,
        'courseTitle': course.courseTitle,
        'type': 'Assignment',
        'dueDate': now.add(const Duration(days: 3)).toIso8601String(),
        'weight': 15,
        'status': 'upcoming',
      },
    ];
  }

  String _calculateTrend(List<Grade> grades) {
    if (grades.length < 2) return 'insufficient_data';
    
    final sortedGrades = List<Grade>.from(grades);
    sortedGrades.sort((a, b) => a.courseCode.compareTo(b.courseCode));
    
    int improving = 0;
    int declining = 0;
    
    for (int i = 1; i < sortedGrades.length; i++) {
      if (sortedGrades[i].totalScore > sortedGrades[i-1].totalScore) {
        improving++;
      } else if (sortedGrades[i].totalScore < sortedGrades[i-1].totalScore) {
        declining++;
      }
    }
    
    if (improving > declining) return 'improving';
    if (declining > improving) return 'declining';
    return 'stable';
  }

  String _calculateOverallTrend(List<Grade> grades) {
    if (grades.length < 2) return 'insufficient_data';
    
    grades.sort((a, b) => a.semester.compareTo(b.semester));
    
    final firstSemesterGrades = grades.where((g) => g.semester == grades.first.semester).toList();
    final lastSemesterGrades = grades.where((g) => g.semester == grades.last.semester).toList();
    
    if (firstSemesterGrades.isEmpty || lastSemesterGrades.isEmpty) {
      return 'insufficient_data';
    }
    
    final firstAvg = firstSemesterGrades.map((g) => g.totalScore).reduce((a, b) => a + b) / firstSemesterGrades.length;
    final lastAvg = lastSemesterGrades.map((g) => g.totalScore).reduce((a, b) => a + b) / lastSemesterGrades.length;
    
    if (lastAvg > firstAvg + 5) return 'improving';
    if (lastAvg < firstAvg - 5) return 'declining';
    return 'stable';
  }

  List<String> _getImprovementAreas(List<Grade> grades) {
    final failingGrades = grades.where((g) => !g.isPassing).toList();
    return failingGrades.map((g) => g.courseCode).toSet().toList();
  }

  List<String> _getStrengthAreas(List<Grade> grades) {
    final excellentGrades = grades.where((g) => g.letterGrade.startsWith('A')).toList();
    return excellentGrades.map((g) => g.courseCode).toSet().toList();
  }

  List<Map<String, dynamic>> _getTodaySchedule(Map<String, List<Course>> schedule) {
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);
    
    if (schedule.containsKey(dayName)) {
      return schedule[dayName]!.map((course) => {
        'courseCode': course.courseCode,
        'courseTitle': course.courseTitle,
        'startTime': course.schedule.startTime,
        'endTime': course.schedule.endTime,
        'room': course.room,
        'building': course.building,
        'instructor': course.instructor,
      }).toList();
    }
    return [];
  }

  Map<String, int> _getWeeklyOverview(Map<String, List<Course>> schedule) {
    final overview = <String, int>{};
    schedule.forEach((day, courses) {
      overview[day] = courses.length;
    });
    return overview;
  }

  double _calculateScheduleDensity(Map<String, List<Course>> schedule) {
    int totalHours = 0;
    schedule.forEach((day, courses) {
      for (var course in courses) {
        final start = DateTime.parse('2023-01-01 ${course.schedule.startTime}:00');
        final end = DateTime.parse('2023-01-01 ${course.schedule.endTime}:00');
        totalHours += end.difference(start).inHours;
      }
    });
    
    return totalHours / 5.0; // Average per weekday
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }
}
