/// ============================================================
///  Campus Digital Twin AI - User Role Management
///  Centralized Role-Based Access Control (RBAC) Enum
/// ============================================================

enum UserRole {
  student,
  teacher,
  hod,
  principal;

  /// Parses a [String] typically received from a backend API 
  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'teacher':
        return UserRole.teacher;
      case 'hod':
        return UserRole.hod;
      case 'principal':
        return UserRole.principal;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  /// Converts the [UserRole] enum back into a [String]
  String toJson() => name;
}