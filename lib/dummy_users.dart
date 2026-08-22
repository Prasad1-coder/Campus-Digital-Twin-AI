import 'user_role.dart';
import 'user_model.dart';
import 'permission_model.dart';

/// ============================================================
///  Campus Digital Twin AI - Dummy User Repository
///  Simulates a backend database for local development and testing.
///  Compatible with future Firebase, REST API, and Supabase migrations.
/// ============================================================

/// A centralized repository that simulates a backend database.
/// 
/// This class holds dummy users and their associated permissions.
/// It provides helper methods to query users by various criteria,
/// mimicking the behavior of a real backend API or database ORM.
class DummyUserRepository {
  DummyUserRepository._internal();
  
  /// Singleton instance for easy access across the app.
  static final DummyUserRepository instance = DummyUserRepository._internal();

  /// Internal list of dummy users acting as the database table.
  final List<UserModel> _users = [
    // ----------------------- PRINCIPAL -----------------------
    UserModel(
      id: 'uuid-principal-01',
      collegeId: 'PRIN001',
      fullName: 'Dr. Suresh Nair',
      email: 'principal@campus.edu',
      password: '123456',
      role: UserRole.principal,
      department: 'Administration',
      designation: 'Principal',
      phoneNumber: '+919876543210',
      gender: 'Male',
      dateOfBirth: DateTime(1975, 5, 12),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'Campus Quarters, Block A',
      isActive: true,
      createdAt: DateTime(2020, 1, 1),
      updatedAt: DateTime(2023, 10, 15),
    ),

    // ----------------------- HODs -----------------------
    UserModel(
      id: 'uuid-hod-cs-01',
      collegeId: 'HODCS01',
      fullName: 'Dr. Anand Joshi',
      email: 'hod.cs@campus.edu',
      password: '123456',
      role: UserRole.hod,
      department: 'Computer Science',
      designation: 'Head of Department',
      phoneNumber: '+919876543211',
      gender: 'Male',
      dateOfBirth: DateTime(1980, 3, 22),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'Campus Quarters, Block B',
      isActive: true,
      createdAt: DateTime(2020, 2, 1),
      updatedAt: DateTime(2023, 9, 15),
    ),
    UserModel(
      id: 'uuid-hod-chem-01',
      collegeId: 'HODCH01',
      fullName: 'Dr. Kavita Deshmukh',
      email: 'hod.chem@campus.edu',
      password: '123456',
      role: UserRole.hod,
      department: 'Chemistry',
      designation: 'Head of Department',
      phoneNumber: '+919876543212',
      gender: 'Female',
      dateOfBirth: DateTime(1982, 7, 18),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'Campus Quarters, Block B',
      isActive: true,
      createdAt: DateTime(2020, 2, 5),
      updatedAt: DateTime(2023, 9, 15),
    ),
    UserModel(
      id: 'uuid-hod-phy-01',
      collegeId: 'HODPH01',
      fullName: 'Dr. Rohan Verma',
      email: 'hod.phy@campus.edu',
      password: '123456',
      role: UserRole.hod,
      department: 'Physics',
      designation: 'Head of Department',
      phoneNumber: '+919876543213',
      gender: 'Male',
      dateOfBirth: DateTime(1978, 11, 2),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'Campus Quarters, Block B',
      isActive: true,
      createdAt: DateTime(2020, 2, 10),
      updatedAt: DateTime(2023, 9, 15),
    ),

    // ----------------------- TEACHERS -----------------------
    UserModel(
      id: 'uuid-teach-cs-01',
      collegeId: 'FACCS101',
      fullName: 'Dr. Rajesh Sharma',
      email: 'rajesh.sharma@campus.edu',
      password: '123456',
      role: UserRole.teacher,
      department: 'Computer Science',
      designation: 'Assistant Professor',
      phoneNumber: '+919876543214',
      gender: 'Male',
      dateOfBirth: DateTime(1985, 2, 14),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'City Center, Flat 302',
      isActive: true,
      createdAt: DateTime(2021, 1, 15),
      updatedAt: DateTime(2023, 8, 20),
    ),
    UserModel(
      id: 'uuid-teach-chem-01',
      collegeId: 'FACCH101',
      fullName: 'Dr. Sunita Rao',
      email: 'sunita.rao@campus.edu',
      password: '123456',
      role: UserRole.teacher,
      department: 'Chemistry',
      designation: 'Associate Professor',
      phoneNumber: '+919876543215',
      gender: 'Female',
      dateOfBirth: DateTime(1986, 6, 25),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'City Center, Flat 405',
      isActive: true,
      createdAt: DateTime(2021, 2, 20),
      updatedAt: DateTime(2023, 8, 20),
    ),
    UserModel(
      id: 'uuid-teach-phy-01',
      collegeId: 'FACPH101',
      fullName: 'Prof. Vikram Singh',
      email: 'vikram.singh@campus.edu',
      password: '123456',
      role: UserRole.teacher,
      department: 'Physics',
      designation: 'Assistant Professor',
      phoneNumber: '+919876543216',
      gender: 'Male',
      dateOfBirth: DateTime(1988, 9, 10),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'City Center, Flat 101',
      isActive: true,
      createdAt: DateTime(2021, 3, 5),
      updatedAt: DateTime(2023, 8, 20),
    ),

    // ----------------------- STUDENTS -----------------------
    UserModel(
      id: 'uuid-stu-cs-01',
      collegeId: 'ST2026001',
      fullName: 'Prasad Patil',
      email: 'prasad@campus.edu',
      password: '123456',
      role: UserRole.student,
      department: 'Computer Science',
      designation: 'Student',
      semester: 6,
      division: 'A',
      rollNumber: 'CS01',
      phoneNumber: '+919876543217',
      gender: 'Male',
      dateOfBirth: DateTime(2002, 1, 15),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'Hostel Block C, Room 12',
      isActive: true,
      createdAt: DateTime(2022, 8, 1),
      updatedAt: DateTime(2023, 10, 1),
    ),
    UserModel(
      id: 'uuid-stu-chem-01',
      collegeId: 'ST2026002',
      fullName: 'Riya Mehta',
      email: 'riya@campus.edu',
      password: '123456',
      role: UserRole.student,
      department: 'Chemistry',
      designation: 'Student',
      semester: 4,
      division: 'B',
      rollNumber: 'CH01',
      phoneNumber: '+919876543218',
      gender: 'Female',
      dateOfBirth: DateTime(2003, 4, 22),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'Hostel Block D, Room 8',
      isActive: true,
      createdAt: DateTime(2022, 8, 2),
      updatedAt: DateTime(2023, 10, 1),
    ),
    UserModel(
      id: 'uuid-stu-phy-01',
      collegeId: 'ST2026003',
      fullName: 'Amit Kumar',
      email: 'amit@campus.edu',
      password: '123456',
      role: UserRole.student,
      department: 'Physics',
      designation: 'Student',
      semester: 2,
      division: 'A',
      rollNumber: 'PH01',
      phoneNumber: '+919876543219',
      gender: 'Male',
      dateOfBirth: DateTime(2004, 8, 18),
      profileImageUrl: null, // 👈 FIX: Set to null
      address: 'Hostel Block C, Room 15',
      isActive: true,
      createdAt: DateTime(2022, 8, 3),
      updatedAt: DateTime(2023, 10, 1),
    ),
  ];

  /// Internal map linking user IDs to their specific permission models.
  final Map<String, PermissionModel> _userPermissions = {
    'uuid-principal-01': PermissionModel.principal(id: 'perm-principal-01', ownerId: 'uuid-principal-01'),
    'uuid-hod-cs-01': PermissionModel.hod(id: 'perm-hod-cs-01', ownerId: 'uuid-hod-cs-01'),
    'uuid-hod-chem-01': PermissionModel.hod(id: 'perm-hod-chem-01', ownerId: 'uuid-hod-chem-01'),
    'uuid-hod-phy-01': PermissionModel.hod(id: 'perm-hod-phy-01', ownerId: 'uuid-hod-phy-01'),
    'uuid-teach-cs-01': PermissionModel.teacher(id: 'perm-teach-cs-01', ownerId: 'uuid-teach-cs-01'),
    'uuid-teach-chem-01': PermissionModel.teacher(id: 'perm-teach-chem-01', ownerId: 'uuid-teach-chem-01'),
    'uuid-teach-phy-01': PermissionModel.teacher(id: 'perm-teach-phy-01', ownerId: 'uuid-teach-phy-01'),
    'uuid-stu-cs-01': PermissionModel.student(id: 'perm-stu-cs-01', ownerId: 'uuid-stu-cs-01'),
    'uuid-stu-chem-01': PermissionModel.student(id: 'perm-stu-chem-01', ownerId: 'uuid-stu-chem-01'),
    'uuid-stu-phy-01': PermissionModel.student(id: 'perm-stu-phy-01', ownerId: 'uuid-stu-phy-01'),
  };

  /// Retrieves all users.
  List<UserModel> get all => List.unmodifiable(_users);

  /// Finds a user by their College ID or Employee ID.
  UserModel? findByCollegeId(String collegeId) {
    try {
      return _users.firstWhere((user) => user.collegeId.toLowerCase() == collegeId.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  /// Finds a user by their Email Address.
  UserModel? findByEmail(String email) {
    try {
      return _users.firstWhere((user) => user.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  /// Authenticates a user using College ID and Password.
  /// 
  /// Returns the [UserModel] if authentication is successful, otherwise null.
  /// In a real backend, this would verify hashed passwords and return a JWT.
  UserModel? login(String collegeId, String password) {
    try {
      final user = _users.firstWhere(
        (user) => user.collegeId.toLowerCase() == collegeId.toLowerCase() && user.password == password,
      );
      return user.isActive ? user : null;
    } catch (e) {
      return null;
    }
  }

  /// Finds all users belonging to a specific [UserRole].
  List<UserModel> findByRole(UserRole role) {
    return _users.where((user) => user.role == role).toList();
  }

  /// Finds all users belonging to a specific department.
  List<UserModel> findByDepartment(String department) {
    return _users
        .where((user) => user.department.toLowerCase() == department.toLowerCase())
        .toList();
  }

  /// Retrieves all students.
  List<UserModel> get students => findByRole(UserRole.student);

  /// Retrieves all teachers.
  List<UserModel> get teachers => findByRole(UserRole.teacher);

  /// Retrieves all HODs.
  List<UserModel> get hods => findByRole(UserRole.hod);

  /// Retrieves the Principal.
  UserModel? get principal {
    try {
      return _users.firstWhere((user) => user.role == UserRole.principal);
    } catch (e) {
      return null;
    }
  }

  /// Retrieves the [PermissionModel] for a specific user ID.
  /// 
  /// Falls back to generating a default permission set based on the user's role
  /// if explicit permissions are not found in the repository.
  PermissionModel getPermissionsForUser(String userId) {
    final permission = _userPermissions[userId];
    if (permission != null) {
      return permission;
    }

    // Fallback logic based on role
    final user = _users.firstWhere((u) => u.id == userId);
    switch (user.role) {
      case UserRole.student:
        return PermissionModel.student(id: 'fallback-$userId', ownerId: userId);
      case UserRole.teacher:
        return PermissionModel.teacher(id: 'fallback-$userId', ownerId: userId);
      case UserRole.hod:
        return PermissionModel.hod(id: 'fallback-$userId', ownerId: userId);
      case UserRole.principal:
        return PermissionModel.principal(id: 'fallback-$userId', ownerId: userId);
    }
  }
}