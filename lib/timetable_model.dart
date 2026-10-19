import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableModel {
  final String id;
  final String academicYearId;
  final String academicYear;
  final String department;
  final String program;
  final String classId;
  final String className;
  final String division;
  final int semester;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String teacherId;
  final String teacherName;
  final String assignmentId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String roomId;
  final String roomName;
  final String scheduleType;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TimetableModel({
    required this.id,
    required this.academicYearId,
    required this.academicYear,
    required this.department,
    required this.program,
    required this.classId,
    required this.className,
    required this.division,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.teacherId,
    required this.teacherName,
    required this.assignmentId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomId,
    required this.roomName,
    required this.scheduleType,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  TimetableModel copyWith({
    String? id,
    String? academicYearId,
    String? academicYear,
    String? department,
    String? program,
    String? classId,
    String? className,
    String? division,
    int? semester,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? teacherId,
    String? teacherName,
    String? assignmentId,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? roomId,
    String? roomName,
    String? scheduleType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      academicYearId: academicYearId ?? this.academicYearId,
      academicYear: academicYear ?? this.academicYear,
      department: department ?? this.department,
      program: program ?? this.program,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      division: division ?? this.division,
      semester: semester ?? this.semester,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      assignmentId: assignmentId ?? this.assignmentId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      scheduleType: scheduleType ?? this.scheduleType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Fields shared by create AND update (everything except the timestamps).
  Map<String, dynamic> _coreFields() {
    return {
      'academicYearId': academicYearId,
      'academicYear': academicYear,
      'department': department,
      'program': program,
      'classId': classId,
      'className': className,
      'division': division,
      'semester': semester,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'assignmentId': assignmentId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'roomId': roomId,
      'roomName': roomName,
      'scheduleType': scheduleType,
      'isActive': isActive,
    };
  }

  // Use for CREATING a new document (sets createdAt + updatedAt).
  Map<String, dynamic> toMap() {
    return {
      ..._coreFields(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Use for EDITING an existing document with update().
  // createdAt is deliberately left out so an edit never overwrites the
  // original creation time; only updatedAt moves forward.
  Map<String, dynamic> toUpdateMap() {
    return {
      ..._coreFields(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TimetableModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TimetableModel(
      id: id,
      academicYearId: map['academicYearId']?.toString() ?? '',
      academicYear: map['academicYear']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      program: map['program']?.toString() ?? '',
      classId: map['classId']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      division: map['division']?.toString() ?? '',
      semester: _parseInt(map['semester']),
      subjectId: map['subjectId']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',
      teacherId: map['teacherId']?.toString() ?? '',
      teacherName: map['teacherName']?.toString() ?? '',
      assignmentId: map['assignmentId']?.toString() ?? '',
      dayOfWeek: map['dayOfWeek']?.toString() ?? '',
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
      roomId: map['roomId']?.toString() ?? '',
      roomName: map['roomName']?.toString() ?? '',
      scheduleType: map['scheduleType']?.toString() ?? 'lecture',
      isActive: _parseBool(map['isActive']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Accepts true and also the string "true" (a common Firebase Console typo).
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _parseDateTime(dynamic value) {
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

  String get timeRange {
    if (startTime.isEmpty && endTime.isEmpty) {
      return '';
    }

    if (endTime.isEmpty) {
      return startTime;
    }

    if (startTime.isEmpty) {
      return endTime;
    }

    return '$startTime - $endTime';
  }

  bool get isLecture {
    return scheduleType.toLowerCase() == 'lecture';
  }

  bool get isLab {
    return scheduleType.toLowerCase() == 'lab';
  }

  bool get isPractical {
    return scheduleType.toLowerCase() == 'practical';
  }

  String get scheduleTypeLabel {
    switch (scheduleType.toLowerCase()) {
      case 'lab':
        return 'Lab';

      case 'practical':
        return 'Practical';

      case 'lecture':
        return 'Lecture';

      default:
        return scheduleType;
    }
  }

  String get normalizedDay {
    return dayOfWeek.trim().toLowerCase();
  }

  bool get isMonday {
    return normalizedDay == 'monday' ||
        normalizedDay == 'mon';
  }

  bool get isTuesday {
    return normalizedDay == 'tuesday' ||
        normalizedDay == 'tue';
  }

  bool get isWednesday {
    return normalizedDay == 'wednesday' ||
        normalizedDay == 'wed';
  }

  bool get isThursday {
    return normalizedDay == 'thursday' ||
        normalizedDay == 'thu';
  }

  bool get isFriday {
    return normalizedDay == 'friday' ||
        normalizedDay == 'fri';
  }

  bool get isSaturday {
    return normalizedDay == 'saturday' ||
        normalizedDay == 'sat';
  }

  String get classDisplayName {
    if (division.isEmpty) {
      return className;
    }

    return '$className - Division $division';
  }

  String get subjectDisplayName {
    if (subjectCode.isEmpty) {
      return subjectName;
    }

    if (subjectName.isEmpty) {
      return subjectCode;
    }

    return '$subjectName ($subjectCode)';
  }

  @override
  String toString() {
    return 'TimetableModel('
        'id: $id, '
        'academicYearId: $academicYearId, '
        'academicYear: $academicYear, '
        'department: $department, '
        'program: $program, '
        'classId: $classId, '
        'className: $className, '
        'division: $division, '
        'semester: $semester, '
        'subjectId: $subjectId, '
        'subjectName: $subjectName, '
        'subjectCode: $subjectCode, '
        'teacherId: $teacherId, '
        'teacherName: $teacherName, '
        'assignmentId: $assignmentId, '
        'dayOfWeek: $dayOfWeek, '
        'startTime: $startTime, '
        'endTime: $endTime, '
        'roomId: $roomId, '
        'roomName: $roomName, '
        'scheduleType: $scheduleType, '
        'isActive: $isActive'
        ')';
  }
}