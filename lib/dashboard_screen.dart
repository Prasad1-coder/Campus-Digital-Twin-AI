import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'drawer_widget.dart';
import 'admin_panel_screen.dart';
import 'services/hod/subject_management_screen.dart';
import 'services/hod/teacher_assignment_screen.dart';

// ---------- Same colour palette (unchanged) ----------
const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _accent = Color(0xFF42A5F5);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

// Helpers so light + dark mode both look good
Color _tintOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _primary.withOpacity(0.20) : _softBlue;

Color _iconOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _accent : _primary;

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
  String get _fullName => _currentUser?.fullName ?? "Guest";
  String get _initial => _userName.isNotEmpty ? _userName[0].toUpperCase() : "G";

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
  void _openHostel() => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostelScreen()));
  void _openAdminPanel() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));

  void _openSubjectManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubjectManagementScreen(),
      ),
    );
  }

  void _openTeacherAssignments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TeacherAssignmentScreen(),
      ),
    );
  }

  void _openSearch() => Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalSearchScreen()));
  void _openNotifications() => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));

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
      list.add({"title": "Hostel", "icon": Icons.apartment_outlined, "action": _openHostel});
    }

    if (_currentUser?.role == UserRole.hod) {
      list.add({
        "title": "Subject Management",
        "icon": Icons.menu_book_outlined,
        "action": _openSubjectManagement,
      });
      list.add({
        "title": "Teacher Assignment",
        "icon": Icons.assignment_ind_outlined,
        "action": _openTeacherAssignments,
      });
    }

    if (_currentUser?.role == UserRole.hod || _currentUser?.role == UserRole.principal) {
      list.add({"title": "Admin Panel", "icon": Icons.admin_panel_settings_outlined, "action": _openAdminPanel});
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

  // =====================================================================
  //                               BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navItems = _navItems; // computed once per build
    final screens = _screens;
    final int safeIndex = _selectedIndex < navItems.length ? _selectedIndex : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 66,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        // Flat gradient - it flows straight into the header card below
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryDark, _primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: "Menu",
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: safeIndex == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _greeting,
                    style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Text(
                navItems[safeIndex].label!,
                style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: "Search",
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.14)),
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: _openSearch,
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: "Notifications",
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.14)),
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: _openNotifications,
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: AppDrawer(
        userRole: widget.userRole,
        currentNavigatorIndex: _selectedIndex,
        onItemTapped: (index) {
          _onNavTap(index);
        },
      ),
      // Hide the floating nav while the keyboard is open (AI chat input stays above the keyboard)
      bottomNavigationBar: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : _buildFloatingNav(navItems, safeIndex),
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
    );
  }

  // =====================================================================
  //                        FLOATING PILL NAV BAR
  // =====================================================================
  Widget _buildFloatingNav(List<BottomNavigationBarItem> items, int current) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(items.length, (i) {
            final selected = i == current;
            final iconData = (items[i].icon as Icon).icon;
            return Expanded(
              flex: selected ? 2 : 1, // selected tab gets more room for its label
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _onNavTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: selected ? _primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData,
                          size: 22,
                          color: selected ? Colors.white : theme.hintColor,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              items[i].label ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // =====================================================================
  //                              HOME TAB
  // =====================================================================
  Widget _buildHomeContent() {
    return SafeArea(
      bottom: false, // Scaffold already reserves space for the nav bar (extendBody)
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card + stats strip that overlaps its bottom edge
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildHeaderCard(),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: -38,
                  child: _buildQuickStats(),
                ),
              ],
            ),
            const SizedBox(height: 62),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModuleGrid(),
                  const SizedBox(height: 26),
                  _buildHomeDashboardSections(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Header: blueprint-style identity panel ----------
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Campus "digital twin" blueprint grid in the background
          Positioned.fill(child: CustomPaint(painter: _BlueprintPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Text(
                        _initial,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _designation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.28)),
                      ),
                      child: Text(
                        _roleString,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.apartment_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _college,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _department,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Stats: one joined strip instead of 3 separate cards ----------
  Widget _buildQuickStats() {
    final theme = Theme.of(context);
    List<Map<String, dynamic>> stats = [];
    if (widget.userRole == UserRole.student) {
      stats = [
        {"title": "Attendance", "value": "85%", "icon": Icons.percent, "color": Colors.green},
        {"title": "CGPA", "value": "8.4", "icon": Icons.star_rounded, "color": Colors.orange},
        {"title": "Books Due", "value": "1", "icon": Icons.menu_book_rounded, "color": Colors.red},
      ];
    } else {
      stats = [
        {"title": "Classes", "value": "4", "icon": Icons.schedule, "color": Colors.blue},
        {"title": "Leaves", "value": "0", "icon": Icons.event_busy, "color": Colors.green},
        {"title": "Pending", "value": "2", "icon": Icons.pending_actions, "color": Colors.orange},
      ];
    }

    final List<Widget> cells = [];
    for (int i = 0; i < stats.length; i++) {
      final s = stats[i];
      final Color c = s['color'] as Color;
      if (i > 0) {
        cells.add(Container(width: 1, height: 40, color: theme.dividerColor));
      }
      cells.add(
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(s['icon'] as IconData, color: c, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    s['value'] as String,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s['title'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: theme.hintColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(children: cells),
    );
  }

  // ---------- Quick Access: launcher-style icon tiles ----------
  Widget _buildModuleGrid() {
    final theme = Theme.of(context);
    final modules = _modules; // computed once
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Quick Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
            ),
            const Spacer(),
            Text(
              "${modules.length} modules",
              style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            mainAxisExtent: 102,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];
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

  // ---------- Notices / Events / AI tip ----------
  Widget _buildHomeDashboardSections() {
    final theme = Theme.of(context);

    const notices = [
      {"title": "Campus Workshop on AI & ML", "time": "2 hours ago"},
      {"title": "Placement Drive - TCS Digital", "time": "5 hours ago"},
    ];

    const events = [
      {"day": "15", "month": "Dec", "title": "Tech Fest 2024", "place": "Auditorium"},
      {"day": "20", "month": "Dec", "title": "Annual Sports Day", "place": "Ground"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasAccess('notice', 'canView')) ...[
          _buildSectionHeader("Recent Notices", Icons.campaign_outlined, _openNotice),
          const SizedBox(height: 10),
          // All notices live inside ONE grouped list (not separate cards)
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < notices.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 68, color: theme.dividerColor.withOpacity(0.7)),
                  _buildNoticeCard(notices[i]["title"]!, notices[i]["time"]!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
        ],

        if (_hasAccess('events', 'canView')) ...[
          _buildSectionHeader("Upcoming Events", Icons.celebration_outlined, _openEvents),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final e = events[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _openEvents,
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        // Calendar-style date block
                        Container(
                          width: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                e["day"]!,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1),
                              ),
                              Text(
                                e["month"]!,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                e["title"]!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: theme.colorScheme.onSurface),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: theme.hintColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      e["place"]!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 26),
        ],

        _buildSectionHeader("AI Suggestions", Icons.smart_toy_outlined, _openAI),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_textDark, Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: const Color(0xFF3949AB).withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _openAI,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's tip",
                            style: TextStyle(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          _isLoadingAi
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: const LinearProgressIndicator(
                                    minHeight: 4,
                                    color: Colors.white,
                                    backgroundColor: Colors.white24,
                                  ),
                                )
                              : Text(
                                  _aiSuggestion,
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Section header with "See all" pill ----------
  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: _iconOf(theme)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            decoration: BoxDecoration(
              color: _tintOf(theme),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("See all", style: TextStyle(color: _iconOf(theme), fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: _iconOf(theme)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- One row inside the grouped notice list ----------
  Widget _buildNoticeCard(String title, String time) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _openNotice,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _tintOf(theme),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.campaign_rounded, color: _iconOf(theme), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text(time, style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//        Blueprint background (grid + radar rings) for header
// =====================================================================
class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fine grid
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Concentric rings in the top-right corner
    final ring = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width - 30, 24);
    for (final r in [36.0, 64.0, 92.0]) {
      canvas.drawCircle(center, r, ring);
    }

    // Small "nodes" sitting on the rings
    final dot = Paint()..color = Colors.white.withOpacity(0.45);
    canvas.drawCircle(Offset(center.dx - 36, center.dy), 3, dot);
    canvas.drawCircle(Offset(center.dx, center.dy + 64), 3, dot);
    canvas.drawCircle(Offset(center.dx - 92, center.dy), 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =====================================================================
//                 Reusable Dashboard Tile (launcher style)
// =====================================================================
class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _tintOf(theme),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _primary.withOpacity(0.10)),
              ),
              child: Icon(icon, size: 26, color: _iconOf(theme)),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}