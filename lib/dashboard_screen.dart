import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter;
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
import 'global_search_screen.dart';
import 'notification_screen.dart';
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'permission_model.dart';
import 'fees_screen.dart';
import 'hostel_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  final UserRole userRole;

  const DashboardScreen({super.key, required this.userRole});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  String _aiSuggestion = "Fetching a personalized tip for you...";
  bool _isLoadingAi = true;

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  PermissionModel? get _permissions => _authService.getCurrentPermissions();

  @override
  void initState() {
    super.initState();
    _fetchAiSuggestion();
  }

  Future<void> _fetchAiSuggestion() async {
    try {
      String role = widget.userRole.name;
      String prompt = "Give one short (max 15 words), highly encouraging and actionable tip for a $role to improve their campus life and studies. Do not include any conversational filler, just the tip.";
      String reply = await GeminiService.askAI(prompt);
      
      if (mounted) {
        setState(() {
          _aiSuggestion = reply.isNotEmpty ? reply : "Stay focused and make the most of your campus resources today!";
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSuggestion = widget.userRole == UserRole.student 
              ? "Your attendance is below 75%. Attend the next class to avoid debarment." 
              : "You have 2 pending leave approvals. Review them in the Attendance section.";
          _isLoadingAi = false;
        });
      }
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String get _userName => _currentUser?.fullName.split(' ').first ?? "Guest";
  
  String get _roleString {
    final role = _currentUser?.role.name;
    if (role == null || role.isEmpty) return "Guest";
    return role[0].toUpperCase() + role.substring(1);
  }
  
  String get _department => _currentUser?.department ?? "Department";
  String get _designation => _currentUser?.designation ?? "Role";
  String get _college => "XYZ Campus of Excellence";
  String get _email => _currentUser?.email ?? "guest@campus.edu";

  bool _hasAccess(String module, String action) {
    return _authService.hasPermission(module, action);
  }

  // ---------- Navigation Helpers ----------
  void _openAI() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIScreen()));
  void _openMap() => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
  void _openTimetable() => Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableScreen(userRole: widget.userRole)));
  void _openProfile() => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(role: widget.userRole)));
  void _openAttendance() => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(userRole: widget.userRole, currentUserName: _userName)));
  void _openLibrary() => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen()));
  void _openCanteen() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanteenScreen()));
  void _openSettings() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  void _openNotice() => Navigator.push(context, MaterialPageRoute(builder: (_) => NoticeScreen(userRole: widget.userRole)));
  void _openEvents() => Navigator.push(context, MaterialPageRoute(builder: (_) => EventsScreen(userRole: widget.userRole, currentUserName: _userName)));
  void _openDigitalId() => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalIdScreen()));
  void _openPlacement() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlacementDashboardScreen()));
  void _openExams() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExaminationScreen()));
  void _openAnalytics() => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsDashboardScreen()));
  void _openFees() => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
  void _openHostel() => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostelScreen())); // 👈 FIX: Added function here
  
  void _openSearch() => Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalSearchScreen()));
  void _openNotifications() => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Logout?", style: TextStyle(fontWeight: flutter.FontWeight.bold, color: _textDark)),
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

  List<Map<String, dynamic>> get _modules {
    final List<Map<String, dynamic>> list = [];
    
    if (_hasAccess('aiassistant', 'canView')) {
      list.add({"title": "AI Assistant", "icon": Icons.smart_toy_outlined, "action": _openAI});
    }
    if (_hasAccess('attendance', 'canView')) {
      list.add({"title": widget.userRole == UserRole.student ? "My Attendance" : "Attendance", "icon": Icons.fact_check_outlined, "action": _openAttendance});
    }
    if (_hasAccess('timetable', 'canView')) {
      list.add({"title": "Timetable", "icon": Icons.calendar_month_outlined, "action": _openTimetable});
    }
    if (_hasAccess('library', 'canView')) {
      list.add({"title": "Library", "icon": Icons.menu_book_outlined, "action": _openLibrary});
    }
    if (_hasAccess('canteen', 'canView')) {
      list.add({"title": "Canteen", "icon": Icons.restaurant_outlined, "action": _openCanteen});
    }
    if (_hasAccess('placement', 'canView')) {
      list.add({"title": "Placement", "icon": Icons.work_outline, "action": _openPlacement});
    }
    if (_hasAccess('notice', 'canView')) {
      list.add({"title": "Notices", "icon": Icons.campaign_outlined, "action": _openNotice});
    }
    if (_hasAccess('events', 'canView')) {
      list.add({"title": "Events", "icon": Icons.celebration_outlined, "action": _openEvents});
    }
    if (_hasAccess('digitalid', 'canView')) {
      list.add({"title": "Digital ID", "icon": Icons.badge_outlined, "action": _openDigitalId});
    }
    if (_hasAccess('campusmap', 'canView')) {
      list.add({"title": "Campus Map", "icon": Icons.map_outlined, "action": _openMap});
    }
    if (_hasAccess('analytics', 'canView')) {
      list.add({"title": "Analytics", "icon": Icons.insights_outlined, "action": _openAnalytics});
    }
    if (_hasAccess('studentmanagement', 'canView')) {
      list.add({"title": "Students", "icon": Icons.groups_outlined, "action": _openAttendance});
    }
    if (_hasAccess('reports', 'canView')) {
      list.add({"title": "Reports", "icon": Icons.summarize_outlined, "action": _openAnalytics});
    }
    if (_hasAccess('attendance', 'canView')) {
      list.add({"title": "Exams", "icon": Icons.assignment_turned_in_outlined, "action": _openExams});
    }
    if (_hasAccess('attendance', 'canView')) { 
      list.add({"title": "Fees", "icon": Icons.account_balance_wallet_outlined, "action": _openFees});
    }
    if (_hasAccess('attendance', 'canView')) { 
      list.add({"title": "Hostel", "icon": Icons.apartment_outlined, "action": _openHostel}); // 👈 FIX: Added Hostel to list
    }
    
    list.add({"title": "Profile", "icon": Icons.person_outline, "action": _openProfile});
    list.add({"title": "Settings", "icon": Icons.settings_outlined, "action": _openSettings});
    
    return list;
  }

  List<BottomNavigationBarItem> get _navItems {
    List<BottomNavigationBarItem> items = [];
    
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"));
    
    if (_hasAccess('aiassistant', 'canView')) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: "AI"));
    }
    
    if (_hasAccess('attendance', 'canView')) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: "Attendance"));
    } else if (_hasAccess('analytics', 'canView')) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: "Analytics"));
    }
    
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"));
    
    return items;
  }

  List<Widget> get _screens {
    List<Widget> screens = [_buildHomeContent()];
    
    if (_hasAccess('aiassistant', 'canView')) {
      screens.add(const AIScreen());
    }
    if (_hasAccess('attendance', 'canView')) {
      screens.add(AttendanceScreen(userRole: widget.userRole, currentUserName: _userName));
    } else if (_hasAccess('analytics', 'canView')) {
      screens.add(AnalyticsDashboardScreen());
    }
    
    screens.add(ProfileScreen(role: widget.userRole));
    
    return screens;
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    int safeIndex = _selectedIndex < _navItems.length ? _selectedIndex : 0;

    return Scaffold(
      backgroundColor: _lightBg,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryDark, _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          safeIndex == 0 ? "$_greeting, $_userName 👋" : _navItems[safeIndex].label!,
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: flutter.FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: _openSearch),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: _openNotifications),
        ],
      ),
      drawer: _buildSmartDrawer(),
      bottomNavigationBar: _buildCleanBottomNav(),
      body: IndexedStack(
        index: safeIndex,
        children: _screens,
      ),
    );
  }

  Widget _buildCleanBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex < _navItems.length ? _selectedIndex : 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _primary,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: TextStyle(fontWeight: flutter.FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: flutter.FontWeight.normal),
          showUnselectedLabels: true,
          elevation: 0,
          onTap: _onNavTap,
          items: _navItems,
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildModuleGrid(),
            const SizedBox(height: 24),
            _buildHomeDashboardSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: flutter.FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_designation, style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: flutter.FontWeight.normal)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_roleString, style: TextStyle(color: Colors.white, fontWeight: flutter.FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            children: [
              const Icon(Icons.apartment_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_college, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: flutter.FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.school_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_department, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: flutter.FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    List<Map<String, dynamic>> stats = [];
    if (widget.userRole == UserRole.student) {
      stats = [
        {"title": "Attendance", "value": "85%", "icon": Icons.percent, "color": Colors.green},
        {"title": "CGPA", "value": "8.4", "icon": Icons.star, "color": Colors.orange},
        {"title": "Books Due", "value": "1", "icon": Icons.menu_book, "color": Colors.red},
      ];
    } else {
      stats = [
        {"title": "Classes", "value": "4", "icon": Icons.schedule, "color": Colors.blue},
        {"title": "Leaves", "value": "0", "icon": Icons.event_busy, "color": Colors.green},
        {"title": "Pending", "value": "2", "icon": Icons.pending_actions, "color": Colors.orange},
      ];
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final s = stats[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: (s['color'] as Color).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: (s['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 16),
                ),
                const SizedBox(height: 8),
                Text(s['value'] as String, style: TextStyle(fontSize: 18, fontWeight: flutter.FontWeight.bold, color: _textDark)),
                Flexible(
                  child: Text(
                    s['title'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: flutter.FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModuleGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Access", style: TextStyle(fontSize: 17, fontWeight: flutter.FontWeight.bold, color: _textDark)),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _modules.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final module = _modules[index];
            return _DashboardCard(
              title: module["title"] as String,
              icon: module["icon"] as IconData,
              onTap: module["action"] as VoidCallback,
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeDashboardSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasAccess('notice', 'canView')) ...[
          _buildSectionHeader("Recent Notices", Icons.campaign_outlined, _openNotice),
          const SizedBox(height: 8),
          _buildNoticeCard("Campus Workshop on AI & ML", "2 hours ago"),
          _buildNoticeCard("Placement Drive - TCS Digital", "5 hours ago"),
          const SizedBox(height: 20),
        ],

        if (_hasAccess('events', 'canView')) ...[
          _buildSectionHeader("Upcoming Events", Icons.celebration_outlined, _openEvents),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return Container(
                  width: 240,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.event, color: _primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(index == 0 ? "Tech Fest 2024" : "Annual Sports Day", style: TextStyle(fontWeight: flutter.FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(index == 0 ? "15 Dec, Auditorium" : "20 Dec, Ground", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        _buildSectionHeader("AI Suggestions", Icons.smart_toy_outlined, _openAI),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openAI,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoadingAi
                      ? const LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.white24)
                      : Text(
                          _aiSuggestion,
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: flutter.FontWeight.normal),
                        ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: _primary),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: flutter.FontWeight.bold, color: _textDark)),
          ],
        ),
        TextButton(onPressed: onTap, child: Text("See All", style: TextStyle(color: _primary, fontWeight: flutter.FontWeight.bold)))
      ],
    );
  }

  Widget _buildNoticeCard(String title, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(width: 4, height: 30, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: flutter.FontWeight.bold, color: Colors.black87)),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSmartDrawer() {
    return Drawer(
      backgroundColor: _lightBg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(),
                const SizedBox(height: 8),
                _drawerTile(Icons.home_outlined, "Home", () { Navigator.pop(context); setState(() => _selectedIndex = 0); }),
                ..._modules.map((m) => _drawerTile(m["icon"] as IconData, m["title"] as String, () {
                  Navigator.pop(context);
                  (m["action"] as VoidCallback)();
                })),
                const Divider(height: 24, indent: 16, endIndent: 16),
                _drawerTile(Icons.help_outline, "Help & Support", () {}),
                _drawerTile(Icons.info_outline, "About Application", () {}),
                _drawerTile(Icons.logout, "Logout", _showLogoutDialog, isLogout: true),
              ],
            ),
          ),
          _buildDrawerFooterVersion(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 35, color: _primary),
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
                        _userName,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: flutter.FontWeight.bold),
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
                          _roleString,
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: flutter.FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            _headerRow(Icons.apartment, _college),
            const SizedBox(height: 6),
            _headerRow(Icons.school_outlined, _department),
            const SizedBox(height: 6),
            _headerRow(Icons.email_outlined, _email),
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
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: flutter.FontWeight.normal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerFooterVersion() {
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
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: flutter.FontWeight.normal, height: 1.5),
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
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
                    fontWeight: flutter.FontWeight.normal,
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
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                child: Icon(icon, size: 26, color: const Color(0xFF1565C0)),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: flutter.FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}