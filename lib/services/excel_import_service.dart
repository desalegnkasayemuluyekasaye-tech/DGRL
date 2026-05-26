import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/grade.dart';

// ─── Staging row models (editable before submit) ───────────────

class StagedStudentRow {
  String studentId;
  String fullName;
  String department;
  String batch;
  String phone;
  String ageStr;
  String sex;

  StagedStudentRow({
    required this.studentId,
    required this.fullName,
    required this.department,
    this.batch = '2024',
    this.phone = '',
    this.ageStr = '',
    this.sex = '',
  });

  String get email => '$studentId@bdu.edu.et';
  String get password => studentId;
  int? get age => int.tryParse(ageStr);
}

class StagedCourseRow {
  String courseCode;
  String courseTitle;
  String creditHoursStr;
  String instructor;
  String semester;
  String department;

  StagedCourseRow({
    required this.courseCode,
    required this.courseTitle,
    this.creditHoursStr = '3',
    required this.instructor,
    required this.semester,
    this.department = '',
  });

  int get creditHours => int.tryParse(creditHoursStr) ?? 3;
}

class StagedGradeRow {
  String studentId;
  String courseCode;
  String midStr;
  String assignmentStr;
  String finalStr;
  String semester;

  StagedGradeRow({
    required this.studentId,
    required this.courseCode,
    this.midStr = '0',
    this.assignmentStr = '0',
    this.finalStr = '0',
    required this.semester,
  });

  double get midScore => double.tryParse(midStr) ?? 0;
  double get assignmentScore => double.tryParse(assignmentStr) ?? 0;
  double get finalScore => double.tryParse(finalStr) ?? 0;
}

// ─── Validation error returned during parse ────────────────────

class StagingError {
  final int row;
  final String message;

  StagingError(this.row, this.message);
}

// ─── Parse result with data + errors ──────────────────────────

class ParseResult<T> {
  final List<T> rows;
  final List<StagingError> errors;
  final int totalRows;

  ParseResult({
    required this.rows,
    required this.errors,
    required this.totalRows,
  });

  bool get hasErrors => errors.isNotEmpty;
}

// ─── Submit result ─────────────────────────────────────────────

class SubmitResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;

  SubmitResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

// ─── Service ───────────────────────────────────────────────────

class ExcelImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<PlatformFile?> pickExcelFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  // ─── PARSE (load into staging, no DB writes) ─────────────────

  ParseResult<StagedStudentRow> parseStudents(String filePath) {
    final rows = <StagedStudentRow>[];
    final errors = <StagingError>[];
    int totalRows = 0;

    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = excel_lib.Excel.decodeBytes(bytes);

      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null || sheet.rows.isEmpty) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          totalRows++;
          final row = sheet.rows[i];
          if (row.isEmpty || row.every((c) => c == null || c.value == null || c.value.toString().trim().isEmpty)) {
            continue;
          }

          String rawId = _cellStr(row, 0);
          final fullName = _cellStr(row, 1);
          final department = _cellStr(row, 2);
          final batch = _cellStr(row, 3);
          final phone = _cellStr(row, 4);
          final ageStr = _cellStr(row, 5);
          final sex = _cellStr(row, 6);

          if (fullName.isEmpty) {
            errors.add(StagingError(i + 1, 'full_name is required'));
            continue;
          }

          rawId = _normalizeStudentId(rawId);
          rows.add(StagedStudentRow(
            studentId: rawId,
            fullName: fullName,
            department: department,
            batch: batch.isNotEmpty ? batch : '2024',
            phone: phone,
            ageStr: ageStr,
            sex: sex,
          ));
        }
      }
    } catch (e) {
      errors.add(StagingError(0, 'File parse error: $e'));
    }

    return ParseResult(rows: rows, errors: errors, totalRows: totalRows);
  }

  ParseResult<StagedCourseRow> parseCourses(String filePath) {
    final rows = <StagedCourseRow>[];
    final errors = <StagingError>[];
    int totalRows = 0;

    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = excel_lib.Excel.decodeBytes(bytes);

      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null || sheet.rows.isEmpty) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          totalRows++;
          final row = sheet.rows[i];
          if (row.isEmpty || row.every((c) => c == null || c.value == null || c.value.toString().trim().isEmpty)) {
            continue;
          }

          final courseCode = _cellStr(row, 0);
          final courseTitle = _cellStr(row, 1);
          final creditHoursStr = _cellStr(row, 2);
          final instructor = _cellStr(row, 3);
          final semester = _cellStr(row, 4);
          final department = _cellStr(row, 5);

          if (courseCode.isEmpty || courseTitle.isEmpty || instructor.isEmpty || semester.isEmpty) {
            errors.add(StagingError(i + 1, 'course_code, course_title, instructor, semester are required'));
            continue;
          }

          rows.add(StagedCourseRow(
            courseCode: courseCode,
            courseTitle: courseTitle,
            creditHoursStr: creditHoursStr.isNotEmpty ? creditHoursStr : '3',
            instructor: instructor,
            semester: semester,
            department: department,
          ));
        }
      }
    } catch (e) {
      errors.add(StagingError(0, 'File parse error: $e'));
    }

    return ParseResult(rows: rows, errors: errors, totalRows: totalRows);
  }

  ParseResult<StagedGradeRow> parseGrades(String filePath) {
    final rows = <StagedGradeRow>[];
    final errors = <StagingError>[];
    int totalRows = 0;

    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = excel_lib.Excel.decodeBytes(bytes);

      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null || sheet.rows.isEmpty) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          totalRows++;
          final row = sheet.rows[i];
          if (row.isEmpty || row.every((c) => c == null || c.value == null || c.value.toString().trim().isEmpty)) {
            continue;
          }

          final studentId = _normalizeStudentId(_cellStr(row, 0));
          final courseCode = _cellStr(row, 1);
          final midStr = _cellStr(row, 2);
          final assignmentStr = _cellStr(row, 3);
          final finalStr = _cellStr(row, 4);
          final semester = _cellStr(row, 5);

          if (studentId.isEmpty || courseCode.isEmpty || semester.isEmpty) {
            errors.add(StagingError(i + 1, 'student_id, course_code, and semester are required'));
            continue;
          }

          rows.add(StagedGradeRow(
            studentId: studentId,
            courseCode: courseCode,
            midStr: midStr.isNotEmpty ? midStr : '0',
            assignmentStr: assignmentStr.isNotEmpty ? assignmentStr : '0',
            finalStr: finalStr.isNotEmpty ? finalStr : '0',
            semester: semester,
          ));
        }
      }
    } catch (e) {
      errors.add(StagingError(0, 'File parse error: $e'));
    }

    return ParseResult(rows: rows, errors: errors, totalRows: totalRows);
  }

  // ─── SUBMIT (validate + write to DB, called from preview) ────

  Future<SubmitResult> submitStudents(List<StagedStudentRow> staged) async {
    final errors = <String>[];
    int successCount = 0;

    for (int i = 0; i < staged.length; i++) {
      final s = staged[i];
      try {
        final email = s.email;
        final password = s.password;

        UserCredential? userCred;
        try {
          userCred = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
        }

        final student = Student(
          studentId: s.studentId,
          fullName: s.fullName,
          department: s.department,
          batch: s.batch,
          email: email,
          password: password,
          phone: s.phone.isNotEmpty ? s.phone : null,
          age: s.age,
          sex: s.sex.isNotEmpty ? s.sex : null,
          uid: userCred?.user?.uid,
        );

        await _firestore.collection('students').doc(s.studentId).set(student.toMap());
        successCount++;
      } catch (e) {
        errors.add('Row ${i + 1} (${s.studentId}): ${e.toString()}');
      }
    }

    return SubmitResult(
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
    );
  }

  Future<SubmitResult> submitCourses(List<StagedCourseRow> staged) async {
    final errors = <String>[];
    int successCount = 0;

    for (int i = 0; i < staged.length; i++) {
      final s = staged[i];
      try {
        final course = Course(
          courseCode: s.courseCode,
          courseTitle: s.courseTitle,
          creditHours: s.creditHours,
          instructor: s.instructor,
          semester: s.semester,
          department: s.department,
          schedule: CourseSchedule(
            dayOfWeek: 'Monday',
            startTime: '09:00',
            endTime: '10:30',
          ),
        );

        await _firestore.collection('courses').add(course.toMap());
        successCount++;
      } catch (e) {
        errors.add('Row ${i + 1} (${s.courseCode}): ${e.toString()}');
      }
    }

    return SubmitResult(
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
    );
  }

  Future<SubmitResult> submitGrades(List<StagedGradeRow> staged) async {
    final errors = <String>[];
    int successCount = 0;

    // Pre-load for cross-checks
    final studentIds = await _loadAllStudentIds();
    final courseCodes = await _loadAllCourseCodes();

    for (int i = 0; i < staged.length; i++) {
      final s = staged[i];
      try {
        if (!studentIds.contains(s.studentId)) {
          errors.add('Row ${i + 1} (${s.studentId}): student does not exist in database');
          continue;
        }

        if (!courseCodes.contains(s.courseCode)) {
          errors.add('Row ${i + 1} (${s.courseCode}): course does not exist in database');
          continue;
        }

        final duplicate = await _hasDuplicateGrade(s.studentId, s.courseCode, s.semester);
        if (duplicate) {
          errors.add('Row ${i + 1}: duplicate — "${s.studentId}" already has grade for "${s.courseCode}" in "${s.semester}"');
          continue;
        }

        final grade = Grade.create(
          studentId: s.studentId,
          courseCode: s.courseCode,
          midScore: s.midScore,
          assignmentScore: s.assignmentScore,
          finalScore: s.finalScore,
          semester: s.semester,
        );

        await _firestore.collection('grades').add(grade.toMap());
        successCount++;
      } catch (e) {
        errors.add('Row ${i + 1}: ${e.toString()}');
      }
    }

    return SubmitResult(
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────

  String _normalizeStudentId(String id) {
    final trimmed = id.trim().toLowerCase();
    if (trimmed.startsWith('bdu')) return trimmed;
    return 'bdu$trimmed';
  }

  String _cellStr(List<excel_lib.Data?> row, int index) {
    if (index >= row.length) return '';
    final cell = row[index];
    if (cell == null) return '';
    final val = cell.value;
    if (val == null) return '';
    return val.toString().trim();
  }

  Future<Set<String>> _loadAllStudentIds() async {
    final snapshot = await _firestore.collection('students').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return (data['student_id'] as String? ?? '').toString();
    }).toSet();
  }

  Future<Set<String>> _loadAllCourseCodes() async {
    final snapshot = await _firestore.collection('courses').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return (data['course_code'] as String? ?? '').toString();
    }).toSet();
  }

  Future<bool> _hasDuplicateGrade(String studentId, String courseCode, String semester) async {
    final snapshot = await _firestore
        .collection('grades')
        .where('student_id', isEqualTo: studentId)
        .where('course_code', isEqualTo: courseCode)
        .where('semester', isEqualTo: semester)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
