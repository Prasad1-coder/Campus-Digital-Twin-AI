import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectAssignmentModel {
  final String id;

  // Teacher
  final String teacherId;
  final String teacherName;

  // Subject
  final String subjectId;
  final String subjectName;
  final String subjectCode;

  // Academic structure
  final String department;

  // NEW: Actual academic class/program reference
  final String classId;
  final String className;
  final String program;

  // Existing division/semester fields kept for compatibility
  final String division;
  final int semester;

  // NEW: Actual academic year document reference
  final String academicYearId;

  // Existing display value kept for compatibility
  final String academicYear;

  // Assignment
  final String assignmentType;

  final DateTime startDate;
  final DateTime? endDate;

  // Audit
  final String assignedBy;
  final String assignedByName;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectAssignmentModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.department,

    required this.classId,
    required this.className,
    required this.program,

    required this.division,
    required this.semester,

    required this.academicYearId,
    required this.academicYear,

    required this.assignmentType,
    required this.startDate,
    this.endDate,
    required this.assignedBy,
    required this.assignedByName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  SubjectAssignmentModel copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? department,

    String? classId,
    String? className,
    String? program,

    String? division,
    int? semester,

    String? academicYearId,
    String? academicYear,

    String? assignmentType,
    DateTime? startDate,
    DateTime? endDate,
    String? assignedBy,
    String? assignedByName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectAssignmentModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      department: department ?? this.department,

      classId: classId ?? this.classId,
      className: className ?? this.className,
      program: program ?? this.program,

      division: division ?? this.division,
      semester: semester ?? this.semester,

      academicYearId: academicYearId ?? this.academicYearId,
      academicYear: academicYear ?? this.academicYear,

      assignmentType: assignmentType ?? this.assignmentType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedByName: assignedByName ?? this.assignedByName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,

      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,

      'department': department,

      // NEW dynamic academic structure
      'classId': classId,
      'className': className,
      'program': program,

      // Existing fields
      'division': division,
      'semester': semester,

      // NEW academic year reference
      'academicYearId': academicYearId,

      // Existing display value
      'academicYear': academicYear,

      'assignmentType': assignmentType,

      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null
          ? Timestamp.fromDate(endDate!)
          : null,

      'assignedBy': assignedBy,
      'assignedByName': assignedByName,

      'isActive': isActive,

      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SubjectAssignmentModel.fromMap(
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

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) {
        return null;
      }

      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value);
      }

      return null;
    }

    return SubjectAssignmentModel(
      id: id,

      teacherId: map['teacherId']?.toString() ?? '',
      teacherName: map['teacherName']?.toString() ?? '',

      subjectId: map['subjectId']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',

      department: map['department']?.toString() ?? '',

      // NEW fields.
      // Empty defaults keep old Firestore documents readable.
      classId: map['classId']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      program: map['program']?.toString() ?? '',

      division: map['division']?.toString() ?? '',

      semester: (map['semester'] as num?)?.toInt() ?? 0,

      academicYearId:
          map['academicYearId']?.toString() ?? '',

      academicYear:
          map['academicYear']?.toString() ?? '',

      assignmentType:
          map['assignmentType']?.toString() ?? 'regular',

      startDate: parseDate(map['startDate']),
      endDate: parseNullableDate(map['endDate']),

      assignedBy:
          map['assignedBy']?.toString() ?? '',

      assignedByName:
          map['assignedByName']?.toString() ?? '',

      isActive:
          map['isActive'] as bool? ?? true,

      createdAt:
          parseDate(map['createdAt']),

      updatedAt:
          parseDate(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'SubjectAssignmentModel('
        'id: $id, '
        'teacherId: $teacherId, '
        'teacherName: $teacherName, '
        'subjectId: $subjectId, '
        'subjectName: $subjectName, '
        'department: $department, '
        'classId: $classId, '
        'className: $className, '
        'program: $program, '
        'division: $division, '
        'semester: $semester, '
        'academicYearId: $academicYearId, '
        'academicYear: $academicYear, '
        'isActive: $isActive'
        ')';
  }
}