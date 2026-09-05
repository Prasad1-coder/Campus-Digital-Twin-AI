import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';
import 'edit_profile_screen.dart';
import 'services/auth_service.dart';
import 'user_model.dart';

// Colors
const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _lightBg = Color(0xFFF5F9FF);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

class ProfileScreen extends StatelessWidget {
  final UserRole role;
  final AuthService _authService = AuthService();

  ProfileScreen({
    super.key,
    required this.role,
  });

  UserModel? get _user => _authService.getCurrentUser();

  // ============================================================
  // ROLE BASED STATS
  // ============================================================

  List<Map<String, dynamic>> get _stats {
    switch (role) {
      case UserRole.student:
        return [
          {
            "label": "Attendance",
            "value": "87%",
            "icon": Icons.fact_check_outlined,
            "color": Colors.green,
          },
          {
            "label": "Semester",
            "value": "6th",
            "icon": Icons.timeline_outlined,
            "color": Colors.blue,
          },
          {
            "label": "CGPA",
            "value": "8.4",
            "icon": Icons.star_outline,
            "color": Colors.orange,
          },
        ];

      case UserRole.teacher:
      case UserRole.hod:
        return [
          {
            "label": "Experience",
            "value": "6 yrs",
            "icon": Icons.work_outline,
            "color": Colors.blue,
          },
          {
            "label": "Subjects",
            "value": "3",
            "icon": Icons.menu_book_outlined,
            "color": Colors.purple,
          },
          {
            "label": "Classes",
            "value": "5",
            "icon": Icons.groups_outlined,
            "color": Colors.teal,
          },
        ];

      case UserRole.principal:
        return [
          {
            "label": "Departments",
            "value": "8",
            "icon": Icons.business_outlined,
            "color": Colors.orange,
          },
          {
            "label": "Students",
            "value": "2.4k",
            "icon": Icons.groups_outlined,
            "color": Colors.teal,
          },
          {
            "label": "Staff",
            "value": "180",
            "icon": Icons.people_alt_outlined,
            "color": Colors.blue,
          },
        ];
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("No User Found"),
        ),
      );
    }

    // ============================================================
    // FIRESTORE LIVE PROFILE
    // ============================================================

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .snapshots(),

      builder: (context, snapshot) {
        // --------------------------------------------------------
        // USE FIRESTORE DATA WHEN AVAILABLE
        // --------------------------------------------------------

        String fullName = user.fullName;
        String email = user.email;
        String phone = user.phoneNumber;
        String collegeId = user.collegeId;
        String designation = user.designation;
        String department = user.department;
        String? profileImageUrl = user.profileImageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();

          if (data != null) {
            fullName =
                data['fullName']?.toString() ?? fullName;

            email =
                data['email']?.toString() ?? email;

            phone =
                data['phoneNumber']?.toString() ?? phone;

            collegeId =
                data['collegeId']?.toString() ?? collegeId;

            designation =
                data['designation']?.toString() ?? designation;

            department =
                data['department']?.toString() ?? department;

            final firestoreImage =
                data['profileImageUrl']?.toString();

            if (firestoreImage != null &&
                firestoreImage.isNotEmpty) {
              profileImageUrl = firestoreImage;
            }
          }
        }

        final String roleText =
            role.name[0].toUpperCase() +
                role.name.substring(1);

        return Scaffold(
          backgroundColor: _lightBg,

          body: CustomScrollView(
            slivers: [

              // ==================================================
              // PROFILE HEADER
              // ==================================================

              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,

                title: Text(
                  "$roleText Profile",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                    ),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            user: user,
                          ),
                        ),
                      );
                    },
                  ),
                ],

                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryDark,
                          _primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      borderRadius:
                          BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),

                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [

                          const SizedBox(height: 30),

                          // ======================================
                          // PROFILE IMAGE
                          // ======================================

                          Container(
                            padding:
                                const EdgeInsets.all(4),

                            decoration:
                                const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),

                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor:
                                  _softBlue,

                              backgroundImage:
                                  profileImageUrl != null &&
                                          profileImageUrl
                                              .isNotEmpty
                                      ? NetworkImage(
                                          profileImageUrl,
                                        )
                                      : null,

                              child:
                                  profileImageUrl == null ||
                                          profileImageUrl
                                              .isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 55,
                                          color: _primary,
                                        )
                                      : null,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ======================================
                          // FULL NAME
                          // ======================================

                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // ======================================
                          // DEPARTMENT
                          // ======================================

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white.withOpacity(
                                0.2,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),

                            child: Text(
                              department,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ======================================
                          // ROLE
                          // ======================================

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),

                            decoration:
                                BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),

                            child: Text(
                              roleText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w900,
                                color: _primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // STATS
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    20,
                    18,
                    0,
                  ),

                  child: Row(
                    children: _stats.map(
                      (stat) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            right: 12,
                          ),

                          child: _StatCard(
                            label:
                                stat['label'] as String,
                            value:
                                stat['value'] as String,
                            icon:
                                stat['icon'] as IconData,
                            color:
                                stat['color'] as Color,
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),

              // ==================================================
              // PERSONAL INFORMATION
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    26,
                    18,
                    24,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Personal Information",

                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                          color: _textDark,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Email
                      _ProfileInfoCard(
                        icon:
                            Icons.email_outlined,
                        label:
                            "Email Address",
                        value: email,
                      ),

                      // Phone
                      _ProfileInfoCard(
                        icon:
                            Icons.phone_outlined,
                        label:
                            "Phone Number",
                        value: phone,
                      ),

                      // College ID
                      _ProfileInfoCard(
                        icon:
                            Icons.badge_outlined,
                        label:
                            "College ID",
                        value: collegeId,
                      ),

                      // Designation
                      _ProfileInfoCard(
                        icon:
                            Icons.workspace_premium_outlined,
                        label:
                            "Designation",
                        value: designation,
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // LOGOUT BUTTON
                      // ==================================================

                      SizedBox(
                        width: double.infinity,

                        child:
                            ElevatedButton.icon(
                          onPressed: () async {
                            await _authService.logout();

                            if (!context.mounted) {
                              return;
                            }

                            Navigator
                                .pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },

                          icon: const Icon(
                            Icons.logout_outlined,
                            color: Colors.red,
                            size: 18,
                          ),

                          label: const Text(
                            "Logout",

                            style: TextStyle(
                              color: Colors.red,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white,

                            side:
                                const BorderSide(
                              color: Colors.red,
                            ),

                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================================================================
// STAT CARD
// ======================================================================

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color:
                  color.withOpacity(0.15),
              blurRadius: 12,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          children: [

            Container(
              padding:
                  const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              value,

              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color: _textDark,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,

              style: TextStyle(
                fontSize: 10.5,
                color:
                    Colors.grey.shade600,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// PROFILE INFORMATION CARD
// ======================================================================

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: ListTile(
        contentPadding:
            EdgeInsets.zero,

        leading: Container(
          padding:
              const EdgeInsets.all(10),

          decoration:
              const BoxDecoration(
            color: _softBlue,
            shape: BoxShape.circle,
          ),

          child: Icon(
            icon,
            color: _primary,
            size: 22,
          ),
        ),

        title: Text(
          label,

          style: TextStyle(
            fontSize: 12,
            color:
                Colors.grey.shade500,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 2,
          ),

          child: Text(
            value,

            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}