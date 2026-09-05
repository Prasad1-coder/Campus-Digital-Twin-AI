import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'user_model.dart';
import 'user_role.dart';
import 'services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  File? _profileImage;

  bool _isSaving = false;
  bool _twoFactorEnabled = false;

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _textDark = Color(0xFF1A237E);

  // ============================================================
  // ROLE BASED SECURITY
  // ============================================================

  bool get _isStudent {
    return widget.user.role == UserRole.student;
  }

  bool get _canEditContact {
    return widget.user.role == UserRole.hod ||
        widget.user.role == UserRole.principal;
  }

  bool get _canEditName {
    return widget.user.role != UserRole.student;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.user.fullName,
    );

    _emailController = TextEditingController(
      text: widget.user.email,
    );

    _phoneController = TextEditingController(
      text: widget.user.phoneNumber,
    );

    _bioController = TextEditingController(
      text: "Update your bio here...",
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  // ============================================================
  // PICK PROFILE IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          _profileImage = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to select image: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = AuthService();

      final currentUser = authService.getCurrentUser();

      if (currentUser == null) {
        throw Exception(
          "User session not found.",
        );
      }

      // --------------------------------------------------------
      // VALIDATION
      // --------------------------------------------------------

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      if (_canEditName && name.isEmpty) {
        throw Exception(
          "Full name cannot be empty.",
        );
      }

      if (_canEditContact && email.isEmpty) {
        throw Exception(
          "Email address cannot be empty.",
        );
      }

      // --------------------------------------------------------
      // UPLOAD PROFILE IMAGE
      // --------------------------------------------------------

      String? profileImageUrl =
          currentUser.profileImageUrl;

      if (_profileImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${currentUser.id}.jpg');

        await storageRef.putFile(
          _profileImage!,
        );

        profileImageUrl =
            await storageRef.getDownloadURL();
      }

      // --------------------------------------------------------
      // CREATE UPDATED USER
      // --------------------------------------------------------

      final updatedUser = UserModel(
        id: currentUser.id,

        collegeId: currentUser.collegeId,

        fullName: _canEditName
            ? name
            : currentUser.fullName,

        email: _canEditContact
            ? email
            : currentUser.email,

        password: currentUser.password,

        role: currentUser.role,

        department: currentUser.department,

        designation: currentUser.designation,

        phoneNumber: _canEditContact
            ? phone
            : currentUser.phoneNumber,

        gender: currentUser.gender,

        address: currentUser.address,

        isActive: currentUser.isActive,

        // Updated image URL
        profileImageUrl: profileImageUrl,

        rollNumber: currentUser.rollNumber,

        semester: currentUser.semester,

        createdAt: currentUser.createdAt,

        updatedAt: DateTime.now(),
      );

      // --------------------------------------------------------
      // FIRESTORE UPDATE
      // --------------------------------------------------------

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .set(
        {
          'collegeId': updatedUser.collegeId,

          'fullName': updatedUser.fullName,

          'email': updatedUser.email,

          'role': updatedUser.role.toJson(),

          'department': updatedUser.department,

          'designation': updatedUser.designation,

          'phoneNumber': updatedUser.phoneNumber,

          'gender': updatedUser.gender,

          'address': updatedUser.address,

          'isActive': updatedUser.isActive,

          // Save Firebase Storage URL
          'profileImageUrl':
              updatedUser.profileImageUrl,

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // --------------------------------------------------------
      // UPDATE AUTH SERVICE
      // --------------------------------------------------------

      authService.updateProfile(
        updatedUser,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      // --------------------------------------------------------
      // SUCCESS MESSAGE
      // --------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Profile Updated Successfully! ✅",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // --------------------------------------------------------
      // GO BACK
      // --------------------------------------------------------

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to update profile: $e",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryDark,
                _primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),

        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _isSaving
                ? null
                : _saveProfile,
            tooltip: "Save",
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [

            // ==================================================
            // PROFILE IMAGE
            // ==================================================

            GestureDetector(
              onTap: _pickImage,

              child: Stack(
                children: [

                  Container(
                    padding:
                        const EdgeInsets.all(4),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color:
                              _primary.withOpacity(0.2),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: _lightBg,

                      backgroundImage:
                          _profileImage != null
                              ? FileImage(
                                  _profileImage!,
                                ) as ImageProvider<Object>
                              : widget.user
                                          .profileImageUrl !=
                                      null
                                  ? NetworkImage(
                                      widget.user
                                          .profileImageUrl!,
                                    ) as ImageProvider<Object>
                                  : null,

                      child:
                          _profileImage == null &&
                                  widget.user
                                          .profileImageUrl ==
                                      null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: _primary
                                      .withOpacity(0.5),
                                )
                              : null,
                    ),
                  ),

                  // ==================================================
                  // CAMERA BUTTON
                  // ==================================================

                  Positioned(
                    bottom: 4,
                    right: 4,

                    child: Container(
                      padding:
                          const EdgeInsets.all(8),

                      decoration: BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,

                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),

                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==================================================
            // FULL NAME
            // ==================================================

            _buildTextField(
              "Full Name",
              Icons.person_outline_rounded,
              _nameController,
              isLocked: !_canEditName,
            ),

            // ==================================================
            // COLLEGE ID
            // ==================================================

            _buildTextField(
              "College ID",
              Icons.badge_outlined,
              TextEditingController(
                text: widget.user.collegeId,
              ),
              isLocked: true,
            ),

            // ==================================================
            // STUDENT SPECIFIC FIELDS
            // ==================================================

            if (_isStudent) ...[

              _buildTextField(
                "Roll Number",
                Icons.format_list_numbered,

                TextEditingController(
                  text:
                      widget.user.rollNumber ??
                          'N/A',
                ),

                isLocked: true,
              ),

              _buildTextField(
                "Semester",
                Icons.timeline_outlined,

                TextEditingController(
                  text:
                      "Sem ${widget.user.semester ?? 1}",
                ),

                isLocked: true,
              ),
            ],

            // ==================================================
            // EMAIL
            // ==================================================

            _buildTextField(
              "Email Address",
              Icons.email_outlined,
              _emailController,

              keyboardType:
                  TextInputType.emailAddress,

              isLocked: !_canEditContact,
            ),

            // ==================================================
            // PHONE
            // ==================================================

            _buildTextField(
              "Phone Number",
              Icons.phone_outlined,
              _phoneController,

              keyboardType:
                  TextInputType.phone,

              isLocked: !_canEditContact,
            ),

            // ==================================================
            // BIO
            // ==================================================

            _buildTextField(
              "Bio / About",
              Icons.description_outlined,
              _bioController,
              maxLines: 3,
            ),

            // ==================================================
            // SECURITY WARNING
            // ==================================================

            if (!_canEditContact) ...[

              const SizedBox(height: 8),

              Container(
                padding:
                    const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color:
                      Colors.orange.shade50,

                  borderRadius:
                      BorderRadius.circular(12),

                  border: Border.all(
                    color:
                        Colors.orange.shade200,
                  ),
                ),

                child: Row(
                  children: [

                    Icon(
                      Icons.privacy_tip_outlined,
                      color:
                          Colors.orange.shade700,
                      size: 20,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        "Email, Phone, and Academic "
                        "details cannot be changed directly. "
                        "Please contact the Admin Office "
                        "for verification.",

                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.orange.shade800,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // ADVANCED SECURITY
            // ==================================================

            if (_canEditContact) ...[

              const SizedBox(height: 24),

              const Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  "Advanced Security",

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(16),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05),
                      blurRadius: 8,
                      offset:
                          const Offset(0, 2),
                    ),
                  ],
                ),

                child: Column(
                  children: [

                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,

                      title: const Text(
                        "Two-Factor Authentication (2FA)",

                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      subtitle: const Text(
                        "Add an extra layer of security "
                        "to your account",

                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),

                      value:
                          _twoFactorEnabled,

                      onChanged: (val) {
                        setState(() {
                          _twoFactorEnabled =
                              val;
                        });

                        ScaffoldMessenger
                                .of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? "2FA Enabled 🔒"
                                  : "2FA Disabled",
                            ),
                          ),
                        );
                      },

                      activeColor: _primary,

                      secondary:
                          const Icon(
                        Icons.lock_outline_rounded,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ==================================================
            // SAVE BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,

              child:
                  ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : _saveProfile,

                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,

                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save_rounded,
                      ),

                label: Text(
                  _isSaving
                      ? "Saving..."
                      : "Save Changes",

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      _primary,

                  foregroundColor:
                      Colors.white,

                  elevation: 0,

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOM TEXT FIELD
  // ============================================================

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    bool isLocked = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),

      child: TextField(
        controller: controller,

        keyboardType:
            keyboardType,

        maxLines: maxLines,

        readOnly: isLocked,

        decoration: InputDecoration(
          labelText: label,

          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight:
                FontWeight.w600,
          ),

          prefixIcon: Icon(
            icon,
            color: isLocked
                ? Colors.grey.shade400
                : _primary,
          ),

          suffixIcon: isLocked
              ? Icon(
                  Icons.lock_outline,
                  color:
                      Colors.grey.shade400,
                  size: 20,
                )
              : null,

          filled: true,

          fillColor: isLocked
              ? Colors.grey.shade100
              : Colors.white,

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide: BorderSide(
              color:
                  Colors.grey.shade200,
              width: 1,
            ),
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide: BorderSide(
              color:
                  Colors.grey.shade200,
              width: 1,
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide:
                const BorderSide(
              color: _primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}