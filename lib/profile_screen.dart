import 'package:flutter/material.dart';
import 'user_role.dart'; // Imported from user_role.dart

class ProfileScreen extends StatelessWidget {
  final UserRole role;

  const ProfileScreen({super.key, this.role = UserRole.student});

  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  // Dynamic User Data based on Role
  Map<String, dynamic> get _userData {
    switch (role) {
      case UserRole.student:
        return {
          "name": "Prasad Patil",
          "subtitle": "Computer Engineering",
          "roleText": "STUDENT",
          "icon": Icons.school_rounded,
          "stats": [
            {"label": "Attendance", "value": "87%", "icon": Icons.fact_check_outlined, "color": Colors.green},
            {"label": "Semester", "value": "6th", "icon": Icons.timeline_outlined, "color": Colors.blue},
            {"label": "CGPA", "value": "8.4", "icon": Icons.star_outline, "color": Colors.orange},
          ],
          "info": [
            {"icon": Icons.email_outlined, "label": "Email", "value": "prasad@campus.edu"},
            {"icon": Icons.school_outlined, "label": "College", "value": "XYZ Campus of Excellence"},
            {"icon": Icons.badge_outlined, "label": "Roll Number", "value": "ST2026001"},
            {"icon": Icons.groups_outlined, "label": "Class / Division", "value": "CE - Div A"},
          ]
        };
      case UserRole.teacher:
        return {
          "name": "Dr. Rajesh Sharma",
          "subtitle": "Computer Science",
          "roleText": "TEACHER",
          "icon": Icons.badge_outlined,
          "stats": [
            {"label": "Experience", "value": "6 yrs", "icon": Icons.work_outline, "color": Colors.blue},
            {"label": "Subjects", "value": "3", "icon": Icons.menu_book_outlined, "color": Colors.purple},
            {"label": "Classes", "value": "5", "icon": Icons.groups_outlined, "color": Colors.teal},
          ],
          "info": [
            {"icon": Icons.email_outlined, "label": "Email", "value": "rajesh.sharma@campus.edu"},
            {"icon": Icons.school_outlined, "label": "Department", "value": "Computer Science"},
            {"icon": Icons.badge_outlined, "label": "Employee ID", "value": "FACCS101"},
            {"icon": Icons.workspace_premium_outlined, "label": "Designation", "value": "Assistant Professor"},
          ]
        };
      case UserRole.hod:
        return {
          "name": "Dr. Sunita Rao",
          "subtitle": "Chemistry Department",
          "roleText": "HOD",
          "icon": Icons.supervised_user_circle_outlined,
          "stats": [
            {"label": "Teachers", "value": "12", "icon": Icons.school_outlined, "color": Colors.purple},
            {"label": "Students", "value": "340", "icon": Icons.groups_outlined, "color": Colors.teal},
            {"label": "Experience", "value": "12 yrs", "icon": Icons.work_outline, "color": Colors.blue},
          ],
          "info": [
            {"icon": Icons.email_outlined, "label": "Email", "value": "hod.chem@campus.edu"},
            {"icon": Icons.business_outlined, "label": "Department", "value": "Chemistry"},
            {"icon": Icons.badge_outlined, "label": "Employee ID", "value": "HODCH01"},
            {"icon": Icons.workspace_premium_outlined, "label": "Designation", "value": "Head of Department"},
          ]
        };
      case UserRole.principal:
        return {
          "name": "Dr. Suresh Nair",
          "subtitle": "Administration",
          "roleText": "PRINCIPAL",
          "icon": Icons.verified_user_outlined,
          "stats": [
            {"label": "Departments", "value": "8", "icon": Icons.business_outlined, "color": Colors.orange},
            {"label": "Students", "value": "2.4k", "icon": Icons.groups_outlined, "color": Colors.teal},
            {"label": "Staff", "value": "180", "icon": Icons.people_alt_outlined, "color": Colors.blue},
          ],
          "info": [
            {"icon": Icons.email_outlined, "label": "Email", "value": "principal@campus.edu"},
            {"icon": Icons.apartment_outlined, "label": "College", "value": "XYZ Campus of Excellence"},
            {"icon": Icons.badge_outlined, "label": "Employee ID", "value": "PRIN001"},
            {"icon": Icons.workspace_premium_outlined, "label": "Designation", "value": "College Principal"},
          ]
        };
      default:
        return {
          "name": "Guest User", "subtitle": "Visitor", "roleText": "GUEST", "icon": Icons.person, "stats": [], "info": []
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _userData;
    final bool isStudent = role == UserRole.student;

    return Scaffold(
      backgroundColor: _lightBg,
      body: CustomScrollView(
        slivers: [
          // ---------- Gradient Header ----------
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "${data['roleText'].toString().split(' ')[0]} Profile",
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryDark, _primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: _softBlue,
                          child: Icon(
                            data['icon'] as IconData,
                            size: 55,
                            color: _primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data['name'] as String,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['subtitle'] as String,
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['roleText'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
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

          // ---------- Stats Row ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Row(
                children: [
                  ...(data['stats'] as List).map((stat) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _StatCard(
                      label: stat['label'] as String,
                      value: stat['value'] as String,
                      icon: stat['icon'] as IconData,
                      color: stat['color'] as Color,
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),

          // ---------- Info Section ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark),
                  ),
                  const SizedBox(height: 16),

                  ...(data['info'] as List).map((info) => _ProfileInfoCard(
                    icon: info['icon'] as IconData,
                    label: info['label'] as String,
                    value: info['value'] as String,
                  )).toList(),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      icon: const Icon(Icons.logout_outlined, size: 18, color: Colors.red),
                      label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF1565C0), size: 22),
        ),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}