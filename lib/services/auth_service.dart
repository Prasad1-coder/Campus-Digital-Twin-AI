import '../user_role.dart';
import '../user_model.dart';
import '../permission_model.dart';
import '../dummy_users.dart';

/// ============================================================
///  Campus Digital Twin AI - Authentication Service
///  Clean Architecture & SOLID Principles
/// ============================================================
///
///  Provides a centralized authentication contract. The UI interacts
///  solely with this abstraction, allowing the underlying implementation
///  to be swapped between Dummy Data, Firebase, REST API, or Supabase
///  without any UI changes.
///
/// ============================================================

/// Represents the outcome of an authentication attempt.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;
  final PermissionModel? permissions;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
    this.permissions,
  });

  /// Factory for successful login.
  factory AuthResult.success(UserModel user, PermissionModel permissions) {
    return AuthResult(
      success: true,
      user: user,
      permissions: permissions,
    );
  }

  /// Factory for failed login.
  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Abstract interface for Authentication Services.
///
/// Implement this interface to create a new authentication backend
/// (e.g., FirebaseAuthService, ApiAuthService, SupabaseAuthService).
abstract class IAuthService {
  Future<AuthResult> login(String collegeId, String password);
  Future<void> logout();
  UserModel? getCurrentUser();
  UserRole? getCurrentRole();
  PermissionModel? getCurrentPermissions();
  bool get isLoggedIn;
  String? validateCollegeId(String? collegeId);
  String? validatePassword(String? password);
  bool hasPermission(String module, String action);
}

/// ============================================================
///  Dummy Authentication Service Implementation
/// ============================================================

/// A concrete implementation of [IAuthService] that uses the
/// [DummyUserRepository] to simulate backend authentication.
///
/// This is intended for local development and prototyping.
class AuthService implements IAuthService {
  // Singleton pattern for easy access across the app without DI frameworks.
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // In-memory session storage.
  // In a production environment, this would be backed by SecureStorage
  // and SharedPreferences for session persistence.
  UserModel? _currentUser;
  PermissionModel? _currentPermissions;

  /// Authenticates a user based on College ID and Password.
  ///
  /// Flow:
  /// 1. Validate inputs.
  /// 2. Find user by College ID.
  /// 3. Verify password.
  /// 4. Check active status.
  /// 5. Load permissions.
  /// 6. Return [AuthResult].
  @override
  Future<AuthResult> login(String collegeId, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // 1. Validate Inputs
    final idError = validateCollegeId(collegeId);
    if (idError != null) return AuthResult.failure(idError);

    final passError = validatePassword(password);
    if (passError != null) return AuthResult.failure(passError);

    // 2. Find User
    final user = DummyUserRepository.instance.findByCollegeId(collegeId);
    if (user == null) {
      return AuthResult.failure("User not found. Please check your College ID.");
    }

    // 3. Verify Password
    if (user.password != password) {
      return AuthResult.failure("Incorrect password. Please try again.");
    }

    // 4. Check Active Status
    if (!user.isActive) {
      return AuthResult.failure("Your account has been deactivated. Please contact administration.");
    }

    // 5. Load Permissions
    final permissions = DummyUserRepository.instance.getPermissionsForUser(user.id);

    // 6. Establish Session
    _currentUser = user;
    _currentPermissions = permissions;

    return AuthResult.success(user, permissions);
  }

  /// Clears the current session.
  @override
  Future<void> logout() async {
    // Simulate network delay for clearing session/token revocation
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _currentPermissions = null;
  }

  /// Returns the currently logged-in [UserModel], or null if not logged in.
  @override
  UserModel? getCurrentUser() => _currentUser;

  /// Returns the [UserRole] of the currently logged-in user, or null.
  @override
  UserRole? getCurrentRole() => _currentUser?.role;

  /// Returns the [PermissionModel] for the current session, or null.
  @override
  PermissionModel? getCurrentPermissions() => _currentPermissions;

  /// Returns true if a user is currently authenticated.
  @override
  bool get isLoggedIn => _currentUser != null;

  /// Validates the College ID format before attempting login.
  @override
  String? validateCollegeId(String? collegeId) {
    if (collegeId == null || collegeId.trim().isEmpty) {
      return "College ID cannot be empty.";
    }
    if (collegeId.trim().length < 3) {
      return "College ID seems too short.";
    }
    return null; // Null means valid
  }

  /// Validates the Password format before attempting login.
  @override
  String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return "Password cannot be empty.";
    }
    if (password.trim().length < 6) {
      return "Password must be at least 6 characters.";
    }
    return null; // Null means valid
  }

  /// Checks if the current user has a specific permission.
  ///
  /// [module] corresponds to the module name (e.g., 'attendance', 'library').
  /// [action] corresponds to the action (e.g., 'canView', 'canEdit').
  @override
  bool hasPermission(String module, String action) {
    if (_currentPermissions == null) return false;

    ActionPermissions? targetModule;
    switch (module.toLowerCase()) {
      case 'dashboard':
        targetModule = _currentPermissions!.dashboard;
        break;
      case 'aiassistant':
      case 'ai':
        targetModule = _currentPermissions!.aiAssistant;
        break;
      case 'attendance':
        targetModule = _currentPermissions!.attendance;
        break;
      case 'attendancescan':
        targetModule = _currentPermissions!.attendanceScan;
        break;
      case 'timetable':
        targetModule = _currentPermissions!.timetable;
        break;
      case 'library':
        targetModule = _currentPermissions!.library;
        break;
      case 'canteen':
        targetModule = _currentPermissions!.canteen;
        break;
      case 'placement':
        targetModule = _currentPermissions!.placement;
        break;
      case 'events':
        targetModule = _currentPermissions!.events;
        break;
      case 'notice':
        targetModule = _currentPermissions!.notice;
        break;
      case 'digitalid':
        targetModule = _currentPermissions!.digitalId;
        break;
      case 'analytics':
        targetModule = _currentPermissions!.analytics;
        break;
      case 'campusmap':
      case 'map':
        targetModule = _currentPermissions!.campusMap;
        break;
      case 'profile':
        targetModule = _currentPermissions!.profile;
        break;
      case 'settings':
        targetModule = _currentPermissions!.settings;
        break;
      case 'reports':
        targetModule = _currentPermissions!.reports;
        break;
      case 'departmentmanagement':
        targetModule = _currentPermissions!.departmentManagement;
        break;
      case 'collegemanagement':
        targetModule = _currentPermissions!.collegeManagement;
        break;
      case 'studentmanagement':
        targetModule = _currentPermissions!.studentManagement;
        break;
      case 'teachermanagement':
        targetModule = _currentPermissions!.teacherManagement;
        break;
      case 'hodmanagement':
        targetModule = _currentPermissions!.hodManagement;
        break;
      case 'principalmanagement':
        targetModule = _currentPermissions!.principalManagement;
        break;
      case 'usermanagement':
        targetModule = _currentPermissions!.userManagement;
        break;
      case 'rolemanagement':
        targetModule = _currentPermissions!.roleManagement;
        break;
      case 'permissionmanagement':
        targetModule = _currentPermissions!.permissionManagement;
        break;
      default:
        return false; // Module not found
    }

    switch (action.toLowerCase()) {
      case 'canview':
      case 'view':
        return targetModule.canView;
      case 'cancreate':
      case 'create':
        return targetModule.canCreate;
      case 'canedit':
      case 'edit':
        return targetModule.canEdit;
      case 'candelete':
      case 'delete':
        return targetModule.canDelete;
      case 'canapprove':
      case 'approve':
        return targetModule.canApprove;
      case 'canexport':
      case 'export':
        return targetModule.canExport;
      case 'canmanage':
      case 'manage':
        return targetModule.canManage;
      default:
        return false; // Action not found
    }
  }
}