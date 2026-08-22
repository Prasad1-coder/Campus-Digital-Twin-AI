import 'package:flutter/material.dart';
import 'user_role.dart';
import 'edit_profile_screen.dart';
import 'services/auth_service.dart';
import 'user_model.dart';

// Colors moved outside class so all classes can access them
const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _lightBg = Color(0xFFF5F9FF);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

class ProfileScreen extends StatelessWidget {
  final UserRole role;
  final AuthService _authService = AuthService();

  ProfileScreen({super.key, required this.role});

  UserModel? get _user => _authService.getCurrentUser();

  // Role-based dummy stats (Since UserModel doesn't have CGPA/Experience fields yet)
  List<Map<String, dynamic>> get _stats {
    switch (role) {
      case UserRole.student:
        return [
          {"label": "Attendance", "value": "87%", "icon": Icons.fact_check_outlined, "color": Colors.green},
          {"label": "Semester", "value": "6th", "icon": Icons.timeline_outlined, "color": Colors.blue},
          {"label": "CGPA", "value": "8.4", "icon": Icons.star_outline, "color": Colors.orange},
        ];
      case UserRole.teacher:
      case UserRole.hod:
        return [
          {"label": "Experience", "value": "6 yrs", "icon": Icons.work_outline, "color": Colors.blue},
          {"label": "Subjects", "value": "3", "icon": Icons.menu_book_outlined, "color": Colors.purple},
          {"label": "Classes", "value": "5", "icon": Icons.groups_outlined, "color": Colors.teal},
        ];
      case UserRole.principal:
        return [
          {"label": "Departments", "value": "8", "icon": Icons.business_outlined, "color": Colors.orange},
          {"label": "Students", "value": "2.4k", "icon": Icons.groups_outlined, "color": Colors.teal},
          {"label": "Staff", "value": "180", "icon": Icons.people_alt_outlined, "color": Colors.blue},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("No User Found")));
    }

    final String roleText = role.name[0].toUpperCase() + role.name.substring(1);

    return Scaffold(
      backgroundColor: _lightBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "$roleText Profile",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                // 👇 FIX: Now passes the whole UserModel directly to EditProfileScreen
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(user: user),
                    ),
                  );
                },
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
                          backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                          child: user.profileImageUrl == null 
                              ? Icon(Icons.person, size: 55, color: _primary) 
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                          user.department,
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
                          roleText,
                          style: const TextStyle(
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Row(
                children: _stats.map((stat) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _StatCard(
                    label: stat['label'] as String,
                    value: stat['value'] as String,
                    icon: stat['icon'] as IconData,
                    color: stat['color'] as Color,
                  ),
                )).toList(),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark),
                  ),
                  const SizedBox(height: 16),

                  _ProfileInfoCard(
                    icon: Icons.email_outlined,
                    label: "Email Address",
                    value: user.email,
                  ),
                  _ProfileInfoCard(
                    icon: Icons.phone_outlined,
                    label: "Phone Number",
                    value: user.phoneNumber,
                  ),
                  _ProfileInfoCard(
                    icon: Icons.badge_outlined,
                    label: "College ID",
                    value: user.collegeId,
                  ),
                  _ProfileInfoCard(
                    icon: Icons.workspace_premium_outlined,
                    label: "Designation",
                    value: user.designation,
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      icon: const Icon(Icons.logout_outlined, color: Colors.red, size: 18),
                      label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
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
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
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
          decoration: const BoxDecoration(color: _softBlue, shape: BoxShape.circle),
          child: Icon(icon, color: _primary, size: 22),
        ),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
      ),
    );
  }
}