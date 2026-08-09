import 'dart:convert';

/// Represents the granular actions a user can perform on a specific module.
class ActionPermissions {
  final bool canView;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canApprove;
  final bool canExport;
  final bool canManage;

  const ActionPermissions({
    this.canView = false,
    this.canCreate = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canApprove = false,
    this.canExport = false,
    this.canManage = false,
  });

  const ActionPermissions.readOnly() : this(canView: true);

  const ActionPermissions.fullAccess()
      : this(
          canView: true,
          canCreate: true,
          canEdit: true,
          canDelete: true,
          canApprove: true,
          canExport: true,
          canManage: true,
        );

  ActionPermissions copyWith({
    bool? canView,
    bool? canCreate,
    bool? canEdit,
    bool? canDelete,
    bool? canApprove,
    bool? canExport,
    bool? canManage,
  }) {
    return ActionPermissions(
      canView: canView ?? this.canView,
      canCreate: canCreate ?? this.canCreate,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canApprove: canApprove ?? this.canApprove,
      canExport: canExport ?? this.canExport,
      canManage: canManage ?? this.canManage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canView': canView,
      'canCreate': canCreate,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'canApprove': canApprove,
      'canExport': canExport,
      'canManage': canManage,
    };
  }

  factory ActionPermissions.fromMap(Map<String, dynamic> map) {
    return ActionPermissions(
      canView: map['canView'] as bool? ?? false,
      canCreate: map['canCreate'] as bool? ?? false,
      canEdit: map['canEdit'] as bool? ?? false,
      canDelete: map['canDelete'] as bool? ?? false,
      canApprove: map['canApprove'] as bool? ?? false,
      canExport: map['canExport'] as bool? ?? false,
      canManage: map['canManage'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ActionPermissions.fromJson(String source) =>
      ActionPermissions.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ActionPermissions(canView: $canView, canCreate: $canCreate, canEdit: $canEdit, canDelete: $canDelete, canApprove: $canApprove, canExport: $canExport, canManage: $canManage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActionPermissions &&
        other.canView == canView &&
        other.canCreate == canCreate &&
        other.canEdit == canEdit &&
        other.canDelete == canDelete &&
        other.canApprove == canApprove &&
        other.canExport == canExport &&
        other.canManage == canManage;
  }

  @override
  int get hashCode {
    return Object.hash(
      canView, canCreate, canEdit, canDelete, canApprove, canExport, canManage,
    );
  }
}

/// Represents the complete permission set for a user or role across all modules.
class PermissionModel {
  final String id;
  final String ownerId;

  final ActionPermissions dashboard;
  final ActionPermissions aiAssistant;
  final ActionPermissions attendance;
  final ActionPermissions attendanceScan;
  final ActionPermissions timetable;
  final ActionPermissions library;
  final ActionPermissions canteen;
  final ActionPermissions placement;
  final ActionPermissions events;
  final ActionPermissions notice;
  final ActionPermissions digitalId;
  final ActionPermissions analytics;
  final ActionPermissions campusMap;
  final ActionPermissions profile;
  final ActionPermissions settings;
  final ActionPermissions reports;
  final ActionPermissions departmentManagement;
  final ActionPermissions collegeManagement;
  final ActionPermissions studentManagement;
  final ActionPermissions teacherManagement;
  final ActionPermissions hodManagement;
  final ActionPermissions principalManagement;
  final ActionPermissions userManagement;
  final ActionPermissions roleManagement;
  final ActionPermissions permissionManagement;

  const PermissionModel({
    required this.id,
    required this.ownerId,
    this.dashboard = const ActionPermissions.readOnly(),
    this.aiAssistant = const ActionPermissions.readOnly(),
    this.attendance = const ActionPermissions.readOnly(),
    this.attendanceScan = const ActionPermissions.readOnly(),
    this.timetable = const ActionPermissions.readOnly(),
    this.library = const ActionPermissions.readOnly(),
    this.canteen = const ActionPermissions.readOnly(),
    this.placement = const ActionPermissions.readOnly(),
    this.events = const ActionPermissions.readOnly(),
    this.notice = const ActionPermissions.readOnly(),
    this.digitalId = const ActionPermissions.readOnly(),
    this.analytics = const ActionPermissions.readOnly(),
    this.campusMap = const ActionPermissions.readOnly(),
    this.profile = const ActionPermissions.readOnly(),
    this.settings = const ActionPermissions.readOnly(),
    this.reports = const ActionPermissions(),
    this.departmentManagement = const ActionPermissions(),
    this.collegeManagement = const ActionPermissions(),
    this.studentManagement = const ActionPermissions(),
    this.teacherManagement = const ActionPermissions(),
    this.hodManagement = const ActionPermissions(),
    this.principalManagement = const ActionPermissions(),
    this.userManagement = const ActionPermissions(),
    this.roleManagement = const ActionPermissions(),
    this.permissionManagement = const ActionPermissions(),
  });

  factory PermissionModel.student({required String id, required String ownerId}) {
    return PermissionModel(
      id: id, ownerId: ownerId,
      dashboard: const ActionPermissions.readOnly(),
      aiAssistant: const ActionPermissions.readOnly(),
      attendance: const ActionPermissions.readOnly(),
      attendanceScan: const ActionPermissions(canView: true, canCreate: true),
      timetable: const ActionPermissions.readOnly(),
      library: const ActionPermissions.readOnly(),
      canteen: const ActionPermissions.readOnly(),
      placement: const ActionPermissions.readOnly(),
      events: const ActionPermissions.readOnly(),
      notice: const ActionPermissions.readOnly(),
      digitalId: const ActionPermissions.readOnly(),
      analytics: const ActionPermissions(),
      campusMap: const ActionPermissions.readOnly(),
      profile: const ActionPermissions(canView: true, canEdit: true),
      settings: const ActionPermissions.readOnly(),
    );
  }

  factory PermissionModel.teacher({required String id, required String ownerId}) {
    return PermissionModel(
      id: id, ownerId: ownerId,
      dashboard: const ActionPermissions.readOnly(),
      aiAssistant: const ActionPermissions.readOnly(),
      attendance: const ActionPermissions(canView: true, canCreate: true, canEdit: true, canExport: true),
      attendanceScan: const ActionPermissions(canView: true, canCreate: true, canManage: true),
      timetable: const ActionPermissions.readOnly(),
      library: const ActionPermissions.readOnly(),
      canteen: const ActionPermissions.readOnly(),
      placement: const ActionPermissions.readOnly(),
      events: const ActionPermissions(canView: true, canCreate: true, canEdit: true),
      notice: const ActionPermissions(canView: true, canCreate: true, canEdit: true),
      digitalId: const ActionPermissions.readOnly(),
      analytics: const ActionPermissions.readOnly(),
      campusMap: const ActionPermissions.readOnly(),
      profile: const ActionPermissions(canView: true, canEdit: true),
      settings: const ActionPermissions.readOnly(),
      reports: const ActionPermissions(canView: true, canExport: true),
      studentManagement: const ActionPermissions(canView: true, canEdit: true),
    );
  }

  factory PermissionModel.hod({required String id, required String ownerId}) {
    return PermissionModel(
      id: id, ownerId: ownerId,
      dashboard: const ActionPermissions.readOnly(),
      aiAssistant: const ActionPermissions.readOnly(),
      attendance: const ActionPermissions.fullAccess(),
      attendanceScan: const ActionPermissions.fullAccess(),
      timetable: const ActionPermissions(canView: true, canManage: true),
      library: const ActionPermissions.readOnly(),
      canteen: const ActionPermissions.readOnly(),
      placement: const ActionPermissions(canView: true, canApprove: true, canManage: true),
      events: const ActionPermissions.fullAccess(),
      notice: const ActionPermissions.fullAccess(),
      digitalId: const ActionPermissions.readOnly(),
      analytics: const ActionPermissions(canView: true, canExport: true),
      campusMap: const ActionPermissions.readOnly(),
      profile: const ActionPermissions(canView: true, canEdit: true),
      settings: const ActionPermissions.readOnly(),
      reports: const ActionPermissions.fullAccess(),
      departmentManagement: const ActionPermissions(canView: true, canEdit: true, canManage: true),
      studentManagement: const ActionPermissions.fullAccess(),
      teacherManagement: const ActionPermissions(canView: true, canEdit: true),
    );
  }

  factory PermissionModel.principal({required String id, required String ownerId}) {
    return PermissionModel(
      id: id, ownerId: ownerId,
      dashboard: const ActionPermissions.fullAccess(),
      aiAssistant: const ActionPermissions.fullAccess(),
      attendance: const ActionPermissions.fullAccess(),
      attendanceScan: const ActionPermissions.fullAccess(),
      timetable: const ActionPermissions.fullAccess(),
      library: const ActionPermissions.fullAccess(),
      canteen: const ActionPermissions.fullAccess(),
      placement: const ActionPermissions.fullAccess(),
      events: const ActionPermissions.fullAccess(),
      notice: const ActionPermissions.fullAccess(),
      digitalId: const ActionPermissions.readOnly(),
      analytics: const ActionPermissions.fullAccess(),
      campusMap: const ActionPermissions.readOnly(),
      profile: const ActionPermissions(canView: true, canEdit: true),
      settings: const ActionPermissions.fullAccess(),
      reports: const ActionPermissions.fullAccess(),
      departmentManagement: const ActionPermissions.fullAccess(),
      collegeManagement: const ActionPermissions.fullAccess(),
      studentManagement: const ActionPermissions.fullAccess(),
      teacherManagement: const ActionPermissions.fullAccess(),
      hodManagement: const ActionPermissions.fullAccess(),
      principalManagement: const ActionPermissions(canView: true),
      userManagement: const ActionPermissions.fullAccess(),
      roleManagement: const ActionPermissions.fullAccess(),
      permissionManagement: const ActionPermissions.fullAccess(),
    );
  }

  PermissionModel copyWith({
    String? id, String? ownerId,
    ActionPermissions? dashboard, ActionPermissions? aiAssistant, ActionPermissions? attendance, ActionPermissions? attendanceScan, ActionPermissions? timetable, ActionPermissions? library, ActionPermissions? canteen, ActionPermissions? placement, ActionPermissions? events, ActionPermissions? notice, ActionPermissions? digitalId, ActionPermissions? analytics, ActionPermissions? campusMap, ActionPermissions? profile, ActionPermissions? settings, ActionPermissions? reports, ActionPermissions? departmentManagement, ActionPermissions? collegeManagement, ActionPermissions? studentManagement, ActionPermissions? teacherManagement, ActionPermissions? hodManagement, ActionPermissions? principalManagement, ActionPermissions? userManagement, ActionPermissions? roleManagement, ActionPermissions? permissionManagement,
  }) {
    return PermissionModel(
      id: id ?? this.id, ownerId: ownerId ?? this.ownerId,
      dashboard: dashboard ?? this.dashboard, aiAssistant: aiAssistant ?? this.aiAssistant, attendance: attendance ?? this.attendance, attendanceScan: attendanceScan ?? this.attendanceScan, timetable: timetable ?? this.timetable, library: library ?? this.library, canteen: canteen ?? this.canteen, placement: placement ?? this.placement, events: events ?? this.events, notice: notice ?? this.notice, digitalId: digitalId ?? this.digitalId, analytics: analytics ?? this.analytics, campusMap: campusMap ?? this.campusMap, profile: profile ?? this.profile, settings: settings ?? this.settings, reports: reports ?? this.reports, departmentManagement: departmentManagement ?? this.departmentManagement, collegeManagement: collegeManagement ?? this.collegeManagement, studentManagement: studentManagement ?? this.studentManagement, teacherManagement: teacherManagement ?? this.teacherManagement, hodManagement: hodManagement ?? this.hodManagement, principalManagement: principalManagement ?? this.principalManagement, userManagement: userManagement ?? this.userManagement, roleManagement: roleManagement ?? this.roleManagement, permissionManagement: permissionManagement ?? this.permissionManagement,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'ownerId': ownerId,
      'dashboard': dashboard.toMap(), 'aiAssistant': aiAssistant.toMap(), 'attendance': attendance.toMap(), 'attendanceScan': attendanceScan.toMap(), 'timetable': timetable.toMap(), 'library': library.toMap(), 'canteen': canteen.toMap(), 'placement': placement.toMap(), 'events': events.toMap(), 'notice': notice.toMap(), 'digitalId': digitalId.toMap(), 'analytics': analytics.toMap(), 'campusMap': campusMap.toMap(), 'profile': profile.toMap(), 'settings': settings.toMap(), 'reports': reports.toMap(), 'departmentManagement': departmentManagement.toMap(), 'collegeManagement': collegeManagement.toMap(), 'studentManagement': studentManagement.toMap(), 'teacherManagement': teacherManagement.toMap(), 'hodManagement': hodManagement.toMap(), 'principalManagement': principalManagement.toMap(), 'userManagement': userManagement.toMap(), 'roleManagement': roleManagement.toMap(), 'permissionManagement': permissionManagement.toMap(),
    };
  }

  factory PermissionModel.fromMap(Map<String, dynamic> map) {
    return PermissionModel(
      id: map['id'] as String? ?? '', ownerId: map['ownerId'] as String? ?? '',
      dashboard: ActionPermissions.fromMap(map['dashboard'] as Map<String, dynamic>? ?? {}), aiAssistant: ActionPermissions.fromMap(map['aiAssistant'] as Map<String, dynamic>? ?? {}), attendance: ActionPermissions.fromMap(map['attendance'] as Map<String, dynamic>? ?? {}), attendanceScan: ActionPermissions.fromMap(map['attendanceScan'] as Map<String, dynamic>? ?? {}), timetable: ActionPermissions.fromMap(map['timetable'] as Map<String, dynamic>? ?? {}), library: ActionPermissions.fromMap(map['library'] as Map<String, dynamic>? ?? {}), canteen: ActionPermissions.fromMap(map['canteen'] as Map<String, dynamic>? ?? {}), placement: ActionPermissions.fromMap(map['placement'] as Map<String, dynamic>? ?? {}), events: ActionPermissions.fromMap(map['events'] as Map<String, dynamic>? ?? {}), notice: ActionPermissions.fromMap(map['notice'] as Map<String, dynamic>? ?? {}), digitalId: ActionPermissions.fromMap(map['digitalId'] as Map<String, dynamic>? ?? {}), analytics: ActionPermissions.fromMap(map['analytics'] as Map<String, dynamic>? ?? {}), campusMap: ActionPermissions.fromMap(map['campusMap'] as Map<String, dynamic>? ?? {}), profile: ActionPermissions.fromMap(map['profile'] as Map<String, dynamic>? ?? {}), settings: ActionPermissions.fromMap(map['settings'] as Map<String, dynamic>? ?? {}), reports: ActionPermissions.fromMap(map['reports'] as Map<String, dynamic>? ?? {}), departmentManagement: ActionPermissions.fromMap(map['departmentManagement'] as Map<String, dynamic>? ?? {}), collegeManagement: ActionPermissions.fromMap(map['collegeManagement'] as Map<String, dynamic>? ?? {}), studentManagement: ActionPermissions.fromMap(map['studentManagement'] as Map<String, dynamic>? ?? {}), teacherManagement: ActionPermissions.fromMap(map['teacherManagement'] as Map<String, dynamic>? ?? {}), hodManagement: ActionPermissions.fromMap(map['hodManagement'] as Map<String, dynamic>? ?? {}), principalManagement: ActionPermissions.fromMap(map['principalManagement'] as Map<String, dynamic>? ?? {}), userManagement: ActionPermissions.fromMap(map['userManagement'] as Map<String, dynamic>? ?? {}), roleManagement: ActionPermissions.fromMap(map['roleManagement'] as Map<String, dynamic>? ?? {}), permissionManagement: ActionPermissions.fromMap(map['permissionManagement'] as Map<String, dynamic>? ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory PermissionModel.fromJson(String source) =>
      PermissionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PermissionModel(id: $id, ownerId: $ownerId, dashboard: $dashboard, aiAssistant: $aiAssistant, attendance: $attendance, attendanceScan: $attendanceScan, timetable: $timetable, library: $library, canteen: $canteen, placement: $placement, events: $events, notice: $notice, digitalId: $digitalId, analytics: $analytics, campusMap: $campusMap, profile: $profile, settings: $settings, reports: $reports, departmentManagement: $departmentManagement, collegeManagement: $collegeManagement, studentManagement: $studentManagement, teacherManagement: $teacherManagement, hodManagement: $hodManagement, principalManagement: $principalManagement, userManagement: $userManagement, roleManagement: $roleManagement, permissionManagement: $permissionManagement)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionModel &&
        other.id == id && other.ownerId == ownerId && other.dashboard == dashboard && other.aiAssistant == aiAssistant && other.attendance == attendance && other.attendanceScan == attendanceScan && other.timetable == timetable && other.library == library && other.canteen == canteen && other.placement == placement && other.events == events && other.notice == notice && other.digitalId == digitalId && other.analytics == analytics && other.campusMap == campusMap && other.profile == profile && other.settings == settings && other.reports == reports && other.departmentManagement == departmentManagement && other.collegeManagement == collegeManagement && other.studentManagement == studentManagement && other.teacherManagement == teacherManagement && other.hodManagement == hodManagement && other.principalManagement == principalManagement && other.userManagement == userManagement && other.roleManagement == roleManagement && other.permissionManagement == permissionManagement;
  }

  // 👇 FIX: Used Object.hashAll to handle more than 20 arguments
  @override
  int get hashCode {
    return Object.hashAll([
      id, ownerId, dashboard, aiAssistant, attendance, attendanceScan, timetable, library, canteen, placement, events, notice, digitalId, analytics, campusMap, profile, settings, reports, departmentManagement, collegeManagement, studentManagement, teacherManagement, hodManagement, principalManagement, userManagement, roleManagement, permissionManagement
    ]);
  }
}