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
import 'analytics_dashboard.dart' hide DigitalIdScreen;
import 'settings_screen.dart';
import 'canteen_screen.dart';
import 'placement_dashboard_screen.dart';
import 'examination_screen.dart';
import 'fees_screen.dart';
import 'hostel_screen.dart';
import 'notification_screen.dart';
import 'global_search_screen.dart';
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

  // Theme Constants
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    final UserModel? user = _authService.getCurrentUser();

    return Drawer(
      backgroundColor: _lightBg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(user),
                const SizedBox(height: 8),
                
                // Common Menu
                _drawerTile(context, Icons.home_outlined, "Home", () {
                  Navigator.pop(context);
                  onItemTapped(0);
                }),
                
                // Dynamic Role-Based Menus
                ..._getDynamicModules(context, _authService),
                
                const Divider(height: 24, indent: 16, endIndent: 16),
                
                _drawerTile(context, Icons.help_outline_rounded, "Help & Support", () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Help & Support coming soon!")),
                  );
                }),
                _drawerTile(context, Icons.info_outline_rounded, "About Application", () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: "Campus Digital Twin AI",
                    applicationVersion: "1.0.0",
                    applicationLegalese: "© 2024 Campus Digital Twin AI",
                  );
                }),
                _drawerTile(context, Icons.logout_rounded, "Logout", () {
                  Navigator.pop(context);
                  _showLogoutDialog(context, _authService);
                }, isLogout: true),
              ],
            ),
          ),
          _buildFooterVersion(),
        ],
      ),
    );
  }

  // ============================================================
  //  HEADER
  // ============================================================
  Widget _buildHeader(UserModel? user) {
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
                      backgroundImage: user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
                      child: user?.profileImageUrl == null
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
                    )
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? "Guest User",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user?.role.name.toUpperCase() ?? "GUEST",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            _headerRow(Icons.apartment, "XYZ Campus of Excellence"),
            const SizedBox(height: 6),
            _headerRow(Icons.school_outlined, user?.department ?? "Department"),
            const SizedBox(height: 6),
            _headerRow(Icons.email_outlined, user?.email ?? "user@campus.edu"),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  DYNAMIC MODULES LOGIC
  // ============================================================
  List<Widget> _getDynamicModules(BuildContext context, AuthService auth) {
    List<Map<String, dynamic>> modules = [];
    
    // 👇 FIX: Getting actual user from Auth Service to check exact role
    final UserModel? user = auth.getCurrentUser();

    if (auth.hasPermission('aiassistant', 'canView')) modules.add({"title": "AI Assistant", "icon": Icons.smart_toy_outlined, "screen": const AIScreen()});
    if (auth.hasPermission('attendance', 'canView')) modules.add({"title": "Attendance", "icon": Icons.fact_check_outlined, "screen": AttendanceScreen(userRole: userRole, currentUserName: auth.getCurrentUser()?.fullName ?? "User")});
    if (auth.hasPermission('timetable', 'canView')) modules.add({"title": "Timetable", "icon": Icons.calendar_month_outlined, "screen": TimetableScreen(userRole: userRole)});
    if (auth.hasPermission('library', 'canView')) modules.add({"title": "Library", "icon": Icons.menu_book_outlined, "screen": const LibraryScreen()});
    if (auth.hasPermission('canteen', 'canView')) modules.add({"title": "Canteen", "icon": Icons.restaurant_outlined, "screen": const CanteenScreen()});
    if (auth.hasPermission('placement', 'canView')) modules.add({"title": "Placement", "icon": Icons.work_outline, "screen": const PlacementDashboardScreen()});
    if (auth.hasPermission('notice', 'canView')) modules.add({"title": "Notices", "icon": Icons.campaign_outlined, "screen": NoticeScreen(userRole: userRole)});
    if (auth.hasPermission('events', 'canView')) modules.add({"title": "Events", "icon": Icons.celebration_outlined, "screen": EventsScreen(userRole: userRole, currentUserName: auth.getCurrentUser()?.fullName ?? "User")});
    if (auth.hasPermission('digitalid', 'canView')) modules.add({"title": "Digital ID", "icon": Icons.badge_outlined, "screen": const DigitalIdScreen()});
    if (auth.hasPermission('campusmap', 'canView')) modules.add({"title": "Campus Map", "icon": Icons.map_outlined, "screen": const MapScreen()});
    if (auth.hasPermission('attendance', 'canView')) modules.add({"title": "Exams", "icon": Icons.assignment_turned_in_outlined, "screen": const ExaminationScreen()});
    if (auth.hasPermission('attendance', 'canView')) modules.add({"title": "Fees", "icon": Icons.account_balance_wallet_outlined, "screen": const FeesScreen()});
    if (auth.hasPermission('attendance', 'canView')) modules.add({"title": "Hostel", "icon": Icons.apartment_outlined, "screen": const HostelScreen()});
    
    if (auth.hasPermission('analytics', 'canView')) modules.add({"title": "Analytics", "icon": Icons.insights_outlined, "screen": AnalyticsDashboardScreen()});
    
    // 👇 FIX: Admin Panel condition checking actual user role from DB
    if (user?.role == UserRole.hod || user?.role == UserRole.principal) {
      modules.add({"title": "Admin Panel", "icon": Icons.admin_panel_settings_outlined, "screen": const AdminPanelScreen()});
    }

    modules.add({"title": "Profile", "icon": Icons.person_outline, "screen": ProfileScreen(role: userRole)});
    modules.add({"title": "Settings", "icon": Icons.settings_outlined, "screen": const SettingsScreen()});

    // Generate Tiles
    return modules.map((m) {
      return _drawerTile(
        context,
        m["icon"] as IconData,
        m["title"] as String,
        () {
          Navigator.pop(context); // Close drawer
          Navigator.push(context, MaterialPageRoute(builder: (_) => m["screen"] as Widget));
        },
      );
    }).toList();
  }

  // ============================================================
  //  REUSABLE UI ELEMENTS
  // ============================================================
  Widget _drawerTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isLogout ? Colors.red : _primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isLogout ? Colors.red : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterVersion() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Center(
        child: Text(
          "Campus Digital Twin AI\nv1.0.0 (Build 2024.12.01)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600, height: 1.5),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Logout?", style: TextStyle(fontWeight: FontWeight.w800, color: _textDark)),
        content: const Text("Are you sure you want to log out from the Campus Digital Twin AI app?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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