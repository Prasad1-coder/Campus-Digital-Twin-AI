import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String id;
  final String name;
  final String code;
  final String department;
  final int semester;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    required this.department,
    required this.semester,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  SubjectModel copyWith({
    String? id,
    String? name,
    String? code,
    String? department,
    int? semester,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'department': department,
      'semester': semester,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SubjectModel.fromMap(
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

    return SubjectModel(
      id: id,
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      semester: (map['semester'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'SubjectModel('
        'id: $id, '
        'name: $name, '
        'code: $code, '
        'department: $department, '
        'semester: $semester, '
        'isActive: $isActive'
        ')';
  }
}