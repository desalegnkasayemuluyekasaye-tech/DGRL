import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String studentId;
  final String fullName;
  final String department;
  final String batch;
  final String email;
  final String password;
  final String? sex;
  final String? phone;
  final int? age;
  final String? photoUrl;
  final String? uid;

  Student({
    required this.studentId,
    required this.fullName,
    required this.department,
    required this.batch,
    required this.email,
    required this.password,
    this.sex,
    this.phone,
    this.age,
    this.photoUrl,
    this.uid,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      studentId: map['student_id'] ?? '',
      fullName: map['full_name'] ?? '',
      department: map['department'] ?? '',
      batch: map['batch'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      sex: map['sex'],
      phone: map['phone'],
      age: map['age'] != null ? int.tryParse(map['age'].toString()) : null,
      photoUrl: map['photo_url'],
      uid: map['uid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'full_name': fullName,
      'department': department,
      'batch': batch,
      'email': email,
      'password': password,
      'sex': sex,
      'phone': phone,
      'age': age,
      'photo_url': photoUrl,
      'uid': uid,
    };
  }

  Student copyWith({
    String? studentId,
    String? fullName,
    String? department,
    String? batch,
    String? email,
    String? password,
    String? sex,
    String? phone,
    int? age,
    String? photoUrl,
    String? uid,
  }) {
    return Student(
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      department: department ?? this.department,
      batch: batch ?? this.batch,
      email: email ?? this.email,
      password: password ?? this.password,
      sex: sex ?? this.sex,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      uid: uid ?? this.uid,
    );
  }

  // Factory method for creating Student from Firestore DocumentSnapshot
  factory Student.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student.fromMap(data);
  }

  // Factory method for creating Student from QueryDocumentSnapshot
  factory Student.fromQueryDocument(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student.fromMap(data);
  }

  // Convert to Map without timestamps (for updates)
  Map<String, dynamic> toUpdateMap() {
    return {
      'full_name': fullName,
      'department': department,
      'batch': batch,
      'email': email,
      'sex': sex,
      'phone': phone,
      'age': age,
      'photo_url': photoUrl,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // Convert to Map without sensitive data (for public display)
  Map<String, dynamic> toPublicMap() {
    return {
      'student_id': studentId,
      'full_name': fullName,
      'department': department,
      'batch': batch,
      'email': email,
      'sex': sex,
      'phone': phone,
      'age': age,
      'photo_url': photoUrl,
    };
  }
}
