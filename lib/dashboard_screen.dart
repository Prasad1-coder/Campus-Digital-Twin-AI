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
import 'analytics_dashboard.dart';
import 'settings_screen.dart';
import 'canteen_screen.dart';
import 'placement_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'drawer_widget.dart';
import 'admin_panel_screen.dart';
import 'services/hod/subject_management_screen.dart';
import 'services/hod/teacher_assignment_screen.dart';
import 'global_search_screen.dart';
import 'notification_screen.dart';

// ------------------------------------------------------------
// COLORS & SHARED HELPERS
// ------------------------------------------------------------

const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _accent = Color(0xFF42A5F5);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

bool _isDark(ThemeData t) => t.brightness == Brightness.dark;
Color _tintOf(ThemeData t) => _isDark(t) ? _primary.withValues(alpha: 0.20) : _softBlue;
Color _iconOf(ThemeData t) => _isDark(t) ? _accent : _primary;

/// Rounded themed card with a soft border (used by stats, nav bar, empty sections).
BoxDecoration _box(ThemeData t, {double radius = 20, List<BoxShadow>? shadow}) => BoxDecoration(
      color: t.cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: t.dividerColor.withValues(alpha: 0.6)),
      boxShadow: shadow,
    );

List<BoxShadow> _shadow(Color c, double alpha, double blur, double dy) =>
    [BoxShadow(color: c.withValues(alpha: alpha), blurRadius: blur, offset: Offset(0, dy))];

// ------------------------------------------------------------
// DASHBOARD
// ------------------------------------------------------------

class DashboardScreen extends StatefulWidget {
  final UserRole userRole;

  const DashboardScreen({super.key, required this.userRole});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();

  int _selectedIndex = 0;
  String _aiSuggestion = 'Preparing a helpful tip for you...';
  bool _isLoadingAi = true;

  UserModel? get _currentUser => _authService.getCurrentUser();
  ThemeData get _theme => Theme.of(context);

  @override
  void initState() {
    super.initState();
    _fetchAiSuggestion();
  }

  // ----------------------------------------------------------
  // AI SUGGESTION
  // ----------------------------------------------------------

  Future<void> _fetchAiSuggestion() async {
    const fallback =
        'Stay consistent, review your progress, and make the most of your campus resources.';

    String tip = fallback;
    try {
      final reply = (await GeminiService.askAI(
        'Give one encouraging, actionable campus-life tip for a '
        '${widget.userRole.name}. Use no more than 15 words. '
        'Do not add conversational filler.',
      ))
          .trim();
      if (reply.isNotEmpty) tip = reply;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _aiSuggestion = tip;
      _isLoadingAi = false;
    });
  }

  // ----------------------------------------------------------
  // USER DETAILS
  // ----------------------------------------------------------

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _fullName {
    final name = _currentUser?.fullName.trim() ?? '';
    return name.isEmpty ? 'Guest' : name;
  }

  String get _userName => _fullName.split(RegExp(r'\s+')).first;

  String get _initial => _userName[0].toUpperCase();

  String get _roleString {
    final role = _currentUser?.role.name;
    if (role == null || role.isEmpty) return 'Guest';
    return role[0].toUpperCase() + role.substring(1);
  }

  String get _department {
    final d = _currentUser?.department.trim() ?? '';
    return d.isEmpty ? 'Department not specified' : d;
  }

  String get _designation {
    final d = _currentUser?.designation.trim() ?? '';
    return d.isEmpty ? _roleString : d;
  }

  bool _hasAccess(String module, [String action = 'canView']) =>
      _authService.hasPermission(module, action);

  // ----------------------------------------------------------
  // NAVIGATION
  // ----------------------------------------------------------

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _openAI() => _push(const AIScreen());
  void _openNotice() => _push(NoticeScreen(userRole: widget.userRole));
  void _openEvents() =>
      _push(EventsScreen(userRole: widget.userRole, currentUserName: _userName));
  void _openAttendance() =>
      _push(AttendanceScreen(userRole: widget.userRole, currentUserName: _userName));
  void _openAnalytics() => _push(AnalyticsDashboardScreen());

  // ----------------------------------------------------------
  // MODULES (quick access grid)
  // ----------------------------------------------------------

  List<(String, IconData, VoidCallback)> get _modules {
    final role = _currentUser?.role;

    // (permission, title, icon, action)
    final permitted = <(String, String, IconData, VoidCallback)>[
      ('aiassistant', 'AI Assistant', Icons.smart_toy_outlined, _openAI),
      (
        'attendance',
        widget.userRole == UserRole.student ? 'My Attendance' : 'Attendance',
        Icons.fact_check_outlined,
        _openAttendance
      ),
      (
        'timetable',
        'Timetable',
        Icons.calendar_month_outlined,
        () => _push(TimetableScreen(userRole: widget.userRole))
      ),
      ('library', 'Library', Icons.menu_book_outlined, () => _push(const LibraryScreen())),
      ('canteen', 'Canteen', Icons.restaurant_outlined, () => _push(const CanteenScreen())),
      (
        'placement',
        'Placement',
        Icons.work_outline,
        () => _push(const PlacementDashboardScreen())
      ),
      ('notice', 'Notices', Icons.campaign_outlined, _openNotice),
      ('events', 'Events', Icons.celebration_outlined, _openEvents),
      ('digitalid', 'Digital ID', Icons.badge_outlined, () => _push(const DigitalIdScreen())),
      ('campusmap', 'Campus Map', Icons.map_outlined, () => _push(const MapScreen())),
      ('analytics', 'Analytics', Icons.insights_outlined, _openAnalytics),
      ('studentmanagement', 'Students', Icons.groups_outlined, _openAttendance),
      ('reports', 'Reports', Icons.summarize_outlined, _openAnalytics),
      // Exams, Fees and Hostel are intentionally omitted until
      // dedicated permission rules are defined in PermissionModel.
    ];

    return [
      for (final m in permitted)
        if (_hasAccess(m.$1)) (m.$2, m.$3, m.$4),
      if (role == UserRole.hod) ...[
        (
          'Subject Management',
          Icons.menu_book_outlined,
          () => _push(const SubjectManagementScreen())
        ),
        (
          'Teacher Assignment',
          Icons.assignment_ind_outlined,
          () => _push(const TeacherAssignmentScreen())
        ),
      ],
      if (role == UserRole.hod || role == UserRole.principal)
        (
          'Admin Panel',
          Icons.admin_panel_settings_outlined,
          () => _push(const AdminPanelScreen())
        ),
      ('Profile', Icons.person_outline, () => _push(ProfileScreen(role: widget.userRole))),
      ('Settings', Icons.settings_outlined, () => _push(const SettingsScreen())),
    ];
  }

  // ----------------------------------------------------------
  // BOTTOM NAV TABS  (label, icon, lazy screen builder)
  // ----------------------------------------------------------

  List<(String, IconData, Widget Function())> get _tabs => [
        ('Home', Icons.home_outlined, _buildHomeContent),
        if (_hasAccess('aiassistant'))
          ('AI', Icons.smart_toy_outlined, () => const AIScreen()),
        if (_hasAccess('attendance'))
          (
            'Attendance',
            Icons.fact_check_outlined,
            () => AttendanceScreen(userRole: widget.userRole, currentUserName: _userName)
          )
        else if (_hasAccess('analytics'))
          ('Analytics', Icons.insights_outlined, () => AnalyticsDashboardScreen()),
        ('Profile', Icons.person_outline, () => ProfileScreen(role: widget.userRole)),
      ];

  void _onNavTap(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() => _selectedIndex = index);
  }

  // ----------------------------------------------------------
  // MAIN BUILD
  // ----------------------------------------------------------

  Widget _appBarAction(String tooltip, IconData icon, VoidCallback onTap) => IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.14)),
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final safeIndex = _selectedIndex < tabs.length ? _selectedIndex : 0;

    return Scaffold(
      backgroundColor: _theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 66,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 0,
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
            tooltip: 'Menu',
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: safeIndex == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_greeting,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(_userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 19, color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              )
            : Text(tabs[safeIndex].$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 19, color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          _appBarAction('Search', Icons.search_rounded, () => _push(GlobalSearchScreen())),
          const SizedBox(width: 6),
          _appBarAction('Notifications', Icons.notifications_none_rounded,
              () => _push(NotificationScreen())),
          const SizedBox(width: 12),
        ],
      ),
      drawer: AppDrawer(
        userRole: widget.userRole,
        currentNavigatorIndex: _selectedIndex,
        onItemTapped: _onNavTap,
      ),
      bottomNavigationBar:
          MediaQuery.of(context).viewInsets.bottom > 0 ? null : _buildFloatingNav(tabs, safeIndex),
      body: IndexedStack(
        index: safeIndex,
        children: [for (final t in tabs) t.$3()],
      ),
    );
  }

  // ----------------------------------------------------------
  // FLOATING NAVIGATION BAR
  // ----------------------------------------------------------

  Widget _buildFloatingNav(List<(String, IconData, Widget Function())> tabs, int current) {
    final theme = _theme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(6),
        decoration: _box(theme, radius: 28, shadow: _shadow(_primary, 0.18, 24, 10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                flex: i == current ? 2 : 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _onNavTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: i == current ? _primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tabs[i].$2,
                              size: 22, color: i == current ? Colors.white : theme.hintColor),
                          if (i == current) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(tabs[i].$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HOME CONTENT
  // ----------------------------------------------------------

  Widget _buildHomeContent() => SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeaderCard(),
                  Positioned(left: 18, right: 18, bottom: -38, child: _buildQuickStats()),
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

  // ----------------------------------------------------------
  // HEADER CARD
  // ----------------------------------------------------------

  Widget _buildHeaderCard() => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _accent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          boxShadow: _shadow(_primary, 0.25, 20, 10),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _BlueprintPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Text(_initial,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(_designation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                        ),
                        child: Text(_roleString,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _headerDetail(Icons.apartment_outlined, 'Campus information unavailable'),
                  const SizedBox(height: 8),
                  _headerDetail(Icons.school_outlined, _department),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _headerDetail(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500)),
          ),
        ],
      );

  // ----------------------------------------------------------
  // QUICK STATS
  // ----------------------------------------------------------

  Widget _buildQuickStats() {
    final theme = _theme;

    // (title, icon, color) — values are placeholders until real data is wired.
    final stats = widget.userRole == UserRole.student
        ? const [
            ('Attendance', Icons.percent, Colors.green),
            ('CGPA', Icons.star_rounded, Colors.orange),
            ('Books Due', Icons.menu_book_rounded, Colors.red),
          ]
        : const [
            ('Classes', Icons.schedule, Colors.blue),
            ('Leaves', Icons.event_busy, Colors.green),
            ('Pending', Icons.pending_actions, Colors.orange),
          ];

    return Container(
      height: 84,
      decoration: _box(theme, radius: 22, shadow: _shadow(Colors.black, 0.08, 18, 8)),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) Container(width: 1, height: 40, color: theme.dividerColor),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(stats[i].$2, color: stats[i].$3, size: 16),
                      const SizedBox(width: 5),
                      Text('—',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(stats[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5, color: theme.hintColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // MODULE GRID
  // ----------------------------------------------------------

  Widget _buildModuleGrid() {
    final theme = _theme;
    final modules = _modules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Quick Access',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface)),
            const Spacer(),
            Text('${modules.length} modules',
                style: TextStyle(
                    fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w500)),
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
          itemBuilder: (_, i) => _DashboardCard(
            title: modules[i].$1,
            icon: modules[i].$2,
            onTap: modules[i].$3,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // HOME SECTIONS
  // ----------------------------------------------------------

  Widget _buildHomeDashboardSections() {
    // (permission, title, headerIcon, onTap, emptyIcon, emptyMessage)
    final infoSections = [
      (
        'notice',
        'Recent Notices',
        Icons.campaign_outlined,
        _openNotice,
        Icons.campaign_outlined,
        'Open Notices to view campus announcements.'
      ),
      (
        'events',
        'Upcoming Events',
        Icons.celebration_outlined,
        _openEvents,
        Icons.event_outlined,
        'Open Events to view campus activities.'
      ),
    ];

    final sections = <Widget>[
      for (final s in infoSections)
        if (_hasAccess(s.$1))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(s.$2, s.$3, s.$4),
              const SizedBox(height: 10),
              _buildEmptySection(icon: s.$5, message: s.$6),
            ],
          ),
      if (_hasAccess('aiassistant'))
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('AI Suggestions', Icons.smart_toy_outlined, _openAI),
            const SizedBox(height: 10),
            _buildAiTipCard(),
          ],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 26),
          sections[i],
        ],
      ],
    );
  }

  Widget _buildAiTipCard() => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_textDark, Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: _shadow(const Color(0xFF3949AB), 0.30, 14, 6),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _openAI,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's tip",
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        if (_isLoadingAi)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              minHeight: 4,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                          )
                        else
                          Text(_aiSuggestion,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13.5, height: 1.4)),
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
      );

  Widget _buildEmptySection({required IconData icon, required String message}) {
    final theme = _theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _box(theme),
      child: Row(
        children: [
          Icon(icon, color: _iconOf(theme), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: theme.hintColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onTap) {
    final theme = _theme;

    return Row(
      children: [
        Icon(icon, size: 20, color: _iconOf(theme)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface)),
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
                Text('See all',
                    style: TextStyle(
                        color: _iconOf(theme), fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: _iconOf(theme)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// BLUEPRINT HEADER BACKGROUND
// ------------------------------------------------------------

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.45);
    final center = Offset(size.width - 30, 24);

    for (final radius in [36.0, 64.0, 92.0]) {
      canvas.drawCircle(center, radius, ring);
    }
    for (final p in [
      Offset(center.dx - 36, center.dy),
      Offset(center.dx, center.dy + 64),
      Offset(center.dx - 92, center.dy),
    ]) {
      canvas.drawCircle(p, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------------
// DASHBOARD MODULE TILE
// ------------------------------------------------------------

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
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _tintOf(theme),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _primary.withValues(alpha: 0.10)),
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