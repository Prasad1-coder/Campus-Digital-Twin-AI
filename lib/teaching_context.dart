import 'package:flutter/foundation.dart';

class TeachingContext {
  final String teacherId;
  final String teacherName;
  final String assignmentId;
  final String department;
  final String program;
  final String academicYearId;
  final String academicYear;
  final String classId;
  final String className;
  final String division;
  final int semester;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String assignmentType;

  const TeachingContext({
    required this.teacherId,
    required this.teacherName,
    required this.assignmentId,
    required this.department,
    required this.program,
    required this.academicYearId,
    required this.academicYear,
    required this.classId,
    required this.className,
    required this.division,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.assignmentType,
  });

  TeachingContext copyWith({
    String? teacherId,
    String? teacherName,
    String? assignmentId,
    String? department,
    String? program,
    String? academicYearId,
    String? academicYear,
    String? classId,
    String? className,
    String? division,
    int? semester,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? assignmentType,
  }) {
    return TeachingContext(
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      assignmentId: assignmentId ?? this.assignmentId,
      department: department ?? this.department,
      program: program ?? this.program,
      academicYearId: academicYearId ?? this.academicYearId,
      academicYear: academicYear ?? this.academicYear,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      division: division ?? this.division,
      semester: semester ?? this.semester,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      assignmentType: assignmentType ?? this.assignmentType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'assignmentId': assignmentId,
      'department': department,
      'program': program,
      'academicYearId': academicYearId,
      'academicYear': academicYear,
      'classId': classId,
      'className': className,
      'division': division,
      'semester': semester,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'assignmentType': assignmentType,
    };
  }

  factory TeachingContext.fromMap(Map<String, dynamic> map) {
    return TeachingContext(
      teacherId: map['teacherId']?.toString() ?? '',
      teacherName: map['teacherName']?.toString() ?? '',
      assignmentId: map['assignmentId']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      program: map['program']?.toString() ?? '',
      academicYearId: map['academicYearId']?.toString() ?? '',
      academicYear: map['academicYear']?.toString() ?? '',
      classId: map['classId']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      division: map['division']?.toString() ?? '',
      semester: _parseInt(map['semester']),
      subjectId: map['subjectId']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',
      assignmentType: map['assignmentType']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  String toString() => 'TeachingContext(${toMap()})';

  void debugPrintContext() {
    if (kDebugMode) {
      debugPrint(toString());
    }
  }
}