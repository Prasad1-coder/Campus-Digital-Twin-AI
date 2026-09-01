import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'dummy_users.dart';
import 'user_model.dart';
import 'user_role.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AuthService _authService = AuthService();
  final DummyUserRepository _userRepo = DummyUserRepository.instance;

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  late List<UserModel> _allUsers;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    // Fetch fresh data from dummy database
    _allUsers = _userRepo.all;
  }

  // 👇 FIX: Logic to update user status in memory
  void _toggleUserStatus(UserModel user, bool newStatus) {
    setState(() {
      // Find the user in the main list and update their status
      final index = _allUsers.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        // Create a copy with new status and replace in list
        _allUsers[index] = user.copyWith(isActive: newStatus);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${user.fullName} ${newStatus ? 'Activated' : 'Deactivated'}"),
            backgroundColor: newStatus ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_primaryDark, _primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        title: const Text("Admin Control Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard("Total Users", "${_allUsers.length}", Icons.groups_rounded, Colors.blue),
                _buildStatCard("Students", "${_userRepo.students.length}", Icons.school_rounded, Colors.green),
                _buildStatCard("Staff", "${_userRepo.teachers.length + _userRepo.hods.length}", Icons.badge_rounded, Colors.orange),
                _buildStatCard("Pending Approvals", "03", Icons.pending_actions_rounded, Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Admin Quick Actions
            _buildSectionTitle("Management", Icons.admin_panel_settings_rounded),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActionCard("User Management", Icons.manage_accounts_outlined, Colors.blue, () {})),
                const SizedBox(width: 12),
                Expanded(child: _buildActionCard("Roles & Access", Icons.security_outlined, Colors.purple, () {})),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionCard("Audit Logs", Icons.history_rounded, Colors.teal, () {})),
                const SizedBox(width: 12),
                Expanded(child: _buildActionCard("System Config", Icons.settings_suggest_outlined, Colors.indigo, () {})),
              ],
            ),
            const SizedBox(height: 24),

            // User List (Manage Status)
            _buildSectionTitle("User Directory", Icons.list_alt_rounded),
            const SizedBox(height: 16),
            // Displaying all users dynamically
            ..._allUsers.map((user) => _buildUserListTile(user)).toList(),
          ],
        ),
      ),
    );
  }

  // 👇 FIX: Switch now actually calls the toggle function
  Widget _buildUserListTile(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _softBlue,
            child: Icon(Icons.person, color: _primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                Text("${user.role.name.toUpperCase()} • ${user.department}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: user.isActive,
            onChanged: (val) => _toggleUserStatus(user, val), // 👈 This is now working!
            activeColor: Colors.green,
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
      ],
    );
  }
}