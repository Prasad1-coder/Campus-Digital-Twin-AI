import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicClassModel {
  final String id;

  // Example: Computer Science
  final String department;

  // Example: BSc Computer Science
  final String program;

  // Example: 1st Year / 2nd Year / 3rd Year
  final String yearName;

  // Example: FY / SY / TY
  final String yearCode;

  // Example: [1, 2] for 1st Year
  final List<int> semesters;

  // Example: ["A", "B", "C"]
  final List<String> divisions;

  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AcademicClassModel({
    required this.id,
    required this.department,
    required this.program,
    required this.yearName,
    required this.yearCode,
    required this.semesters,
    required this.divisions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  AcademicClassModel copyWith({
    String? id,
    String? department,
    String? program,
    String? yearName,
    String? yearCode,
    List<int>? semesters,
    List<String>? divisions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicClassModel(
      id: id ?? this.id,
      department: department ?? this.department,
      program: program ?? this.program,
      yearName: yearName ?? this.yearName,
      yearCode: yearCode ?? this.yearCode,
      semesters: semesters ?? this.semesters,
      divisions: divisions ?? this.divisions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'department': department,
      'program': program,
      'yearName': yearName,
      'yearCode': yearCode,
      'semesters': semesters,
      'divisions': divisions,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AcademicClassModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }

      return DateTime.now();
    }

    return AcademicClassModel(
      id: id,
      department: map['department']?.toString() ?? '',
      program: map['program']?.toString() ?? '',
      yearName: map['yearName']?.toString() ?? '',
      yearCode: map['yearCode']?.toString() ?? '',
      semesters: (map['semesters'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      divisions: (map['divisions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'AcademicClassModel('
        'id: $id, '
        'department: $department, '
        'program: $program, '
        'yearName: $yearName, '
        'yearCode: $yearCode, '
        'semesters: $semesters, '
        'divisions: $divisions, '
        'isActive: $isActive'
        ')';
  }
}