class CourseRegistration {
  final String id;
  final String studentId;
  final String courseCode;
  final String semester;
  final DateTime registrationDate;
  final String status; // 'registered', 'dropped', 'completed', 'failed'
  final double? finalGrade;
  final String? gradeLetter;
  final int creditHoursEarned;
  final bool isActive;

  CourseRegistration({
    required this.id,
    required this.studentId,
    required this.courseCode,
    required this.semester,
    required this.registrationDate,
    this.status = 'registered',
    this.finalGrade,
    this.gradeLetter,
    this.creditHoursEarned = 0,
    this.isActive = true,
  });

  factory CourseRegistration.fromMap(Map<String, dynamic> map) {
    return CourseRegistration(
      id: map['id'] ?? '',
      studentId: map['student_id'] ?? '',
      courseCode: map['course_code'] ?? '',
      semester: map['semester'] ?? '',
      registrationDate: map['registration_date'] != null 
          ? DateTime.parse(map['registration_date'])
          : DateTime.now(),
      status: map['status'] ?? 'registered',
      finalGrade: map['final_grade']?.toDouble(),
      gradeLetter: map['grade_letter'],
      creditHoursEarned: map['credit_hours_earned'] ?? 0,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'course_code': courseCode,
      'semester': semester,
      'registration_date': registrationDate.toIso8601String(),
      'status': status,
      'final_grade': finalGrade,
      'grade_letter': gradeLetter,
      'credit_hours_earned': creditHoursEarned,
      'is_active': isActive,
    };
  }

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isDropped => status == 'dropped';
  bool get isFailed => status == 'failed';
  bool get isRegistered => status == 'registered';
  bool get hasGrade => finalGrade != null;

  CourseRegistration copyWith({
    String? id,
    String? studentId,
    String? courseCode,
    String? semester,
    DateTime? registrationDate,
    String? status,
    double? finalGrade,
    String? gradeLetter,
    int? creditHoursEarned,
    bool? isActive,
  }) {
    return CourseRegistration(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseCode: courseCode ?? this.courseCode,
      semester: semester ?? this.semester,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      finalGrade: finalGrade ?? this.finalGrade,
      gradeLetter: gradeLetter ?? this.gradeLetter,
      creditHoursEarned: creditHoursEarned ?? this.creditHoursEarned,
      isActive: isActive ?? this.isActive,
    );
  }

  // Factory method for creating new registration
  factory CourseRegistration.create({
    required String studentId,
    required String courseCode,
    required String semester,
  }) {
    return CourseRegistration(
      id: '${studentId}_${courseCode}_$semester',
      studentId: studentId,
      courseCode: courseCode,
      semester: semester,
      registrationDate: DateTime.now(),
      status: 'registered',
    );
  }
}
