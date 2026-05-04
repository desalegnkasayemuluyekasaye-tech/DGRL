import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _studentsCollection = 
      FirebaseFirestore.instance.collection('students');

  // Add a new student to Firestore and create Firebase Auth account
  Future<String> addStudent(Student student) async {
    try {
      // Create Firebase Auth user for the student
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: student.email,
        password: student.password,
      );
      
      // Add student to Firestore with studentId as document ID
      final studentWithUid = Student(
        studentId: student.studentId,
        fullName: student.fullName,
        department: student.department,
        batch: student.batch,
        email: student.email,
        password: student.password,
        phone: student.phone,
        age: student.age,
        sex: student.sex,
        uid: userCredential.user!.uid,
      );
      
      await _studentsCollection.doc(student.studentId).set(studentWithUid.toMap());
      return student.studentId;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error adding student: $e');
      rethrow;
    } catch (e) {
      print('Error adding student: $e');
      rethrow;
    }
  }

  // Get student by student ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final querySnapshot = await _studentsCollection
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Student.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting student: $e');
      return null;
    }
  }

  // Get all students
  Future<List<Student>> getAllStudents() async {
    try {
      final querySnapshot = await _studentsCollection.get();
      return querySnapshot.docs
          .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all students: $e');
      return [];
    }
  }

  // Update student data by studentId (which is now the document ID)
  Future<bool> updateStudent(String studentId, Map<String, dynamic> data) async {
    try {
      await _studentsCollection.doc(studentId).update(data);
      return true;
    } catch (e) {
      print('Error updating student: $e');
      return false;
    }
  }

  // Update student data using Student object
  Future<bool> updateStudentData(Student student) async {
    try {
      await _studentsCollection.doc(student.studentId).update(student.toMap());
      return true;
    } catch (e) {
      print('Error updating student data: $e');
      return false;
    }
  }

  // Delete student
  Future<bool> deleteStudent(String studentId) async {
    try {
      await _studentsCollection.doc(studentId).delete();
      return true;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  // Search students by name or department
  Future<List<Student>> searchStudents(String query) async {
    try {
      final querySnapshot = await _studentsCollection
          .where('full_name', isGreaterThanOrEqualTo: query)
          .where('full_name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      
      return querySnapshot.docs
          .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching students: $e');
      return [];
    }
  }

  // Get students by department
  Future<List<Student>> getStudentsByDepartment(String department) async {
    try {
      final querySnapshot = await _studentsCollection
          .where('department', isEqualTo: department)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting students by department: $e');
      return [];
    }
  }

  // Get students by batch
  Future<List<Student>> getStudentsByBatch(String batch) async {
    try {
      final querySnapshot = await _studentsCollection
          .where('batch', isEqualTo: batch)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting students by batch: $e');
      return [];
    }
  }

  // Stream of all students
  Stream<List<Student>> streamAllStudents() {
    return _studentsCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  // Stream of students by department
  Stream<List<Student>> streamStudentsByDepartment(String department) {
    return _studentsCollection
        .where('department', isEqualTo: department)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }
}
