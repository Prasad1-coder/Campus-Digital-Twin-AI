import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'digital_id_screen.dart';
import 'main.dart'; // LoginScreen yahan se aata hai

class SettingsScreen extends StatefulWidget {
  final UserRole userRole;

  const SettingsScreen({super.key, required this.userRole});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  String selectedLanguage = "English";

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(role: widget.userRole)));
  }

  void _openDigitalId() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DigitalIdScreen(userRole: widget.userRole)));
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature - coming soon"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  void _pickLanguage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final languages = ["English", "Hindi", "Marathi"];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("Select Language", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                ...languages.map((lang) {
                  final isSelected = lang == selectedLanguage;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    title: Text(lang, style: const TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      setState(() => selectedLanguage = lang);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout?"),
        content: const Text("Kya aap sach mein logout karna chahte ho?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          // ============ ACCOUNT ============
          _SettingsSection(
            title: "Account",
            icon: Icons.person_outline_rounded,
            children: [
              _SettingsTile(
                icon: Icons.account_circle_outlined,
                label: "Profile",
                onTap: _openProfile,
              ),
              _SettingsTile(
                icon: Icons.edit_outlined,
                label: "Edit Profile",
                onTap: () => _showComingSoon("Edit Profile"),
              ),
              _SettingsTile(
                icon: Icons.badge_outlined,
                label: "Digital ID",
                onTap: _openDigitalId,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ============ PREFERENCES ============
          _SettingsSection(
            title: "Preferences",
            icon: Icons.tune_rounded,
            children: [
              _SettingsSwitchTile(
                icon: Icons.notifications_outlined,
                label: "Notifications",
                value: notificationsEnabled,
                onChanged: (v) => setState(() => notificationsEnabled = v),
              ),
              _SettingsSwitchTile(
                icon: Icons.dark_mode_outlined,
                label: "Dark Mode",
                value: darkModeEnabled,
                onChanged: (v) {
                  setState(() => darkModeEnabled = v);
                  _showComingSoon("Dark Mode");
                },
              ),
              _SettingsTile(
                icon: Icons.language_outlined,
                label: "Language",
                trailingText: selectedLanguage,
                onTap: _pickLanguage,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ============ CAMPUS ============
          _SettingsSection(
            title: "Campus",
            icon: Icons.school_outlined,
            children: [
              _SettingsTile(
                icon: Icons.fact_check_outlined,
                label: "Attendance Settings",
                onTap: () => _showComingSoon("Attendance Settings"),
              ),
              _SettingsTile(
                icon: Icons.menu_book_outlined,
                label: "Library Settings",
                onTap: () => _showComingSoon("Library Settings"),
              ),
              _SettingsTile(
                icon: Icons.smart_toy_outlined,
                label: "AI Assistant Settings",
                onTap: () => _showComingSoon("AI Assistant Settings"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ============ PRIVACY & SECURITY ============
          _SettingsSection(
            title: "Privacy & Security",
            icon: Icons.lock_outline_rounded,
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: "Privacy Policy",
                onTap: () => _showComingSoon("Privacy Policy"),
              ),
              _SettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                label: "Permissions",
                onTap: () => _showComingSoon("Permissions"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ============ ABOUT ============
          _SettingsSection(
            title: "About",
            icon: Icons.info_outline_rounded,
            children: [
              _SettingsTile(
                icon: Icons.apps_outlined,
                label: "About App",
                onTap: () => _showComingSoon("About App"),
              ),
              _SettingsTile(
                icon: Icons.numbers_outlined,
                label: "Version",
                trailingText: "1.0.0",
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                label: "Feedback",
                onTap: () => _showComingSoon("Feedback"),
              ),
              _SettingsTile(
                icon: Icons.support_agent_outlined,
                label: "Contact Support",
                onTap: () => _showComingSoon("Contact Support"),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // ============ LOGOUT ============
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showLogoutDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 19),
                    const SizedBox(width: 10),
                    Text(
                      "Logout",
                      style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              "Campus Digital Twin AI v1.0.0",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// REUSABLE WIDGETS
// ================================================================

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.label, this.trailingText, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 17, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(trailingText!, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
              ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}