import 'package:cloud_firestore/cloud_firestore.dart';

import '../academic_class_model.dart';

class AcademicClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection('academic_classes');

  // ------------------------------------------------------------
  // CREATE CLASS
  // ------------------------------------------------------------

  Future<String> createClass(
    AcademicClassModel academicClass,
  ) async {
    final docRef = _classes.doc();

    await docRef.set(academicClass.toMap());

    return docRef.id;
  }

  // ------------------------------------------------------------
  // UPDATE CLASS
  // ------------------------------------------------------------

  Future<void> updateClass(
    AcademicClassModel academicClass,
  ) async {
    await _classes.doc(academicClass.id).update({
      ...academicClass.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // ACTIVATE / DEACTIVATE CLASS
  // ------------------------------------------------------------

  Future<void> setClassStatus(
    String classId,
    bool isActive,
  ) async {
    await _classes.doc(classId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // GET SINGLE CLASS
  // ------------------------------------------------------------

  Future<AcademicClassModel?> getClass(
    String classId,
  ) async {
    final snapshot = await _classes.doc(classId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AcademicClassModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  // ------------------------------------------------------------
  // GET ALL ACTIVE CLASSES
  // ------------------------------------------------------------

  Future<List<AcademicClassModel>> getActiveClasses() async {
    final snapshot = await _classes
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => AcademicClassModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ------------------------------------------------------------
  // GET CLASSES BY DEPARTMENT
  // ------------------------------------------------------------

  Future<List<AcademicClassModel>> getClassesByDepartment(
    String department,
  ) async {
    final snapshot = await _classes
        .where('department', isEqualTo: department)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => AcademicClassModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ------------------------------------------------------------
  // GET CLASSES BY DEPARTMENT + PROGRAM
  // ------------------------------------------------------------

  Future<List<AcademicClassModel>> getClassesByProgram({
    required String department,
    required String program,
  }) async {
    final snapshot = await _classes
        .where('department', isEqualTo: department)
        .where('program', isEqualTo: program)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => AcademicClassModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ------------------------------------------------------------
  // CHECK DUPLICATE CLASS
  // ------------------------------------------------------------

  Future<bool> classExists({
    required String department,
    required String program,
    required String yearCode,
  }) async {
    final snapshot = await _classes
        .where('department', isEqualTo: department)
        .where('program', isEqualTo: program)
        .where('yearCode', isEqualTo: yearCode)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ------------------------------------------------------------
  // DELETE CLASS
  // ------------------------------------------------------------
  //
  // IMPORTANT:
  // We will normally prefer deactivate instead of deleting,
  // because assignments and attendance may reference this class.
  // ------------------------------------------------------------

  Future<void> deleteClass(
    String classId,
  ) async {
    await _classes.doc(classId).delete();
  }
}