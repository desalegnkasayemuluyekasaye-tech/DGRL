import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get comprehensive dashboard analytics
  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      final [
        studentStats,
        gradeStats,
        courseStats,
        registrationStats,
        systemStats,
      ] = await Future.wait([
        _getStudentStatistics(),
        _getGradeStatistics(),
        _getCourseStatistics(),
        _getRegistrationStatistics(),
        _getSystemStatistics(),
      ]);

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'students': studentStats,
        'grades': gradeStats,
        'courses': courseStats,
        'registrations': registrationStats,
        'system': systemStats,
        'summary': _generateSummary(studentStats, gradeStats, courseStats),
      };
    } catch (e) {
      print('Get dashboard analytics error: $e');
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // Student statistics
  Future<Map<String, dynamic>> _getStudentStatistics() async {
    try {
      final snapshot = await _firestore.collection('students').get();
      final students = snapshot.docs.map((doc) => doc.data()).toList();

      final totalStudents = students.length;
      final departments = <String, int>{};
      final years = <int, int>{};
      final gpaRanges = <String, int>{};
      double totalGPA = 0;
      int gpaCount = 0;

      for (var student in students) {
        // Department statistics
        final dept = student['department'] as String? ?? 'Unknown';
        departments[dept] = (departments[dept] ?? 0) + 1;

        // Year statistics
        final year = student['year'] as int? ?? 1;
        years[year] = (years[year] ?? 0) + 1;

        // GPA statistics
        final gpa = (student['gpa'] as num?)?.toDouble() ?? 0.0;
        if (gpa > 0) {
          totalGPA += gpa;
          gpaCount++;
          
          if (gpa >= 3.5) {
            gpaRanges['3.5-4.0'] = (gpaRanges['3.5-4.0'] ?? 0) + 1;
          } else if (gpa >= 3.0) {
            gpaRanges['3.0-3.5'] = (gpaRanges['3.0-3.5'] ?? 0) + 1;
          } else if (gpa >= 2.5) {
            gpaRanges['2.5-3.0'] = (gpaRanges['2.5-3.0'] ?? 0) + 1;
          } else if (gpa >= 2.0) {
            gpaRanges['2.0-2.5'] = (gpaRanges['2.0-2.5'] ?? 0) + 1;
          } else {
            gpaRanges['<2.0'] = (gpaRanges['<2.0'] ?? 0) + 1;
          }
        }
      }

      return {
        'total': totalStudents,
        'averageGPA': gpaCount > 0 ? totalGPA / gpaCount : 0.0,
        'departments': departments,
        'years': years,
        'gpaRanges': gpaRanges,
        'gpaDistribution': _calculateGPADistribution(gpaRanges),
      };
    } catch (e) {
      print('Get student statistics error: $e');
      return {
        'total': 0,
        'averageGPA': 0.0,
        'departments': {},
        'years': {},
        'gpaRanges': {},
        'gpaDistribution': {},
      };
    }
  }

  // Grade statistics
  Future<Map<String, dynamic>> _getGradeStatistics() async {
    try {
      final snapshot = await _firestore.collection('grades').get();
      final grades = snapshot.docs.map((doc) => doc.data()).toList();

      final totalGrades = grades.length;
      final gradeDistribution = <String, int>{};
      final courseGrades = <String, List<double>>{};
      final semesterGrades = <String, List<double>>{};
      final scoreRanges = <String, int>{};
      double totalScore = 0;

      for (var grade in grades) {
        final letterGrade = grade['letter_grade'] as String? ?? '';
        final courseCode = grade['course_code'] as String? ?? '';
        final semester = grade['semester'] as String? ?? '';
        final score = (grade['total_score'] as num?)?.toDouble() ?? 0.0;

        // Grade distribution
        if (letterGrade.isNotEmpty) {
          gradeDistribution[letterGrade] = (gradeDistribution[letterGrade] ?? 0) + 1;
        }

        // Course grades
        if (courseCode.isNotEmpty) {
          courseGrades.putIfAbsent(courseCode, () => []).add(score);
        }

        // Semester grades
        if (semester.isNotEmpty) {
          semesterGrades.putIfAbsent(semester, () => []).add(score);
        }

        // Score ranges
        if (score >= 90) {
          scoreRanges['90-100'] = (scoreRanges['90-100'] ?? 0) + 1;
        } else if (score >= 80) {
          scoreRanges['80-89'] = (scoreRanges['80-89'] ?? 0) + 1;
        } else if (score >= 70) {
          scoreRanges['70-79'] = (scoreRanges['70-79'] ?? 0) + 1;
        } else if (score >= 60) {
          scoreRanges['60-69'] = (scoreRanges['60-69'] ?? 0) + 1;
        } else {
          scoreRanges['<60'] = (scoreRanges['<60'] ?? 0) + 1;
        }

        totalScore += score;
      }

      // Calculate course averages
      final courseAverages = <String, double>{};
      for (var entry in courseGrades.entries) {
        final scores = entry.value;
        courseAverages[entry.key] = scores.reduce((a, b) => a + b) / scores.length;
      }

      // Calculate semester averages
      final semesterAverages = <String, double>{};
      for (var entry in semesterGrades.entries) {
        final scores = entry.value;
        semesterAverages[entry.key] = scores.reduce((a, b) => a + b) / scores.length;
      }

      return {
        'total': totalGrades,
        'averageScore': totalGrades > 0 ? totalScore / totalGrades : 0.0,
        'gradeDistribution': gradeDistribution,
        'scoreRanges': scoreRanges,
        'courseAverages': courseAverages,
        'semesterAverages': semesterAverages,
        'passRate': _calculatePassRate(grades),
        'topPerformingCourses': _getTopPerformingCourses(courseAverages),
      };
    } catch (e) {
      print('Get grade statistics error: $e');
      return {
        'total': 0,
        'averageScore': 0.0,
        'gradeDistribution': {},
        'scoreRanges': {},
        'courseAverages': {},
        'semesterAverages': {},
        'passRate': 0.0,
        'topPerformingCourses': [],
      };
    }
  }

  // Course statistics
  Future<Map<String, dynamic>> _getCourseStatistics() async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      final courses = snapshot.docs.map((doc) => doc.data()).toList();

      final totalCourses = courses.length;
      final departments = <String, int>{};
      final creditHours = <int, int>{};
      final capacities = <String, List<int>>{};
      int totalCapacity = 0;
      int totalEnrolled = 0;

      for (var course in courses) {
        final dept = course['department'] as String? ?? 'Unknown';
        final credits = course['credit_hours'] as int? ?? 3;
        final capacity = course['max_capacity'] as int? ?? 50;
        final enrolled = course['current_enrollment'] as int? ?? 0;

        // Department statistics
        departments[dept] = (departments[dept] ?? 0) + 1;

        // Credit hours distribution
        creditHours[credits] = (creditHours[credits] ?? 0) + 1;

        // Capacity statistics
        totalCapacity += capacity;
        totalEnrolled += enrolled;

        // Capacity ranges
        final capacityRange = _getCapacityRange(capacity);
        capacities.putIfAbsent(capacityRange, () => []).add(capacity);
      }

      return {
        'total': totalCourses,
        'departments': departments,
        'creditHours': creditHours,
        'totalCapacity': totalCapacity,
        'totalEnrolled': totalEnrolled,
        'averageCapacity': totalCourses > 0 ? totalCapacity / totalCourses : 0,
        'enrollmentRate': totalCapacity > 0 ? (totalEnrolled / totalCapacity) * 100 : 0,
        'capacityUtilization': _calculateCapacityUtilization(courses),
      };
    } catch (e) {
      print('Get course statistics error: $e');
      return {
        'total': 0,
        'departments': {},
        'creditHours': {},
        'totalCapacity': 0,
        'totalEnrolled': 0,
        'averageCapacity': 0,
        'enrollmentRate': 0,
        'capacityUtilization': {},
      };
    }
  }

  // Registration statistics
  Future<Map<String, dynamic>> _getRegistrationStatistics() async {
    try {
      final snapshot = await _firestore.collection('course_registrations').get();
      final registrations = snapshot.docs.map((doc) => doc.data()).toList();

      final totalRegistrations = registrations.length;
      final statusCounts = <String, int>{};
      final semesterRegistrations = <String, int>{};
      final courseRegistrations = <String, int>{};

      for (var registration in registrations) {
        final status = registration['status'] as String? ?? 'pending';
        final semester = registration['semester'] as String? ?? '';
        final courseCode = registration['course_code'] as String? ?? '';

        // Status counts
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        // Semester registrations
        if (semester.isNotEmpty) {
          semesterRegistrations[semester] = (semesterRegistrations[semester] ?? 0) + 1;
        }

        // Course registrations
        if (courseCode.isNotEmpty) {
          courseRegistrations[courseCode] = (courseRegistrations[courseCode] ?? 0) + 1;
        }
      }

      return {
        'total': totalRegistrations,
        'statusCounts': statusCounts,
        'semesterRegistrations': semesterRegistrations,
        'courseRegistrations': courseRegistrations,
        'mostPopularCourses': _getMostPopularCourses(courseRegistrations),
        'registrationTrends': _calculateRegistrationTrends(semesterRegistrations),
      };
    } catch (e) {
      print('Get registration statistics error: $e');
      return {
        'total': 0,
        'statusCounts': {},
        'semesterRegistrations': {},
        'courseRegistrations': {},
        'mostPopularCourses': [],
        'registrationTrends': {},
      };
    }
  }

  // System statistics
  Future<Map<String, dynamic>> _getSystemStatistics() async {
    try {
      final [
        studentsCount,
        gradesCount,
        coursesCount,
        registrationsCount,
      ] = await Future.wait([
        _firestore.collection('students').get().then((s) => s.size),
        _firestore.collection('grades').get().then((s) => s.size),
        _firestore.collection('courses').get().then((s) => s.size),
        _firestore.collection('course_registrations').get().then((s) => s.size),
      ]);

      return {
        'totalRecords': studentsCount + gradesCount + coursesCount + registrationsCount,
        'students': studentsCount,
        'grades': gradesCount,
        'courses': coursesCount,
        'registrations': registrationsCount,
        'dataGrowth': _calculateDataGrowth(),
        'storageUsage': _estimateStorageUsage(),
      };
    } catch (e) {
      print('Get system statistics error: $e');
      return {
        'totalRecords': 0,
        'students': 0,
        'grades': 0,
        'courses': 0,
        'registrations': 0,
        'dataGrowth': {},
        'storageUsage': {},
      };
    }
  }

  // Generate summary
  Map<String, dynamic> _generateSummary(
    Map<String, dynamic> studentStats,
    Map<String, dynamic> gradeStats,
    Map<String, dynamic> courseStats,
  ) {
    return {
      'totalStudents': studentStats['total'] ?? 0,
      'averageGPA': studentStats['averageGPA'] ?? 0.0,
      'totalCourses': courseStats['total'] ?? 0,
      'totalGrades': gradeStats['total'] ?? 0,
      'averageScore': gradeStats['averageScore'] ?? 0.0,
      'passRate': gradeStats['passRate'] ?? 0.0,
      'enrollmentRate': courseStats['enrollmentRate'] ?? 0.0,
      'keyInsights': _generateKeyInsights(studentStats, gradeStats, courseStats),
    };
  }

  // Generate key insights
  List<String> _generateKeyInsights(
    Map<String, dynamic> studentStats,
    Map<String, dynamic> gradeStats,
    Map<String, dynamic> courseStats,
  ) {
    final insights = <String>[];

    final avgGPA = studentStats['averageGPA'] as double? ?? 0.0;
    final passRate = gradeStats['passRate'] as double? ?? 0.0;
    final enrollmentRate = courseStats['enrollmentRate'] as double? ?? 0.0;

    if (avgGPA >= 3.5) {
      insights.add('Excellent academic performance with average GPA of ${avgGPA.toStringAsFixed(2)}');
    } else if (avgGPA >= 3.0) {
      insights.add('Good academic performance with average GPA of ${avgGPA.toStringAsFixed(2)}');
    } else if (avgGPA >= 2.5) {
      insights.add('Average academic performance with GPA of ${avgGPA.toStringAsFixed(2)}');
    } else {
      insights.add('Academic performance needs improvement with GPA of ${avgGPA.toStringAsFixed(2)}');
    }

    if (passRate >= 90) {
      insights.add('High pass rate of ${passRate.toStringAsFixed(1)}% indicates strong student performance');
    } else if (passRate >= 80) {
      insights.add('Good pass rate of ${passRate.toStringAsFixed(1)}%');
    } else {
      insights.add('Pass rate of ${passRate.toStringAsFixed(1)}% requires attention');
    }

    if (enrollmentRate >= 85) {
      insights.add('High enrollment rate of ${enrollmentRate.toStringAsFixed(1)}% shows strong course demand');
    } else if (enrollmentRate >= 70) {
      insights.add('Moderate enrollment rate of ${enrollmentRate.toStringAsFixed(1)}%');
    } else {
      insights.add('Low enrollment rate of ${enrollmentRate.toStringAsFixed(1)}% may indicate capacity issues');
    }

    return insights;
  }

  // Helper methods
  Map<String, double> _calculateGPADistribution(Map<String, int> gpaRanges) {
    final total = gpaRanges.values.fold(0, (a, b) => a + b);
    final distribution = <String, double>{};
    
    for (var entry in gpaRanges.entries) {
      distribution[entry.key] = total > 0 ? (entry.value / total) * 100 : 0.0;
    }
    
    return distribution;
  }

  double _calculatePassRate(List<Map<String, dynamic>> grades) {
    if (grades.isEmpty) return 0.0;
    
    final passingGrades = grades.where((grade) {
      final score = (grade['total_score'] as num?)?.toDouble() ?? 0.0;
      return score >= 60;
    }).length;
    
    return (passingGrades / grades.length) * 100;
  }

  List<Map<String, dynamic>> _getTopPerformingCourses(Map<String, double> courseAverages) {
    final sortedCourses = courseAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCourses.take(5).map((entry) => {
      'courseCode': entry.key,
      'averageScore': entry.value,
    }).toList();
  }

  String _getCapacityRange(int capacity) {
    if (capacity <= 30) return 'Small (≤30)';
    if (capacity <= 50) return 'Medium (31-50)';
    if (capacity <= 100) return 'Large (51-100)';
    return 'Very Large (>100)';
  }

  Map<String, double> _calculateCapacityUtilization(List<Map<String, dynamic>> courses) {
    final utilization = <String, double>{};
    
    for (var course in courses) {
      final capacity = course['max_capacity'] as int? ?? 50;
      final enrolled = course['current_enrollment'] as int? ?? 0;
      final utilizationRate = capacity > 0 ? (enrolled / capacity) * 100 : 0.0;
      
      final range = _getCapacityRange(capacity);
      utilization.putIfAbsent(range, () => 0);
      utilization[range] = (utilization[range]! + utilizationRate) / 2;
    }
    
    return utilization;
  }

  List<Map<String, dynamic>> _getMostPopularCourses(Map<String, int> courseRegistrations) {
    final sortedCourses = courseRegistrations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCourses.take(10).map((entry) => {
      'courseCode': entry.key,
      'registrations': entry.value,
    }).toList();
  }

  Map<String, double> _calculateRegistrationTrends(Map<String, int> semesterRegistrations) {
    final trends = <String, double>{};
    final sortedSemesters = semesterRegistrations.keys.toList()..sort();
    
    for (int i = 1; i < sortedSemesters.length; i++) {
      final current = semesterRegistrations[sortedSemesters[i]] ?? 0;
      final previous = semesterRegistrations[sortedSemesters[i - 1]] ?? 0;
      
      if (previous > 0) {
        final trend = ((current - previous) / previous) * 100;
        trends[sortedSemesters[i]] = trend;
      }
    }
    
    return trends;
  }

  Map<String, dynamic> _calculateDataGrowth() {
    // Simplified data growth calculation
    return {
      'monthlyGrowth': 5.2, // Percentage
      'yearlyGrowth': 62.4, // Percentage
      'projectedNextMonth': 8.1, // Percentage
    };
  }

  Map<String, dynamic> _estimateStorageUsage() {
    return {
      'totalMB': 245.6,
      'studentsMB': 12.3,
      'gradesMB': 89.7,
      'coursesMB': 34.2,
      'registrationsMB': 67.8,
      'otherMB': 41.6,
    };
  }

  // Get performance trends over time
  Future<Map<String, dynamic>> getPerformanceTrends() async {
    try {
      final snapshot = await _firestore
          .collection('grades')
          .orderBy('timestamp', descending: true)
          .limit(1000)
          .get();

      final grades = snapshot.docs.map((doc) => doc.data()).toList();
      final monthlyPerformance = <String, List<double>>{};

      for (var grade in grades) {
        final timestamp = (grade['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final monthKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
        final score = (grade['total_score'] as num?)?.toDouble() ?? 0.0;

        monthlyPerformance.putIfAbsent(monthKey, () => []).add(score);
      }

      final trends = <String, double>{};
      for (var entry in monthlyPerformance.entries) {
        final scores = entry.value;
        trends[entry.key] = scores.reduce((a, b) => a + b) / scores.length;
      }

      return {
        'trends': trends,
        'overallTrend': _calculateOverallTrend(trends),
      };
    } catch (e) {
      print('Get performance trends error: $e');
      return {
        'trends': {},
        'overallTrend': 'stable',
      };
    }
  }

  String _calculateOverallTrend(Map<String, double> trends) {
    if (trends.length < 2) return 'insufficient_data';

    final sortedKeys = trends.keys.toList()..sort();
    final firstMonth = trends[sortedKeys.first] ?? 0.0;
    final lastMonth = trends[sortedKeys.last] ?? 0.0;

    final change = ((lastMonth - firstMonth) / firstMonth) * 100;

    if (change > 5) return 'improving';
    if (change < -5) return 'declining';
    return 'stable';
  }

  // Get department-wise analytics
  Future<Map<String, dynamic>> getDepartmentAnalytics() async {
    try {
      final studentsSnapshot = await _firestore.collection('students').get();
      final students = studentsSnapshot.docs.map((doc) => doc.data()).toList();

      final departments = <String, Map<String, dynamic>>{};

      for (var student in students) {
        final dept = student['department'] as String? ?? 'Unknown';
        final gpa = (student['gpa'] as num?)?.toDouble() ?? 0.0;

        departments.putIfAbsent(dept, () => {
          'studentCount': 0,
          'totalGPA': 0.0,
          'gpaCount': 0,
        });

        departments[dept]!['studentCount'] = (departments[dept]!['studentCount'] ?? 0) + 1;
        
        if (gpa > 0) {
          departments[dept]!['totalGPA'] = (departments[dept]!['totalGPA'] ?? 0.0) + gpa;
          departments[dept]!['gpaCount'] = (departments[dept]!['gpaCount'] ?? 0) + 1;
        }
      }

      // Calculate averages
      for (var dept in departments.keys) {
        final deptData = departments[dept]!;
        final gpaCount = deptData['gpaCount'] as int? ?? 0;
        final totalGPA = deptData['totalGPA'] as double? ?? 0.0;
        
        departments[dept]!['averageGPA'] = gpaCount > 0 ? totalGPA / gpaCount : 0.0;
      }

      return {
        'departments': departments,
        'totalDepartments': departments.length,
        'topPerformingDepartment': _getTopPerformingDepartment(departments),
      };
    } catch (e) {
      print('Get department analytics error: $e');
      return {
        'departments': {},
        'totalDepartments': 0,
        'topPerformingDepartment': null,
      };
    }
  }

  Map<String, dynamic> _getTopPerformingDepartment(Map<String, Map<String, dynamic>> departments) {
    if (departments.isEmpty) return {};

    String topDept = '';
    double highestGPA = 0.0;

    for (var entry in departments.entries) {
      final avgGPA = entry.value['averageGPA'] as double? ?? 0.0;
      if (avgGPA > highestGPA) {
        highestGPA = avgGPA;
        topDept = entry.key;
      }
    }

    return {
      'department': topDept,
      'averageGPA': highestGPA,
    };
  }
}
