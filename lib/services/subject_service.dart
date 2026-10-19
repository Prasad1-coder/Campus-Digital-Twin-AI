import 'package:cloud_firestore/cloud_firestore.dart';

import '/subject_model.dart';

class SubjectService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subjects =>
      _firestore.collection('subjects');

  // ------------------------------------------------------------
  // CREATE SUBJECT
  // ------------------------------------------------------------

  Future<String> createSubject(
    SubjectModel subject,
  ) async {
    final docRef = _subjects.doc();

    await docRef.set({
      ...subject.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ------------------------------------------------------------
  // UPDATE SUBJECT
  // ------------------------------------------------------------

  Future<void> updateSubject(
    SubjectModel subject,
  ) async {
    await _subjects.doc(subject.id).update({
      ...subject.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // ACTIVATE / DEACTIVATE SUBJECT
  // ------------------------------------------------------------

  Future<void> setSubjectStatus(
    String subjectId,
    bool isActive,
  ) async {
    await _subjects.doc(subjectId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // GET SINGLE SUBJECT
  // ------------------------------------------------------------

  Future<SubjectModel?> getSubject(
    String subjectId,
  ) async {
    final snapshot =
        await _subjects.doc(subjectId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return SubjectModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  // ------------------------------------------------------------
  // GET ALL SUBJECTS
  // ------------------------------------------------------------

  Future<List<SubjectModel>> getAllSubjects() async {
    final snapshot = await _subjects.get();

    print(
      'SUBJECT DOCUMENT COUNT: ${snapshot.docs.length}',
    );

    for (final doc in snapshot.docs) {
      print(
        'SUBJECT DATA: ${doc.id} -> ${doc.data()}',
      );
    }

    final subjects = snapshot.docs
        .map(
          (doc) => SubjectModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    subjects.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return subjects;
  }

  // ------------------------------------------------------------
  // GET ALL ACTIVE SUBJECTS
  // ------------------------------------------------------------

  Future<List<SubjectModel>> getActiveSubjects() async {
    final snapshot = await _subjects
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    final subjects = snapshot.docs
        .map(
          (doc) => SubjectModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    subjects.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return subjects;
  }

  // ------------------------------------------------------------
  // GET SUBJECTS BY DEPARTMENT
  // ------------------------------------------------------------

  Future<List<SubjectModel>> getSubjectsByDepartment(
    String department,
  ) async {
    final snapshot = await _subjects
        .where(
          'department',
          isEqualTo: department,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    final subjects = snapshot.docs
        .map(
          (doc) => SubjectModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    subjects.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return subjects;
  }

  // ------------------------------------------------------------
  // GET SUBJECTS BY DEPARTMENT + SEMESTER
  // ------------------------------------------------------------

  Future<List<SubjectModel>> getSubjectsBySemester({
    required String department,
    required int semester,
  }) async {
    final snapshot = await _subjects
        .where(
          'department',
          isEqualTo: department,
        )
        .where(
          'semester',
          isEqualTo: semester,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    final subjects = snapshot.docs
        .map(
          (doc) => SubjectModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    subjects.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return subjects;
  }

  // ------------------------------------------------------------
  // CHECK DUPLICATE SUBJECT CODE
  // ------------------------------------------------------------

  Future<bool> subjectCodeExists(
    String code, {
    String? excludeSubjectId,
  }) async {
    final snapshot = await _subjects
        .where(
          'code',
          isEqualTo: code.trim().toUpperCase(),
        )
        .limit(10)
        .get();

    for (final doc in snapshot.docs) {
      if (excludeSubjectId == null ||
          doc.id != excludeSubjectId) {
        return true;
      }
    }

    return false;
  }

  // ------------------------------------------------------------
  // DELETE SUBJECT
  // ------------------------------------------------------------

  Future<void> deleteSubject(
    String subjectId,
  ) async {
    await _subjects.doc(subjectId).delete();
  }
}