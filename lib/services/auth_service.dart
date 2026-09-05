import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user_role.dart';
import '../user_model.dart';
import '../permission_model.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;
  final PermissionModel? permissions;

  const AuthResult({required this.success, this.errorMessage, this.user, this.permissions});
  factory AuthResult.success(UserModel user, PermissionModel permissions) => AuthResult(success: true, user: user, permissions: permissions);
  factory AuthResult.failure(String message) => AuthResult(success: false, errorMessage: message);
}

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
  Future<void> tryRestoreSession();
  void updateProfile(UserModel updatedUser);
}

class AuthService implements IAuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  PermissionModel? _currentPermissions;
  
  final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier(null);

  UserRole _getRoleFromId(String collegeId) {
    String id = collegeId.toUpperCase();
    if (id.startsWith("ST")) return UserRole.student;
    if (id.startsWith("FAC")) return UserRole.teacher;
    if (id.startsWith("HOD")) return UserRole.hod;
    if (id.startsWith("PRIN")) return UserRole.principal;
    return UserRole.student;
  }

  // 👇 FIX: Robust logic to fetch and parse data from Firestore safely
  Future<UserModel> _fetchUserData(User firebaseUser, String collegeId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Safely parse Timestamp to DateTime to avoid "bad element" crash
        DateTime createdAt = DateTime.now();
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          } else if (data['createdAt'] is String) {
            createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
          }
        }

        return UserModel(
          id: firebaseUser.uid,
          collegeId: data['collegeId'] ?? collegeId,
          fullName: data['fullName'] ?? "Campus User",
          email: data['email'] ?? firebaseUser.email ?? "",
          password: "",
          role: UserRole.fromString(data['role']?.toString()),
          department: data['department'] ?? "Administration",
          designation: data['designation'] ?? "User",
          phoneNumber: data['phoneNumber'] ?? "",
          gender: data['gender'] ?? "",
          address: data['address'] ?? "",
          isActive: data['isActive'] ?? true,
          createdAt: createdAt,
          updatedAt: DateTime.now(),
        );
      } else {
        // If document doesn't exist in Firestore, create a temporary fallback
        UserRole role = _getRoleFromId(collegeId);
        return UserModel(
          id: firebaseUser.uid,
          collegeId: collegeId,
          fullName: "Campus User",
          email: firebaseUser.email ?? "",
          password: "",
          role: role,
          department: "Administration",
          designation: role.name[0].toUpperCase() + role.name.substring(1),
          phoneNumber: "",
          gender: "",
          address: "",
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      print("❌ Firestore Fetch Error: $e");
      // Fallback on any error so app doesn't crash
      UserRole role = _getRoleFromId(collegeId);
      return UserModel(
        id: firebaseUser.uid,
        collegeId: collegeId,
        fullName: "Campus User",
        email: firebaseUser.email ?? "",
        password: "",
        role: role,
        department: "Administration",
        designation: role.name[0].toUpperCase() + role.name.substring(1),
        phoneNumber: "",
        gender: "",
        address: "",
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<AuthResult> login(String collegeId, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Convert College ID to Email format (e.g., ST2026001 -> ST2026001@campus.edu)
    String email = "${collegeId.toLowerCase()}@campus.edu";

    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      _currentUser = await _fetchUserData(
  userCredential.user!,
  collegeId.toUpperCase(),
);

_currentPermissions = switch (_currentUser!.role) {
  UserRole.student => PermissionModel.student(
      id: 'perm-${_currentUser!.id}',
      ownerId: _currentUser!.id,
    ),
  UserRole.teacher => PermissionModel.teacher(
      id: 'perm-${_currentUser!.id}',
      ownerId: _currentUser!.id,
    ),
  UserRole.hod => PermissionModel.hod(
      id: 'perm-${_currentUser!.id}',
      ownerId: _currentUser!.id,
    ),
  UserRole.principal => PermissionModel.principal(
      id: 'perm-${_currentUser!.id}',
      ownerId: _currentUser!.id,
    ),
};

currentUserNotifier.value = _currentUser;
      return AuthResult.success(_currentUser!, _currentPermissions!);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return AuthResult.failure("User not found. Check College ID.");
      } else if (e.code == 'wrong-password') {
        return AuthResult.failure("Incorrect password.");
      } else if (e.code == 'invalid-email') {
        return AuthResult.failure("Invalid College ID format.");
      }
      return AuthResult.failure("Login failed: ${e.message}");
    } catch (e) {
      return AuthResult.failure("An error occurred: $e");
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _currentPermissions = null;
    currentUserNotifier.value = null;
  }

  @override
Future<void> tryRestoreSession() async {
  User? firebaseUser = _firebaseAuth.currentUser;

  if (firebaseUser != null) {
    String email = firebaseUser.email ?? "";
    String collegeId = email.split("@").first.toUpperCase();

    _currentUser = await _fetchUserData(
      firebaseUser,
      collegeId,
    );

    _currentPermissions = switch (_currentUser!.role) {
      UserRole.student => PermissionModel.student(
          id: 'perm-${_currentUser!.id}',
          ownerId: _currentUser!.id,
        ),
      UserRole.teacher => PermissionModel.teacher(
          id: 'perm-${_currentUser!.id}',
          ownerId: _currentUser!.id,
        ),
      UserRole.hod => PermissionModel.hod(
          id: 'perm-${_currentUser!.id}',
          ownerId: _currentUser!.id,
        ),
      UserRole.principal => PermissionModel.principal(
          id: 'perm-${_currentUser!.id}',
          ownerId: _currentUser!.id,
        ),
    };

    currentUserNotifier.value = _currentUser;
  }
}

  @override
  UserModel? getCurrentUser() => _currentUser;

  @override
  UserRole? getCurrentRole() => _currentUser?.role;

  @override
  PermissionModel? getCurrentPermissions() => _currentPermissions;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  String? validateCollegeId(String? collegeId) {
    if (collegeId == null || collegeId.trim().isEmpty) return "College ID cannot be empty.";
    if (collegeId.trim().length < 3) return "College ID too short.";
    return null;
  }

  @override
  String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) return "Password cannot be empty.";
    if (password.trim().length < 6) return "Password must be 6+ characters.";
    return null;
  }

  @override
  bool hasPermission(String module, String action) {
    if (_currentPermissions == null) return false;
    switch (module.toLowerCase()) {
      case 'dashboard': return _currentPermissions!.dashboard.canView;
      case 'aiassistant': return _currentPermissions!.aiAssistant.canView;
      case 'attendance': return _currentPermissions!.attendance.canView;
      case 'attendanceScan': return _currentPermissions!.attendanceScan.canView;
      case 'timetable': return _currentPermissions!.timetable.canView;
      case 'library': return _currentPermissions!.library.canView;
      case 'canteen': return _currentPermissions!.canteen.canView;
      case 'placement': return _currentPermissions!.placement.canView;
      case 'events': return _currentPermissions!.events.canView;
      case 'notice': return _currentPermissions!.notice.canView;
      case 'digitalid': return _currentPermissions!.digitalId.canView;
      case 'analytics': return _currentPermissions!.analytics.canView;
      case 'campusmap': return _currentPermissions!.campusMap.canView;
      case 'profile': return _currentPermissions!.profile.canView;
      case 'settings': return _currentPermissions!.settings.canView;
      case 'reports': return _currentPermissions!.reports.canView;
      case 'studentmanagement': return _currentPermissions!.studentManagement.canView;
      default: return false;
    }
  }

  @override
  void updateProfile(UserModel updatedUser) {
    _currentUser = updatedUser;
    currentUserNotifier.value = updatedUser;
  }
}