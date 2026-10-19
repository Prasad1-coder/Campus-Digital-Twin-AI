import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';
import 'edit_profile_screen.dart';
import 'services/auth_service.dart';
import 'user_model.dart';

// ---------- Same colour palette (unchanged) ----------
const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _accent = Color(0xFF42A5F5);
const Color _lightBg = Color(0xFFF5F9FF);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

// Helpers so light + dark mode both look good
Color _tintOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _primary.withOpacity(0.20) : _softBlue;

Color _iconOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _accent : _primary;

Color _headingOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : _textDark;

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
    // FIRESTORE LIVE PROFILE (logic unchanged)
    // ============================================================

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.id).snapshots(),
      builder: (context, snapshot) {
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
            fullName = data['fullName']?.toString() ?? fullName;
            email = data['email']?.toString() ?? email;
            phone = data['phoneNumber']?.toString() ?? phone;
            collegeId = data['collegeId']?.toString() ?? collegeId;
            designation = data['designation']?.toString() ?? designation;
            department = data['department']?.toString() ?? department;

            final firestoreImage = data['profileImageUrl']?.toString();

            if (firestoreImage != null && firestoreImage.isNotEmpty) {
              profileImageUrl = firestoreImage;
            }
          }
        }

        final String roleText = role.name[0].toUpperCase() + role.name.substring(1);

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: isDark ? theme.scaffoldBackgroundColor : _lightBg,
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              // Extra bottom space so Logout never hides behind the floating nav bar
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header + stats strip overlapping its bottom edge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildHeader(
                        context,
                        user: user,
                        fullName: fullName,
                        department: department,
                        profileImageUrl: profileImageUrl,
                        roleText: roleText,
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: -38,
                        child: _buildStatsStrip(theme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 62),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==========================================
                        // PERSONAL INFORMATION
                        // ==========================================
                        Text(
                          "Personal Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _headingOf(theme),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // One grouped list instead of 4 separate cards
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
                          ),
                          child: Column(
                            children: [
                              _ProfileInfoRow(
                                icon: Icons.email_outlined,
                                label: "Email Address",
                                value: email,
                              ),
                              _rowDivider(theme),
                              _ProfileInfoRow(
                                icon: Icons.phone_outlined,
                                label: "Phone Number",
                                value: phone,
                              ),
                              _rowDivider(theme),
                              _ProfileInfoRow(
                                icon: Icons.badge_outlined,
                                label: "College ID",
                                value: collegeId,
                              ),
                              _rowDivider(theme),
                              _ProfileInfoRow(
                                icon: Icons.workspace_premium_outlined,
                                label: "Designation",
                                value: designation,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ==========================================
                        // LOGOUT BUTTON (logic unchanged)
                        // ==========================================
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _authService.logout();

                              if (!context.mounted) {
                                return;
                              }

                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            },
                            icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                            label: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.red.withOpacity(0.08),
                              side: BorderSide(color: Colors.red.withOpacity(0.45)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rowDivider(ThemeData theme) {
    return Divider(height: 1, indent: 70, color: theme.dividerColor.withOpacity(0.7));
  }

  // ============================================================
  // HEADER: blueprint panel, left aligned ID-card style
  // ============================================================
  Widget _buildHeader(
    BuildContext context, {
    required UserModel user,
    required String fullName,
    required String department,
    required String? profileImageUrl,
    required String roleText,
  }) {
    // Back button only when this screen was pushed (same rule the old AppBar used)
    final bool canGoBack = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ProfileGridPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- Top row: back / title / edit ----------
                  Row(
                    children: [
                      if (canGoBack) ...[
                        _HeaderIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: "Back",
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          "$roleText Profile",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: "Edit profile",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(user: user),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---------- Avatar + name + chips ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(fullName, profileImageUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (department.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.28)),
                                    ),
                                    child: Text(
                                      department,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    roleText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Squircle avatar (falls back to initial if image fails) ----------
  Widget _buildAvatar(String name, String? url) {
    final String trimmed = name.trim();
    final String initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : "?";

    final Widget fallback = Center(
      child: Text(
        initial,
        style: const TextStyle(color: _primaryDark, fontSize: 34, fontWeight: FontWeight.w800),
      ),
    );

    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          color: _softBlue,
          child: (url != null && url.isNotEmpty)
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                  loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
                )
              : fallback,
        ),
      ),
    );
  }

  // ============================================================
  // STATS: one joined strip (same style as dashboard)
  // ============================================================
  Widget _buildStatsStrip(ThemeData theme) {
    final stats = _stats;
    final List<Widget> cells = [];

    for (int i = 0; i < stats.length; i++) {
      final s = stats[i];
      if (i > 0) {
        cells.add(Container(width: 1, height: 40, color: theme.dividerColor));
      }
      cells.add(
        Expanded(
          child: _StatCell(
            label: s['label'] as String,
            value: s['value'] as String,
            icon: s['icon'] as IconData,
            color: s['color'] as Color,
          ),
        ),
      );
    }

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(children: cells),
    );
  }
}

// ======================================================================
// HEADER GRID (same blueprint look as the dashboard)
// ======================================================================

class _ProfileGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final ring = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width - 30, size.height - 40);
    for (final r in [36.0, 64.0, 92.0]) {
      canvas.drawCircle(center, r, ring);
    }

    final dot = Paint()..color = Colors.white.withOpacity(0.45);
    canvas.drawCircle(Offset(center.dx - 36, center.dy), 3, dot);
    canvas.drawCircle(Offset(center.dx, center.dy - 64), 3, dot);
    canvas.drawCircle(Offset(center.dx - 92, center.dy), 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ======================================================================
// SMALL FROSTED BUTTON FOR THE HEADER
// ======================================================================

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// STAT CELL (one column of the stats strip)
// ======================================================================

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _headingOf(theme),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: theme.hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// PROFILE INFORMATION ROW (lives inside the grouped list)
// ======================================================================

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isEmpty = value.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _tintOf(theme),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _iconOf(theme), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEmpty ? "Not added yet" : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w700,
                    color: isEmpty ? theme.hintColor : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}