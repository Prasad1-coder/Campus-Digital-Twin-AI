import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'theme_controller.dart'; // 👈 FIX: Imported Theme Controller

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> { 
  final AuthService _authService = AuthService();
  
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;

  UserModel? get _user => _authService.getCurrentUser();
  bool get _isStudent => _user?.role == UserRole.student;
  bool get _isTeacher => _user?.role == UserRole.teacher;
  bool get _isHOD => _user?.role == UserRole.hod;
  bool get _isPrincipal => _user?.role == UserRole.principal;

  void _showFeatureDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text("The $title module is ready for backend integration. (UI Placeholder)"),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Logout?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Are you sure you want to log out from the Campus Digital Twin AI app?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            
            // Account Section
            _buildSectionTitle("Account"),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildTile(Icons.person_outline_rounded, "Profile Information", "Update your personal details", () => _showFeatureDialog("Profile")),
                _buildTile(Icons.lock_outline_rounded, "Change Password", "Update your security password", () => _showFeatureDialog("Change Password")),
                _buildTile(Icons.security_rounded, "Two-Factor Authentication (2FA)", "Add an extra layer of security", () => _showFeatureDialog("2FA")),
                _buildSwitchTile(Icons.fingerprint_rounded, "Biometric Login", "Use fingerprint/face unlock", _biometricEnabled, (val) => setState(() => _biometricEnabled = val)),
              ],
            ),
            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionTitle("Preferences"),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildSwitchTile(Icons.notifications_active_outlined, "Push Notifications", "Receive alerts for notices & events", _notificationsEnabled, (val) => setState(() => _notificationsEnabled = val)),
                // 👇 FIX: Dark Mode Toggle Connected to ThemeController
                _buildSwitchTile(
                  Icons.dark_mode_outlined, 
                  "Dark Mode", 
                  "Toggle app theme", 
                  ThemeController.instance.isDark, 
                  (val) {
                    ThemeController.instance.toggleTheme(val);
                    setState(() {}); // To instantly reflect on UI
                  }
                ),
                _buildTile(Icons.language_rounded, "Language", "English (Default)", () => _showFeatureDialog("Language Selection")),
                _buildTile(Icons.accessibility_new_rounded, "Accessibility", "Font size and contrast settings", () => _showFeatureDialog("Accessibility")),
              ],
            ),
            const SizedBox(height: 24),

            // Role-Based Preferences
            if (_isStudent) ...[
              _buildSectionTitle("Student Preferences"),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildTile(Icons.privacy_tip_outlined, "Privacy Settings", "Control who can see your data", () => _showFeatureDialog("Privacy Settings")),
                  _buildTile(Icons.download_for_offline_outlined, "Download My Data", "Request a copy of your data", () => _showFeatureDialog("Data Download")),
                ],
              ),
              const SizedBox(height: 24),
            ],

            if (_isTeacher) ...[
              _buildSectionTitle("Teacher Preferences"),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildTile(Icons.fact_check_outlined, "Attendance Preferences", "Default marking settings", () => _showFeatureDialog("Attendance Preferences")),
                  _buildTile(Icons.calendar_month_outlined, "Timetable Preferences", "Sync and view settings", () => _showFeatureDialog("Timetable Preferences")),
                  _buildTile(Icons.class_outlined, "Class Management", "Default class configurations", () => _showFeatureDialog("Class Preferences")),
                ],
              ),
              const SizedBox(height: 24),
            ],

            if (_isHOD || _isPrincipal) ...[
              _buildSectionTitle(_isPrincipal ? "Administration" : "Department Management"),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  if (_isHOD) ...[
                    _buildTile(Icons.business_outlined, "Department Preferences", "Configure department settings", () => _showFeatureDialog("Dept Preferences")),
                    _buildTile(Icons.approval_outlined, "Approval Workflow", "Configure notice/event approvals", () => _showFeatureDialog("Approval Preferences")),
                  ],
                  if (_isPrincipal) ...[
                    _buildTile(Icons.admin_panel_settings_outlined, "College Settings", "General college configuration", () => _showFeatureDialog("College Settings")),
                    _buildTile(Icons.people_alt_outlined, "User Management", "Manage students & staff", () => _showFeatureDialog("User Management")),
                    _buildTile(Icons.manage_accounts_outlined, "Role Management", "Define roles & permissions", () => _showFeatureDialog("Role Management")),
                    _buildTile(Icons.apartment_outlined, "Department Management", "Add/Edit departments", () => _showFeatureDialog("Department Management")),
                  ]
                ],
              ),
              const SizedBox(height: 24),
            ],

            // System Configuration (Principal Only)
            if (_isPrincipal) ...[
              _buildSectionTitle("System & Security"),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildTile(Icons.settings_applications_outlined, "System Configuration", "API & integration settings", () => _showFeatureDialog("System Configuration")),
                  _buildTile(Icons.cloud_upload_outlined, "Backup & Restore", "Manage cloud backups", () => _showFeatureDialog("Backup & Restore")),
                  _buildTile(Icons.history_rounded, "Audit Logs", "View system activity logs", () => _showFeatureDialog("Audit Logs")),
                  _buildTile(Icons.devices_other_outlined, "Device Management", "Manage active sessions", () => _showFeatureDialog("Device Management")),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Support & About
            _buildSectionTitle("Support & About"),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildTile(Icons.help_outline_rounded, "Help & Support", "FAQs and contact us", () => _showFeatureDialog("Help & Support")),
                _buildTile(Icons.feedback_outlined, "Send Feedback", "Report a bug or suggest a feature", () => _showFeatureDialog("Feedback")),
                _buildTile(Icons.info_outline_rounded, "About Application", "Version 1.0.0 (Build 2024.12.01)", () => _showFeatureDialog("About App")),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_outlined, color: Colors.white),
                label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  WIDGETS
  // ============================================================

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.person, size: 35, color: colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_user?.fullName ?? "Guest User", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text("${_user?.role.name.toUpperCase()} • ${_user?.department ?? 'N/A'}", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white), onPressed: () => _showFeatureDialog("Profile"))
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor, // 👈 FIX: Adapts to Dark Mode card color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          return Column(
            children: [
              children[index],
              if (index < children.length - 1) Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(10)
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: theme.hintColor)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.hintColor),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: theme.hintColor,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );
  }
}