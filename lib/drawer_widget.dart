import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'digital_id_screen.dart';
import 'ai_screen.dart';
import 'attendance_screen.dart';
import 'timetable_screen.dart';
import 'library_screen.dart';
import 'canteen_screen.dart';
import 'notice_screen.dart';
import 'events_screen.dart';
import 'placement_dashboard_screen.dart';
import 'analytics_dashboard.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class DrawerWidget extends StatelessWidget {
  final UserRole userRole;
  final int currentNavigatorIndex;

  const DrawerWidget({
    super.key,
    required this.userRole,
    this.currentNavigatorIndex = 0,
  });

  // Theme Constants
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
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
          _buildHeader(user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionTitle("Main Menu"),
                _buildTile(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: "Dashboard",
                  onTap: () => _navigateTo(context, const DashboardScreen(userRole: userRole)),
                ),
                _buildTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: "My Profile",
                  onTap: () => _navigateTo(context, ProfileScreen(role: userRole)),
                ),
                _buildTile(
                  context,
                  icon: Icons.badge_outlined,
                  title: "Digital ID",
                  onTap: () => _navigateTo(context, DigitalIdScreen(userRole: userRole)),
                ),
                _buildTile(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: "AI Assistant",
                  badge: "AI",
                  onTap: () => _navigateTo(context, const AIScreen()),
                ),
                _buildTile(
                  context,
                  icon: Icons.map_outlined,
                  title: "Campus Map",
                  onTap: () => _navigateTo(context, const MapScreen()),
                ),
                
                // Role & Permission Based Menus
                if (_authService.hasPermission('attendance', 'canView')) ...[
                  _buildSectionTitle("Academics"),
                  _buildTile(
                    context,
                    icon: Icons.fact_check_outlined,
                    title: userRole == UserRole.student ? "My Attendance" : "Attendance Mgmt",
                    onTap: () => _navigateTo(context, AttendanceScreen(userRole: userRole, currentUserName: user?.fullName ?? "User")),
                  ),
                ],
                if (_authService.hasPermission('timetable', 'canView')) ...[
                  _buildTile(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: "Timetable",
                    onTap: () => _navigateTo(context, TimetableScreen(userRole: userRole)),
                  ),
                ],
                
                _buildSectionTitle("Campus Life"),
                if (_authService.hasPermission('library', 'canView')) ...[
                  _buildTile(
                    context,
                    icon: Icons.menu_book_outlined,
                    title: "Library",
                    onTap: () => _navigateTo(context, const LibraryScreen()),
                  ),
                ],
                if (_authService.hasPermission('canteen', 'canView')) ...[
                  _buildTile(
                    context,
                    icon: Icons.restaurant_outlined,
                    title: "Canteen",
                    onTap: () => _navigateTo(context, const CanteenScreen()),
                  ),
                ],
                if (_authService.hasPermission('notice', 'canView')) ...[
                  _buildTile(
                    context,
                    icon: Icons.campaign_outlined,
                    title: "Notices",
                    badge: "2", // Dummy badge
                    onTap: () => _navigateTo(context, NoticeScreen(userRole: userRole)),
                  ),
                ],
                if (_authService.hasPermission('events', 'canView')) ...[
                  _buildTile(
                    context,
                    icon: Icons.celebration_outlined,
                    title: "Events",
                    onTap: () => _navigateTo(context, EventsScreen(userRole: userRole, currentUserName: user?.fullName ?? "User")),
                  ),
                ],
                if (_authService.hasPermission('placement', 'canView')) ...[
                  _buildTile(
                    context,
                    icon: Icons.work_outline,
                    title: "Placement Portal",
                    onTap: () => _navigateTo(context, const PlacementDashboardScreen()),
                  ),
                ],

                // Admin & Management
                if (_authService.hasPermission('analytics', 'canView') || _authService.hasPermission('reports', 'canView')) ...[
                  _buildSectionTitle("Administration"),
                  if (_authService.hasPermission('analytics', 'canView')) ...[
                    _buildTile(
                      context,
                      icon: Icons.insights_outlined,
                      title: userRole == UserRole.principal ? "College Analytics" : "Dept Analytics",
                      onTap: () => _navigateTo(context, const AnalyticsDashboardScreen()),
                    ),
                  ],
                  if (_authService.hasPermission('userManagement', 'canView')) ...[
                    _buildTile(
                      context,
                      icon: Icons.people_alt_outlined,
                      title: "User Management",
                      onTap: () => _navigateTo(context, const AnalyticsDashboardScreen()), // Placeholder route
                    ),
                  ],
                  if (_authService.hasPermission('roleManagement', 'canView')) ...[
                    _buildTile(
                      context,
                      icon: Icons.manage_accounts_outlined,
                      title: "Role Management",
                      onTap: () => _navigateTo(context, const AnalyticsDashboardScreen()), // Placeholder route
                    ),
                  ],
                ],

                _buildSectionTitle("System"),
                _buildTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () => _navigateTo(context, const SettingsScreen()),
                ),
                _buildTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: "Help & Support",
                  onTap: () => _showSnack(context, "Help & Support coming soon!"),
                ),
                _buildTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: "About App",
                  onTap: () => _showSnack(context, "Campus Digital Twin AI v1.0.0"),
                ),
                const SizedBox(height: 16),
                _buildTile(
                  context,
                  icon: Icons.logout,
                  title: "Logout",
                  isLogout: true,
                  onTap: () => _showLogoutDialog(context, _authService),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showSnack(BuildContext context, String msg) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showLogoutDialog(BuildContext context, AuthService _authService) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Logout?", style: TextStyle(fontWeight: FontWeight.w800, color: _textDark)),
        content: const Text("Are you sure you want to log out from the Campus Digital Twin AI app?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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

  // ============================================================
  //  WIDGETS
  // ============================================================

  Widget _buildHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: _softBlue,
                      backgroundImage: user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
                      child: user?.profileImageUrl == null
                          ? const Icon(Icons.person, size: 35, color: _primary)
                          : null,
                    ),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? "Guest User",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "ID: ${user?.collegeId ?? 'N/A'}",
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user?.role.name.toUpperCase() ?? "STUDENT",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user?.department ?? "Department of Computer Engineering",
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, String? badge, bool isLogout = false}) {
    Color tileColor = isLogout ? Colors.red.shade50 : Colors.white;
    Color iconColor = isLogout ? Colors.red : _primary;
    Color textColor = isLogout ? Colors.red : _textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLogout ? Colors.red.withOpacity(0.1) : _softBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  )
                else if (!isLogout)
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
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
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600, height: 1.5),
        ),
      ),
    );
  }
}