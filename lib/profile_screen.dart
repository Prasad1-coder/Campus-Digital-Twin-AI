import 'package:flutter/material.dart';

enum UserRole { student, teacher }

class ProfileScreen extends StatelessWidget {
  final UserRole role;

  const ProfileScreen({super.key, this.role = UserRole.student});

  @override
  Widget build(BuildContext context) {
    final bool isStudent = role == UserRole.student;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // 👇 Gradient header - same style jo dashboard/profile mein pehle use kiya tha
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              isStudent ? "Student Profile" : "Teacher Profile",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                          backgroundColor: const Color(0xFFE3F2FD),
                          child: Icon(
                            isStudent ? Icons.person : Icons.person_2_outlined,
                            size: 55,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isStudent ? "Prasad" : "Dr. Rajesh Sharma",
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
                          isStudent ? "Computer Engineering" : "Chemistry Department",
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 👇 Role badge - visually batata hai kaun hai
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isStudent ? Colors.orange.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isStudent ? Icons.school : Icons.badge,
                              size: 14,
                              color: isStudent ? Colors.orange.shade700 : Colors.green.shade700,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isStudent ? "STUDENT" : "FACULTY",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isStudent ? Colors.orange.shade700 : Colors.green.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 👇 Stats row - quick glance info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Row(
                children: isStudent
                    ? [
                        _StatCard(label: "Attendance", value: "87%", icon: Icons.fact_check_outlined, color: Colors.green),
                        const SizedBox(width: 12),
                        _StatCard(label: "Semester", value: "4th", icon: Icons.timeline_outlined, color: Colors.blue),
                        const SizedBox(width: 12),
                        _StatCard(label: "CGPA", value: "8.4", icon: Icons.star_outline, color: Colors.orange),
                      ]
                    : [
                        _StatCard(label: "Experience", value: "6 yrs", icon: Icons.work_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        _StatCard(label: "Subjects", value: "3", icon: Icons.menu_book_outlined, color: Colors.purple),
                        const SizedBox(width: 12),
                        _StatCard(label: "Classes", value: "5", icon: Icons.groups_outlined, color: Colors.teal),
                      ],
              ),
            ),
          ),

          // 👇 Info section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Personal Information",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 14),

                  _ProfileInfoCard(
                    icon: Icons.email_outlined,
                    label: "Email",
                    value: isStudent ? "prasad@college.edu" : "rajesh.sharma@college.edu",
                  ),
                  _ProfileInfoCard(
                    icon: Icons.school_outlined,
                    label: "College",
                    value: "XYZ Engineering College",
                  ),

                  // 👇 Yahan se role-specific fields alag hote hain
                  if (isStudent) ...[
                    _ProfileInfoCard(
                      icon: Icons.badge_outlined,
                      label: "Roll Number",
                      value: "CE-2026-101",
                    ),
                    _ProfileInfoCard(
                      icon: Icons.numbers_outlined,
                      label: "Enrollment No.",
                      value: "SRTMU2024CE0187",
                    ),
                    _ProfileInfoCard(
                      icon: Icons.groups_outlined,
                      label: "Class / Division",
                      value: "CE - Division B",
                    ),
                  ] else ...[
                    _ProfileInfoCard(
                      icon: Icons.badge_outlined,
                      label: "Employee ID",
                      value: "FAC-2019-045",
                    ),
                    _ProfileInfoCard(
                      icon: Icons.workspace_premium_outlined,
                      label: "Designation",
                      value: "Assistant Professor",
                    ),
                    _ProfileInfoCard(
                      icon: Icons.auto_stories_outlined,
                      label: "Subjects Taught",
                      value: "Organic Chemistry, Physical Chemistry",
                    ),
                  ],

                  _ProfileInfoCard(
                    icon: Icons.phone_outlined,
                    label: "Mobile",
                    value: "+91 9876543210",
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
                      onPressed: () {},
                      icon: const Icon(Icons.logout_outlined, size: 18, color: Colors.red),
                      label: const Text("Logout", style: TextStyle(color: Colors.red)),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.blue, size: 22),
        ),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}