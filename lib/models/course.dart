class Course {
  final String courseCode;
  final String courseTitle;
  final int creditHours;
  final String instructor;
  final String semester;
  final String department;
  final String description;
  final int maxCapacity;
  final int currentEnrolled;
  final List<String> prerequisites;
  final CourseSchedule schedule;
  final bool isActive;
  final String? room;
  final String? building;

  Course({
    required this.courseCode,
    required this.courseTitle,
    required this.creditHours,
    required this.instructor,
    required this.semester,
    this.department = '',
    this.description = '',
    this.maxCapacity = 50,
    this.currentEnrolled = 0,
    this.prerequisites = const [],
    required this.schedule,
    this.isActive = true,
    this.room,
    this.building,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      courseCode: map['course_code'] ?? '',
      courseTitle: map['course_title'] ?? '',
      creditHours: map['credit_hours'] ?? 0,
      instructor: map['instructor'] ?? '',
      semester: map['semester'] ?? '',
      department: map['department'] ?? '',
      description: map['description'] ?? '',
      maxCapacity: map['max_capacity'] ?? 50,
      currentEnrolled: map['current_enrolled'] ?? 0,
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      schedule: CourseSchedule.fromMap(map['schedule'] ?? {}),
      isActive: map['is_active'] ?? true,
      room: map['room'],
      building: map['building'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'course_code': courseCode,
      'course_title': courseTitle,
      'credit_hours': creditHours,
      'instructor': instructor,
      'semester': semester,
      'department': department,
      'description': description,
      'max_capacity': maxCapacity,
      'current_enrolled': currentEnrolled,
      'prerequisites': prerequisites,
      'schedule': schedule.toMap(),
      'is_active': isActive,
      'room': room,
      'building': building,
    };
  }

  // Helper methods
  bool get isFull => currentEnrolled >= maxCapacity;
  bool get hasAvailability => currentEnrolled < maxCapacity;
  double get enrollmentPercentage => maxCapacity > 0 ? (currentEnrolled / maxCapacity) * 100 : 0;
  String get availabilityStatus => isFull ? 'Full' : '$maxCapacity - $currentEnrolled seats available';
  
  Course copyWith({
    String? courseCode,
    String? courseTitle,
    int? creditHours,
    String? instructor,
    String? semester,
    String? department,
    String? description,
    int? maxCapacity,
    int? currentEnrolled,
    List<String>? prerequisites,
    CourseSchedule? schedule,
    bool? isActive,
    String? room,
    String? building,
  }) {
    return Course(
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      creditHours: creditHours ?? this.creditHours,
      instructor: instructor ?? this.instructor,
      semester: semester ?? this.semester,
      department: department ?? this.department,
      description: description ?? this.description,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentEnrolled: currentEnrolled ?? this.currentEnrolled,
      prerequisites: prerequisites ?? this.prerequisites,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
      room: room ?? this.room,
      building: building ?? this.building,
    );
  }
}

class CourseSchedule {
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String scheduleType; // 'lecture', 'lab', 'tutorial'

  CourseSchedule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.scheduleType = 'lecture',
  });

  factory CourseSchedule.fromMap(Map<String, dynamic> map) {
    return CourseSchedule(
      dayOfWeek: map['day_of_week'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      scheduleType: map['schedule_type'] ?? 'lecture',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'schedule_type': scheduleType,
    };
  }

  String get formattedTime => '$startTime - $endTime';
  String get formattedSchedule => '$dayOfWeek: $formattedTime';
}
