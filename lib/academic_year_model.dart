import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicYearModel {
  final String id;
  final String name; // Example: 2026-27
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AcademicYearModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  AcademicYearModel copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicYearModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isCurrent': isCurrent,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AcademicYearModel.fromMap(
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

    return AcademicYearModel(
      id: id,
      name: map['name']?.toString() ?? '',
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      isCurrent: map['isCurrent'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'AcademicYearModel('
        'id: $id, '
        'name: $name, '
        'isCurrent: $isCurrent, '
        'isActive: $isActive'
        ')';
  }
}