import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

// Import all your screens here
import 'ai_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'timetable_screen.dart';
import 'attendance_screen.dart';
import 'library_screen.dart';
import 'notice_screen.dart';
import 'events_screen.dart';
import 'digital_id_screen.dart';
import 'analytics_dashboard.dart';
import 'settings_screen.dart';
import 'canteen_screen.dart';
import 'placement_dashboard_screen.dart';
import 'examination_screen.dart';
import 'fees_screen.dart';
import 'hostel_screen.dart';
import 'admin_panel_screen.dart';

class AppDrawer extends StatelessWidget {
  final UserRole userRole;
  final int currentNavigatorIndex;
  final Function(int) onItemTapped;

  const AppDrawer({
    super.key,
    required this.userRole,
    this.currentNavigatorIndex = 0,
    required this.onItemTapped,
  });

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.getCurrentUser();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: dark ? const Color(0xFF0B1120) : const Color(0xFFF5F9FF),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(user),
                const SizedBox(height: 8),
                _tile(context, Icons.home_outlined, "Home", () {
                  Navigator.pop(context);
                  onItemTapped(0);
                }),
                for (final m in _modules(auth, user))
                  _tile(context, m.$2, m.$1, () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(context, MaterialPageRoute(builder: (_) => m.$3()));
                  }),
                const Divider(height: 24, indent: 16, endIndent: 16),
                _tile(context, Icons.help_outline_rounded, "Help & Support", () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Help & Support coming soon!")),
                  );
                }),
                _tile(context, Icons.info_outline_rounded, "About Application", () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: "Campus Digital Twin AI",
                    applicationVersion: "1.0.0",
                    applicationLegalese: "© 2024 Campus Digital Twin AI",
                  );
                }),
                _tile(context, Icons.logout_rounded, "Logout", () {
                  Navigator.pop(context);
                  _showLogoutDialog(context, auth);
                }, isLogout: true),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader(UserModel? user) {
    final photo = user?.profileImageUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: photo != null ? NetworkImage(photo) : null,
                      child: photo == null
                          ? const Icon(Icons.person, size: 35, color: _primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? "Guest User",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(user?.role.name.toUpperCase() ?? "GUEST",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final (icon, text) in [
              (Icons.apartment, "XYZ Campus of Excellence"),
              (Icons.school_outlined, user?.department ?? "Department"),
              (Icons.email_outlined, user?.email ?? "user@campus.edu"),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white70, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- MODULES (title, icon, lazy screen) ----------------

  List<(String, IconData, Widget Function())> _modules(AuthService auth, UserModel? user) {
    final name = user?.fullName ?? "User";

    // (permission, title, icon, screen)
    final permitted = <(String, String, IconData, Widget Function())>[
      ('aiassistant', "AI Assistant", Icons.smart_toy_outlined, () => const AIScreen()),
      (
        'attendance',
        "Attendance",
        Icons.fact_check_outlined,
        () => AttendanceScreen(userRole: userRole, currentUserName: name)
      ),
      (
        'timetable',
        "Timetable",
        Icons.calendar_month_outlined,
        () => TimetableScreen(userRole: userRole)
      ),
      ('library', "Library", Icons.menu_book_outlined, () => const LibraryScreen()),
      ('canteen', "Canteen", Icons.restaurant_outlined, () => const CanteenScreen()),
      ('placement', "Placement", Icons.work_outline, () => const PlacementDashboardScreen()),
      ('notice', "Notices", Icons.campaign_outlined, () => NoticeScreen(userRole: userRole)),
      (
        'events',
        "Events",
        Icons.celebration_outlined,
        () => EventsScreen(userRole: userRole, currentUserName: name)
      ),
      ('digitalid', "Digital ID", Icons.badge_outlined, () => const DigitalIdScreen()),
      ('campusmap', "Campus Map", Icons.map_outlined, () => const MapScreen()),
      // Exams, Fees and Hostel currently share the 'attendance' permission.
      (
        'attendance',
        "Exams",
        Icons.assignment_turned_in_outlined,
        () => const ExaminationScreen()
      ),
      (
        'attendance',
        "Fees",
        Icons.account_balance_wallet_outlined,
        () => const FeesScreen()
      ),
      ('attendance', "Hostel", Icons.apartment_outlined, () => const HostelScreen()),
      ('analytics', "Analytics", Icons.insights_outlined, () => AnalyticsDashboardScreen()),
    ];

    return [
      for (final m in permitted)
        if (auth.hasPermission(m.$1, 'canView')) (m.$2, m.$3, m.$4),
      // Admin Panel: based on the actual user role from DB
      if (user?.role == UserRole.hod || user?.role == UserRole.principal)
        ("Admin Panel", Icons.admin_panel_settings_outlined, () => const AdminPanelScreen()),
      ("Profile", Icons.person_outline, () => ProfileScreen(role: userRole)),
      ("Settings", Icons.settings_outlined, () => const SettingsScreen()),
    ];
  }

  // ---------------- UI ELEMENTS ----------------

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final iconColor = isLogout ? Colors.red : (dark ? _accent : _primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLogout ? Colors.red : theme.colorScheme.onSurface,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Text(
        "Campus Digital Twin AI\nv1.0.0 (Build 2024.12.01)",
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.w600, height: 1.5),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Logout?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Are you sure you want to log out from the Campus Digital Twin AI app?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await auth.logout();
              if (!dialogContext.mounted) return;
              Navigator.pushNamedAndRemoveUntil(dialogContext, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}