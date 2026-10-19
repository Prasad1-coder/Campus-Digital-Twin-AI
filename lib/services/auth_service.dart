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

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
    this.permissions,
  });

  factory AuthResult.success(
    UserModel user,
    PermissionModel permissions,
  ) {
    return AuthResult(
      success: true,
      user: user,
      permissions: permissions,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      errorMessage: message,
    );
  }
}

abstract class IAuthService {
  Future<AuthResult> login(
    String collegeId,
    String password,
  );

  Future<void> logout();

  UserModel? getCurrentUser();

  UserRole? getCurrentRole();

  PermissionModel? getCurrentPermissions();

  bool get isLoggedIn;

  String? validateCollegeId(String? collegeId);

  String? validatePassword(String? password);

  bool hasPermission(
    String module,
    String action,
  );

  Future<void> tryRestoreSession();

  void updateProfile(
    UserModel updatedUser,
  );
}

class AuthService implements IAuthService {
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  UserModel? _currentUser;

  PermissionModel? _currentPermissions;

  final ValueNotifier<UserModel?> currentUserNotifier =
      ValueNotifier<UserModel?>(null);

  // ============================================================
  // FIREBASE EMAIL FROM COLLEGE ID (FIXED)
  // ============================================================

  String _getFirebaseEmail(String collegeId) {
    final String id = collegeId.trim();

    // FIX: Agar user ne direct email daali hai, toh use hi use karo
    if (id.contains('@')) {
      return id.toLowerCase();
    }

    final String upperId = id.toUpperCase();

    // Current demo accounts
    if (upperId == 'PRIN001') {
      return 'principal@campus.edu';
    }

    if (upperId == 'HOD001') {
      return 'hod@campus.edu';
    }

    if (upperId == 'FAC001') {
      return 'teacher@campus.edu';
    }

    if (upperId == 'ST001') {
      return 'student@campus.edu';
    }

    // Generic accounts
    return '${id.toLowerCase()}@campus.edu';
  }

  // ============================================================
  // ROLE FROM COLLEGE ID (FIXED)
  // ============================================================

  UserRole? _getRoleFromId(String collegeId) {
    final String id = collegeId.trim().toUpperCase();

    if (id.startsWith('ST')) {
      return UserRole.student;
    }

    if (id.startsWith('FAC')) {
      return UserRole.teacher;
    }

    if (id.startsWith('HOD')) {
      return UserRole.hod;
    }

    if (id.startsWith('PRIN')) {
      return UserRole.principal;
    }

    // Agar direct email hai jisme prefix nahi hai, toh role null hoga, 
    // par login attempt nahi rokenge, Firestore role authoritative hoga.
    if (id.contains('@')) {
      return null; 
    }

    return null;
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDate(dynamic value) {
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

  // ============================================================
  // INTEGER PARSER
  // ============================================================

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  // ============================================================
  // FETCH USER DATA
  // ============================================================

  Future<UserModel> _fetchUserData(
    User firebaseUser,
    String collegeId,
  ) async {
    final DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    // Firestore profile is mandatory.
    if (!doc.exists) {
      throw Exception('USER_DOCUMENT_NOT_FOUND');
    }

    final Map<String, dynamic> data =
        doc.data() as Map<String, dynamic>;

    // ==========================================================
    // ROLE
    // ==========================================================

    final String firestoreRole =
        data['role']?.toString().trim().toLowerCase() ?? '';

    UserRole? role;

    switch (firestoreRole) {
      case 'student':
        role = UserRole.student;
        break;

      case 'teacher':
      case 'faculty':
        role = UserRole.teacher;
        break;

      case 'hod':
        role = UserRole.hod;
        break;

      case 'principal':
        role = UserRole.principal;
        break;

      default:
        throw Exception('INVALID_USER_ROLE');
    }

    // ==========================================================
    // DATES
    // ==========================================================

    final DateTime createdAt =
        _parseDate(data['createdAt']) ??
            DateTime.now();

    final DateTime updatedAt =
        _parseDate(data['updatedAt']) ??
            DateTime.now();

    final DateTime? lastLogin =
        _parseDate(data['lastLogin']);

    final DateTime? dateOfBirth =
        _parseDate(data['dateOfBirth']);

    // ==========================================================
    // ACTIVE STATUS
    // ==========================================================

    final bool isActive =
        data['isActive'] is bool
            ? data['isActive'] as bool
            : true;

    // ==========================================================
    // USER MODEL
    // ==========================================================

    return UserModel(
      id: firebaseUser.uid,

      collegeId:
          data['collegeId']?.toString() ??
              collegeId,

      fullName:
          data['fullName']?.toString() ??
              'Campus User',

      email:
          data['email']?.toString() ??
              firebaseUser.email ??
              '',

      // Password is managed only by Firebase Authentication.
      password: '',

      role: role,

      department:
          data['department']?.toString() ??
              '',

      designation:
          data['designation']?.toString() ??
              '',

      program:
          data['program']?.toString() ??
              '',

      classId:
          data['classId']?.toString() ??
              '',

      className:
          data['className']?.toString() ??
              '',

      academicYearId:
          data['academicYearId']?.toString() ??
              '',

      academicYear:
          data['academicYear']?.toString() ??
              '',

      semester:
          _parseInt(data['semester']),

      division:
          data['division']?.toString(),

      rollNumber:
          data['rollNumber']?.toString(),

      phoneNumber:
          data['phoneNumber']?.toString() ??
              '',

      gender:
          data['gender']?.toString() ??
              '',

      dateOfBirth:
          dateOfBirth,

      profileImageUrl:
          data['profileImageUrl']?.toString(),

      address:
          data['address']?.toString() ??
              '',

      isActive:
          isActive,

      lastLogin:
          lastLogin,

      createdAt:
          createdAt,

      updatedAt:
          updatedAt,
    );
  }

  // ============================================================
  // BUILD PERMISSIONS
  // ============================================================

  PermissionModel _buildPermissions(
    UserModel user,
  ) {
    switch (user.role) {
      case UserRole.student:
        return PermissionModel.student(
          id: 'perm-${user.id}',
          ownerId: user.id,
        );

      case UserRole.teacher:
        return PermissionModel.teacher(
          id: 'perm-${user.id}',
          ownerId: user.id,
        );

      case UserRole.hod:
        return PermissionModel.hod(
          id: 'perm-${user.id}',
          ownerId: user.id,
        );

      case UserRole.principal:
        return PermissionModel.principal(
          id: 'perm-${user.id}',
          ownerId: user.id,
        );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  @override
  Future<AuthResult> login(
    String collegeId,
    String password,
  ) async {
    final String cleanCollegeId =
        collegeId.trim();

    final String cleanPassword =
        password.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    final String? idError =
        validateCollegeId(cleanCollegeId);

    if (idError != null) {
      return AuthResult.failure(idError);
    }

    final String? passwordError =
        validatePassword(cleanPassword);

    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    // ----------------------------------------------------------
    // VALIDATE COLLEGE ID PREFIX (Skip if direct email)
    // ----------------------------------------------------------

    final UserRole? expectedRole =
        _getRoleFromId(cleanCollegeId);

    if (expectedRole == null && !cleanCollegeId.contains('@')) {
      return AuthResult.failure(
        'Invalid College ID. Please enter a valid college ID or email.',
      );
    }

    // ----------------------------------------------------------
    // COLLEGE ID -> FIREBASE EMAIL
    // ----------------------------------------------------------

    final String email =
        _getFirebaseEmail(cleanCollegeId);

    debugPrint(
      '========================================',
    );

    debugPrint(
      'LOGIN ATTEMPT',
    );

    debugPrint(
      'Input ID: $cleanCollegeId',
    );

    debugPrint(
      'Firebase Email: $email',
    );

    debugPrint(
      '========================================',
    );

    try {
      // ========================================================
      // FIREBASE AUTHENTICATION
      // ========================================================

      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: cleanPassword,
      );

      final User? firebaseUser =
          userCredential.user;

      if (firebaseUser == null) {
        return AuthResult.failure(
          'Unable to identify Firebase user.',
        );
      }

      debugPrint(
        '✅ Firebase Authentication successful',
      );

      debugPrint(
        'Firebase UID: ${firebaseUser.uid}',
      );

      // ========================================================
      // FIRESTORE USER PROFILE
      // ========================================================

      try {
        _currentUser = await _fetchUserData(
          firebaseUser,
          cleanCollegeId.toUpperCase(),
        );
      } catch (e) {
        debugPrint(
          '❌ Firestore profile error: $e',
        );

        await _firebaseAuth.signOut();

        _currentUser = null;
        _currentPermissions = null;
        currentUserNotifier.value = null;

        if (e.toString().contains(
              'USER_DOCUMENT_NOT_FOUND',
            )) {
          return AuthResult.failure(
            'Firebase login successful, but your college profile is not configured. Please contact the administrator.',
          );
        }

        if (e.toString().contains(
              'INVALID_USER_ROLE',
            )) {
          return AuthResult.failure(
            'Invalid role configuration. Please contact the administrator.',
          );
        }

        return AuthResult.failure(
          'Unable to load your college profile.',
        );
      }

      // ========================================================
      // ACTIVE STATUS
      // ========================================================

      if (!_currentUser!.isActive) {
        await _firebaseAuth.signOut();

        _currentUser = null;
        _currentPermissions = null;
        currentUserNotifier.value = null;

        return AuthResult.failure(
          'Your account is inactive. Please contact the college administration.',
        );
      }

      // ========================================================
      // VERIFY ROLE (Only if prefix was used, otherwise Firestore is authoritative)
      // ========================================================

      if (expectedRole != null && _currentUser!.role != expectedRole) {
        debugPrint(
          '❌ Role mismatch',
        );

        debugPrint(
          'Expected: $expectedRole',
        );

        debugPrint(
          'Firestore: ${_currentUser!.role}',
        );

        await _firebaseAuth.signOut();

        _currentUser = null;
        _currentPermissions = null;
        currentUserNotifier.value = null;

        return AuthResult.failure(
          'Role configuration does not match this College ID.',
        );
      }

      // ========================================================
      // BUILD PERMISSIONS
      // ========================================================

      _currentPermissions =
          _buildPermissions(_currentUser!);

      currentUserNotifier.value =
          _currentUser;

      // ========================================================
      // SUCCESS LOG
      // ========================================================

      debugPrint(
        '========================================',
      );

      debugPrint(
        '✅ LOGIN SUCCESSFUL',
      );

      debugPrint(
        'Name: ${_currentUser!.fullName}',
      );

      debugPrint(
        'College ID: ${_currentUser!.collegeId}',
      );

      debugPrint(
        'Role: ${_currentUser!.role}',
      );

      debugPrint(
        'Department: ${_currentUser!.department}',
      );

      debugPrint(
        '========================================',
      );

      return AuthResult.success(
        _currentUser!,
        _currentPermissions!,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '❌ Firebase Auth Error Code: ${e.code}',
      );

      debugPrint(
        'Firebase Auth Error Message: ${e.message}',
      );

      switch (e.code) {
        case 'user-not-found':
          return AuthResult.failure(
            'College ID is not registered.',
          );

        case 'wrong-password':
          return AuthResult.failure(
            'Incorrect password.',
          );

        case 'invalid-credential':
          return AuthResult.failure(
            'Invalid College ID or password.',
          );

        case 'invalid-email':
          return AuthResult.failure(
            'Invalid College ID format.',
          );

        case 'user-disabled':
          return AuthResult.failure(
            'This Firebase account has been disabled.',
          );

        case 'too-many-requests':
          return AuthResult.failure(
            'Too many login attempts. Please try again later.',
          );

        case 'network-request-failed':
          return AuthResult.failure(
            'Network error. Please check your internet connection.',
          );

        case 'operation-not-allowed':
          return AuthResult.failure(
            'Email/password authentication is not enabled in Firebase.',
          );

        default:
          return AuthResult.failure(
            'Login failed. Please check your College ID and password.',
          );
      }
    } catch (e) {
      debugPrint(
        '❌ Login Error: $e',
      );

      return AuthResult.failure(
        'Unable to login. Please try again.',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();

    _currentUser = null;

    _currentPermissions = null;

    currentUserNotifier.value = null;
  }

  // ============================================================
  // RESTORE SESSION
  // ============================================================

  @override
  Future<void> tryRestoreSession() async {
    final User? firebaseUser =
        _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      return;
    }

    final String email =
        firebaseUser.email ?? '';

    final String collegeId =
        email.split('@').first.toUpperCase();

    try {
      _currentUser =
          await _fetchUserData(
        firebaseUser,
        collegeId,
      );

      if (!_currentUser!.isActive) {
        await logout();
        return;
      }

      _currentPermissions =
          _buildPermissions(_currentUser!);

      currentUserNotifier.value =
          _currentUser;

      debugPrint(
        '✅ Session restored',
      );

      debugPrint(
        'College ID: ${_currentUser!.collegeId}',
      );

      debugPrint(
        'Role: ${_currentUser!.role}',
      );
    } catch (e) {
      debugPrint(
        '❌ Session restore failed: $e',
      );

      await logout();
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  @override
  UserModel? getCurrentUser() {
    return _currentUser;
  }

  // ============================================================
  // CURRENT ROLE
  // ============================================================

  @override
  UserRole? getCurrentRole() {
    return _currentUser?.role;
  }

  // ============================================================
  // CURRENT PERMISSIONS
  // ============================================================

  @override
  PermissionModel? getCurrentPermissions() {
    return _currentPermissions;
  }

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  @override
  bool get isLoggedIn {
    return _currentUser != null;
  }

  // ============================================================
  // COLLEGE ID VALIDATION
  // ============================================================

  @override
  String? validateCollegeId(
    String? collegeId,
  ) {
    if (collegeId == null ||
        collegeId.trim().isEmpty) {
      return 'College ID cannot be empty.';
    }

    if (collegeId.trim().length < 4) {
      return 'College ID too short.';
    }

    return null;
  }

  // ============================================================
  // PASSWORD VALIDATION
  // ============================================================

  @override
  String? validatePassword(
    String? password,
  ) {
    if (password == null ||
        password.trim().isEmpty) {
      return 'Password cannot be empty.';
    }

    if (password.trim().length < 6) {
      return 'Password must be 6+ characters.';
    }

    return null;
  }

  // ============================================================
  // PERMISSION CHECK (PRIORITY 1 FIXED)
  // ============================================================

  @override
  bool hasPermission(
    String module,
    String action,
  ) {
    if (_currentPermissions == null) {
      return false;
    }

    final String m = module.toLowerCase();
    final String a = action.toLowerCase();

    // Helper function to check the specific action on a permission object
    bool checkAction(dynamic perm) {
      if (perm == null) return false;
      switch (a) {
        case 'canview':
          return perm.canView == true;
        case 'cancreate':
          return perm.canCreate == true;
        case 'canedit':
          return perm.canEdit == true;
        case 'candelete':
          return perm.canDelete == true;
        case 'canapprove':
          return perm.canApprove == true;
        case 'canexport':
          return perm.canExport == true;
        case 'canmanage':
          return perm.canManage == true;
        default:
          return false; // Unknown action fails closed
      }
    }

    switch (m) {
      case 'dashboard':
        return checkAction(_currentPermissions!.dashboard);
      case 'aiassistant':
        return checkAction(_currentPermissions!.aiAssistant);
      case 'attendance':
        return checkAction(_currentPermissions!.attendance);
      case 'attendancescan':
        return checkAction(_currentPermissions!.attendanceScan);
      case 'timetable':
        return checkAction(_currentPermissions!.timetable);
      case 'library':
        return checkAction(_currentPermissions!.library);
      case 'canteen':
        return checkAction(_currentPermissions!.canteen);
      case 'placement':
        return checkAction(_currentPermissions!.placement);
      case 'events':
        return checkAction(_currentPermissions!.events);
      case 'notice':
        return checkAction(_currentPermissions!.notice);
      case 'digitalid':
        return checkAction(_currentPermissions!.digitalId);
      case 'analytics':
        return checkAction(_currentPermissions!.analytics);
      case 'campusmap':
        return checkAction(_currentPermissions!.campusMap);
      case 'profile':
        return checkAction(_currentPermissions!.profile);
      case 'settings':
        return checkAction(_currentPermissions!.settings);
      case 'reports':
        return checkAction(_currentPermissions!.reports);
      case 'studentmanagement':
        return checkAction(_currentPermissions!.studentManagement);
      default:
        return false; // Unknown module fails closed
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  @override
  void updateProfile(
    UserModel updatedUser,
  ) {
    _currentUser = updatedUser;

    currentUserNotifier.value =
        updatedUser;
  }
}