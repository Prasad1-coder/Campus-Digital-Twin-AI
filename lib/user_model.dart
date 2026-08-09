import 'dart:convert';
import 'user_role.dart';

/// Represents a user within the Campus Digital Twin AI system.
class UserModel {
  final String id;
  final String collegeId;
  final String fullName;
  final String email;
  final String password;
  final UserRole role;
  final String department;
  final String designation;
  final int? semester;
  final String? division;
  final String? rollNumber;
  final String phoneNumber;
  final String gender;
  final DateTime? dateOfBirth;
  final String? profileImageUrl;
  final String address;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.collegeId,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    required this.department,
    required this.designation,
    this.semester,
    this.division,
    this.rollNumber,
    required this.phoneNumber,
    required this.gender,
    this.dateOfBirth,
    this.profileImageUrl,
    required this.address,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? id,
    String? collegeId,
    String? fullName,
    String? email,
    String? password,
    UserRole? role,
    String? department,
    String? designation,
    int? semester,
    String? division,
    String? rollNumber,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    String? address,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      semester: semester ?? this.semester,
      division: division ?? this.division,
      rollNumber: rollNumber ?? this.rollNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collegeId': collegeId,
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role.toJson(),
      'department': department,
      'designation': designation,
      'semester': semester,
      'division': division,
      'rollNumber': rollNumber,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'address': address,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      collegeId: map['collegeId'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      password: map['password'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      department: map['department'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      semester: map['semester'] as int?,
      division: map['division'] as String?,
      rollNumber: map['rollNumber'] as String?,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.parse(map['dateOfBirth'] as String) : null,
      profileImageUrl: map['profileImageUrl'] as String?,
      address: map['address'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, collegeId: $collegeId, fullName: $fullName, email: $email, role: $role, department: $department, designation: $designation, semester: $semester, division: $division, rollNumber: $rollNumber, phoneNumber: $phoneNumber, gender: $gender, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.collegeId == collegeId &&
        other.fullName == fullName &&
        other.email == email &&
        other.password == password &&
        other.role == role &&
        other.department == department &&
        other.designation == designation &&
        other.semester == semester &&
        other.division == division &&
        other.rollNumber == rollNumber &&
        other.phoneNumber == phoneNumber &&
        other.gender == gender &&
        other.dateOfBirth == dateOfBirth &&
        other.profileImageUrl == profileImageUrl &&
        other.address == address &&
        other.isActive == isActive &&
        other.lastLogin == lastLogin &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id, collegeId, fullName, email, password, role, department, designation, semester, division, rollNumber, phoneNumber, gender, dateOfBirth, profileImageUrl, address, isActive, lastLogin, createdAt, updatedAt
    );
  }
}