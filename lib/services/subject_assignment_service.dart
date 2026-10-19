import 'package:cloud_firestore/cloud_firestore.dart';

import '/subject_assignment_model.dart';

class SubjectAssignmentService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _assignments =>
          _firestore.collection('subject_assignments');

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> createAssignment(
    SubjectAssignmentModel assignment,
  ) async {
    final docRef = _assignments.doc();

    final data = assignment.toMap();

    await docRef.set(data);

    return docRef.id;
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateAssignment(
    SubjectAssignmentModel assignment,
  ) async {
    await _assignments.doc(assignment.id).update({
      ...assignment.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ACTIVE / INACTIVE
  // ============================================================

  Future<void> setAssignmentStatus(
    String assignmentId,
    bool isActive,
  ) async {
    await _assignments.doc(assignmentId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // GET SINGLE ASSIGNMENT
  // ============================================================

  Future<SubjectAssignmentModel?> getAssignment(
    String assignmentId,
  ) async {
    final snapshot =
        await _assignments.doc(assignmentId).get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      return null;
    }

    return SubjectAssignmentModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  // ============================================================
  // TEACHER ASSIGNMENTS
  // ============================================================

  Future<List<SubjectAssignmentModel>>
      getTeacherAssignments(
    String teacherId,
  ) async {
    final snapshot = await _assignments
        .where(
          'teacherId',
          isEqualTo: teacherId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              SubjectAssignmentModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ============================================================
  // TEACHER ASSIGNMENTS FOR SPECIFIC CLASS
  // ============================================================

  Future<List<SubjectAssignmentModel>>
      getTeacherClassAssignments({
    required String teacherId,
    required String classId,
    required String academicYearId,
  }) async {
    final snapshot = await _assignments
        .where(
          'teacherId',
          isEqualTo: teacherId,
        )
        .where(
          'classId',
          isEqualTo: classId,
        )
        .where(
          'academicYearId',
          isEqualTo: academicYearId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              SubjectAssignmentModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ============================================================
  // DEPARTMENT ASSIGNMENTS
  // ============================================================

  Future<List<SubjectAssignmentModel>>
      getDepartmentAssignments(
    String department,
  ) async {
    final snapshot = await _assignments
        .where(
          'department',
          isEqualTo: department,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              SubjectAssignmentModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ============================================================
  // CLASS ASSIGNMENTS
  // ============================================================

  Future<List<SubjectAssignmentModel>>
      getClassAssignments({
    required String classId,
    required String academicYearId,
  }) async {
    final snapshot = await _assignments
        .where(
          'classId',
          isEqualTo: classId,
        )
        .where(
          'academicYearId',
          isEqualTo: academicYearId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              SubjectAssignmentModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ============================================================
  // CLASS + DIVISION + SEMESTER
  // ============================================================

  Future<List<SubjectAssignmentModel>>
      getClassDivisionAssignments({
    required String classId,
    required String division,
    required int semester,
    required String academicYearId,
  }) async {
    final snapshot = await _assignments
        .where(
          'classId',
          isEqualTo: classId,
        )
        .where(
          'division',
          isEqualTo: division,
        )
        .where(
          'semester',
          isEqualTo: semester,
        )
        .where(
          'academicYearId',
          isEqualTo: academicYearId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              SubjectAssignmentModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ============================================================
  // DEPARTMENT + CLASS
  // ============================================================

  Future<List<SubjectAssignmentModel>>
      getDepartmentClassAssignments({
    required String department,
    required String classId,
    required String academicYearId,
  }) async {
    final snapshot = await _assignments
        .where(
          'department',
          isEqualTo: department,
        )
        .where(
          'classId',
          isEqualTo: classId,
        )
        .where(
          'academicYearId',
          isEqualTo: academicYearId,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              SubjectAssignmentModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ============================================================
  // LEGACY / COMPATIBILITY METHOD
  // ============================================================

  Future<List<SubjectAssignmentModel>>
      getLegacyClassAssignments({
    required String department,
    required String division,
    required int semester,
    required String academicYear,
  }) async {
    final snapshot = await _assignments
        .where(
          'department',
          isEqualTo: department,
        )
        .where(
          'division',
          isEqualTo: division,
        )
        .where(
          'semester',
          isEqualTo: semester,
        )
        .where(
          'academicYear',
          isEqualTo: academicYear,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              SubjectAssignmentModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  // ============================================================
  // CHECK TEACHER ASSIGNMENT
  // ============================================================

  Future<bool> isTeacherAssigned({
    required String teacherId,
    required String subjectId,
    required String classId,
    required String division,
    required int semester,
    required String academicYearId,
  }) async {
    final snapshot = await _assignments
        .where(
          'teacherId',
          isEqualTo: teacherId,
        )
        .where(
          'subjectId',
          isEqualTo: subjectId,
        )
        .where(
          'classId',
          isEqualTo: classId,
        )
        .where(
          'division',
          isEqualTo: division,
        )
        .where(
          'semester',
          isEqualTo: semester,
        )
        .where(
          'academicYearId',
          isEqualTo: academicYearId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteAssignment(
    String assignmentId,
  ) async {
    await _assignments
        .doc(assignmentId)
        .delete();
  }
}