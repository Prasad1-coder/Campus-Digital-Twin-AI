import 'package:cloud_firestore/cloud_firestore.dart';

import '../academic_year_model.dart';

class AcademicYearService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _years =>
      _firestore.collection('academic_years');

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> createAcademicYear(
    AcademicYearModel academicYear,
  ) async {
    final docRef = _years.doc();

    await docRef.set(
      academicYear.toMap(),
    );

    return docRef.id;
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateAcademicYear(
    AcademicYearModel academicYear,
  ) async {
    await _years.doc(academicYear.id).update({
      ...academicYear.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

  Future<void> setAcademicYearStatus(
    String yearId,
    bool isActive,
  ) async {
    await _years.doc(yearId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // SET CURRENT ACADEMIC YEAR
  // ============================================================

  Future<void> setCurrentAcademicYear(
    String yearId,
  ) async {
    final batch = _firestore.batch();

    final snapshot = await _years
        .where('isCurrent', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(
        doc.reference,
        {
          'isCurrent': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    batch.update(
      _years.doc(yearId),
      {
        'isCurrent': true,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ============================================================
  // GET SINGLE
  // ============================================================

  Future<AcademicYearModel?> getAcademicYear(
    String yearId,
  ) async {
    final snapshot =
        await _years.doc(yearId).get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      return null;
    }

    return AcademicYearModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  // ============================================================
  // GET ALL ACTIVE YEARS
  // ============================================================

  Future<List<AcademicYearModel>>
      getActiveAcademicYears() async {
    final snapshot = await _years
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    final years = snapshot.docs
        .map(
          (doc) => AcademicYearModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    years.sort(
      (a, b) => b.startDate.compareTo(
        a.startDate,
      ),
    );

    return years;
  }

  // ============================================================
  // GET CURRENT YEAR
  // ============================================================

  Future<AcademicYearModel?> getCurrentAcademicYear() async {
    final snapshot = await _years
        .where(
          'isCurrent',
          isEqualTo: true,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    return AcademicYearModel.fromMap(
      doc.id,
      doc.data(),
    );
  }

  // ============================================================
  // CHECK DUPLICATE
  // ============================================================

  Future<bool> academicYearExists(
    String name,
  ) async {
    final snapshot = await _years
        .where(
          'name',
          isEqualTo: name,
        )
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}