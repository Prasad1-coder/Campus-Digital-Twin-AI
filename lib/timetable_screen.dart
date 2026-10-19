import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'user_role.dart';

// ---------- Same colour palette (unchanged) ----------
const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _accent = Color(0xFF42A5F5);
const Color _lightBg = Color(0xFFF5F9FF);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

// Helpers so light + dark mode both look good
Color _tintOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _primary.withOpacity(0.20) : _softBlue;

Color _iconOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _accent : _primary;

Color _headingOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : _textDark;

class TimetableScreen extends StatefulWidget {
  final UserRole userRole;

  const TimetableScreen({
    super.key,
    this.userRole = UserRole.student,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // =====================================================================
  // 1. DATA & HELPERS
  // =====================================================================
  final TextEditingController _searchController = TextEditingController();

  String _selectedDay = 'Monday';
  String _searchQuery = '';

  final List<String> _days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // NOTE: this is still one demo list for every day. Real per-day data
  // (class_schedules in Firestore) comes in a later phase; until then,
  // switching the day changes the heading and date, not the classes.
  final List<Map<String, dynamic>> _dailySchedule = [
    {
      'subject': 'Data Structures',
      'code': 'CS332',
      'teacher': 'Prof. Amit Sharma',
      'room': 'Room 204',
      'start': '09:00 AM',
      'end': '10:00 AM',
      'type': 'Lecture',
      'division': 'A',
      'semester': '3',
    },
    {
      'subject': 'Database Management System',
      'code': 'CS333',
      'teacher': 'Prof. Sneha Patil',
      'room': 'Lab 2',
      'start': '10:15 AM',
      'end': '11:15 AM',
      'type': 'Lab',
      'division': 'A',
      'semester': '3',
    },
    {
      'subject': 'Computer Networks',
      'code': 'CS334',
      'teacher': 'Prof. Rahul Deshmukh',
      'room': 'Room 305',
      'start': '11:30 AM',
      'end': '12:30 PM',
      'type': 'Lecture',
      'division': 'A',
      'semester': '3',
    },
    {
      'subject': 'Operating System',
      'code': 'CS335',
      'teacher': 'Prof. Neha Joshi',
      'room': 'Room 202',
      'start': '01:30 PM',
      'end': '02:30 PM',
      'type': 'Lecture',
      'division': 'A',
      'semester': '3',
    },
    {
      'subject': 'Python Programming',
      'code': 'CS336',
      'teacher': 'Prof. Sagar More',
      'room': 'Lab 1',
      'start': '02:45 PM',
      'end': '03:45 PM',
      'type': 'Practical',
      'division': 'A',
      'semester': '3',
    },
  ];

  final List<Map<String, dynamic>> _deptOverview = [
    {
      'department': 'Computer Science',
      'classes': 8,
      'lectures': 32,
      'faculty': 14,
    },
    {
      'department': 'Computer Applications',
      'classes': 6,
      'lectures': 24,
      'faculty': 10,
    },
    {
      'department': 'Information Technology',
      'classes': 7,
      'lectures': 28,
      'faculty': 12,
    },
  ];

  final List<Map<String, dynamic>> _facultyList = [
    {
      'name': 'Prof. Amit Sharma',
      'department': 'Computer Science',
      'subject': 'Data Structures',
      'room': 'Room 204',
      'time': '09:00 AM - 10:00 AM',
    },
    {
      'name': 'Prof. Sneha Patil',
      'department': 'Computer Science',
      'subject': 'DBMS',
      'room': 'Lab 2',
      'time': '10:15 AM - 11:15 AM',
    },
    {
      'name': 'Prof. Rahul Deshmukh',
      'department': 'Information Technology',
      'subject': 'Computer Networks',
      'room': 'Room 305',
      'time': '11:30 AM - 12:30 PM',
    },
    {
      'name': 'Prof. Neha Joshi',
      'department': 'Computer Applications',
      'subject': 'Operating System',
      'room': 'Room 202',
      'time': '01:30 PM - 02:30 PM',
    },
  ];

  bool get _isAdmin {
    return widget.userRole == UserRole.hod || widget.userRole == UserRole.principal;
  }

  bool get _isTeacher {
    return widget.userRole == UserRole.teacher || widget.userRole == UserRole.hod;
  }

  // ---------- Search (works for the timeline AND the admin view) ----------
  String get _query => _searchQuery.toLowerCase().trim();

  bool _matches(Map<String, dynamic> item, List<String> keys) {
    final q = _query;
    if (q.isEmpty) return true;
    return keys.any((k) => (item[k] ?? '').toString().toLowerCase().contains(q));
  }

  List<Map<String, dynamic>> get _filteredSchedule =>
      _dailySchedule.where((i) => _matches(i, ['subject', 'code', 'teacher', 'room'])).toList();

  List<Map<String, dynamic>> get _filteredDepartments =>
      _deptOverview.where((d) => _matches(d, ['department'])).toList();

  List<Map<String, dynamic>> get _filteredFaculty =>
      _facultyList.where((f) => _matches(f, ['name', 'department', 'subject', 'room'])).toList();

  // ---------- Real dates for the week strip (no more hard-coded 21, 22...) ----------
  int get _selectedIndex => _days.indexOf(_selectedDay);

  DateTime _dateOfDay(int index) {
    final now = DateTime.now();
    // Monday of this week + index (DateTime handles month overflow)
    return DateTime(now.year, now.month, now.day - (now.weekday - 1) + index);
  }

  int get _todayIndex {
    final w = DateTime.now().weekday; // 1 = Mon ... 7 = Sun
    return (w >= 1 && w <= 6) ? w - 1 : -1; // Sunday has no column
  }

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  // ---------- Live class detection ("09:00 AM" -> minutes since midnight) ----------
  int? _toMinutes(String text) {
    try {
      final parts = text.trim().split(' ');
      final hm = parts[0].split(':');
      int hour = int.parse(hm[0]) % 12;
      final int minute = int.parse(hm[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM') hour += 12;
      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }

  bool _isLive(Map<String, dynamic> item) {
    if (_selectedIndex != _todayIndex) return false; // only "today" can be live
    final int? start = _toMinutes(item['start'].toString());
    final int? end = _toMinutes(item['end'].toString());
    if (start == null || end == null) return false;
    final now = DateTime.now();
    final int current = now.hour * 60 + now.minute;
    return current >= start && current < end;
  }

  int get _liveCount => _dailySchedule.where(_isLive).length;

  @override
  void initState() {
    super.initState();
    // open on today's column (Sunday falls back to Monday)
    _selectedDay = _todayIndex >= 0 ? _days[_todayIndex] : _days.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =====================================================================
  // 2. BUILD (screen skeleton)
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : _lightBg,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + week strip that overlaps its bottom edge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeader(),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: -40,
                    child: _buildDaySelector(),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    if (_isAdmin) _buildAdminView() else _buildTimelineView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // 3. HEADER + WEEK STRIP + SEARCH
  // =====================================================================
  Widget _buildHeader() {
    final bool canGoBack = Navigator.of(context).canPop();
    final DateTime date = _dateOfDay(_selectedIndex);
    final bool isToday = _selectedIndex == _todayIndex;
    final int live = _liveCount;

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
          Positioned.fill(child: CustomPaint(painter: _HeaderGridPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 62),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- Top row: back / title / today / menu ----------
                  Row(
                    children: [
                      if (canGoBack) ...[
                        _headerButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: 'Back',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Expanded(
                        child: Text(
                          'Timetable',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ),
                      _headerButton(
                        icon: Icons.today_rounded,
                        tooltip: 'Jump to today',
                        onTap: () {
                          setState(() {
                            _selectedDay = _todayIndex >= 0 ? _days[_todayIndex] : _days.first;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildMenu(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---------- Role + selected day ----------
                  Text(
                    _getRoleTitle(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedDay,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isToday ? '${_formatDate(date)} • Today' : _formatDate(date),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // ---------- Summary chips ----------
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _isAdmin
                        ? [
                            _summaryChip(Icons.account_tree_outlined, '${_deptOverview.length}', 'Departments'),
                            _summaryChip(Icons.groups_outlined, '${_facultyList.length}', 'Faculty'),
                          ]
                        : [
                            _summaryChip(Icons.class_outlined, '${_dailySchedule.length}', 'Classes'),
                            if (live > 0) _summaryChip(Icons.play_circle_outline, '$live', 'Live now'),
                          ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // Export / Print menu (same actions as before)
  Widget _buildMenu() {
    return PopupMenuButton<String>(
      tooltip: 'More',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: _handleMenuAction,
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'export',
          child: Row(children: [Icon(Icons.download_outlined), SizedBox(width: 10), Text('Export')]),
        ),
        PopupMenuItem<String>(
          value: 'print',
          child: Row(children: [Icon(Icons.print_outlined), SizedBox(width: 10), Text('Print')]),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Week strip: weekday + real date, today gets a dot
  Widget _buildDaySelector() {
    final theme = Theme.of(context);
    final int today = _todayIndex;

    return Container(
      height: 80,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: List.generate(_days.length, (i) {
          final bool selected = _selectedIndex == i;
          final DateTime date = _dateOfDay(i);

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedDay = _days[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [_primary, _primaryDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _days[i].substring(0, 3),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white70 : theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : _headingOf(theme),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == today ? (selected ? Colors.white : _primary) : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.8)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(fontSize: 14.5, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: _isAdmin ? 'Search department, faculty, room...' : 'Search subject, teacher, room...',
          hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: _iconOf(theme)),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close_rounded, color: theme.hintColor, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // =====================================================================
  // 4. TIMELINE VIEW (student / teacher)
  // =====================================================================
  Widget _buildTimelineView() {
    final schedules = _filteredSchedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('$_selectedDay Timeline')),
            Text(
              '${schedules.length} classes',
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (schedules.isEmpty)
          _emptyNote(Icons.event_busy_outlined, 'No classes found for your search.')
        else
          ...List.generate(schedules.length, (i) => _timelineRow(schedules[i], i == schedules.length - 1)),
      ],
    );
  }

  // One row = start/end time | dot + line | class card
  Widget _timelineRow(Map<String, dynamic> item, bool isLast) {
    final theme = Theme.of(context);
    final bool live = _isLive(item);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time column
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['start'].toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: live ? _iconOf(theme) : _headingOf(theme),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['end'].toString(),
                    style: TextStyle(fontSize: 10.5, color: theme.hintColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // Dot + line
          SizedBox(
            width: 26,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: live ? _primary : theme.cardColor,
                    border: Border.all(color: _primary, width: 3),
                    boxShadow: live
                        ? [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 8, spreadRadius: 2)]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _primary.withOpacity(0.18),
                    ),
                  ),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _scheduleCard(item, live),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'lab':
        return Icons.computer_outlined;
      case 'practical':
        return Icons.code_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  Widget _scheduleCard(Map<String, dynamic> item, bool live) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: live ? _primary : theme.dividerColor.withOpacity(0.6),
          width: live ? 1.6 : 1,
        ),
        boxShadow: live
            ? [BoxShadow(color: _primary.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showScheduleDetails(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(13)),
                      child: Icon(_iconForType(item['type'].toString()), color: _iconOf(theme), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['subject'].toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: live ? _iconOf(theme) : _headingOf(theme),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['code'].toString(),
                            style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (live) ...[
                      const SizedBox(width: 8),
                      _pill('LIVE', _primary, Colors.white),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _infoLine(Icons.person_outline, item['teacher'].toString()),
                const SizedBox(height: 6),
                _infoLine(Icons.room_outlined, item['room'].toString()),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill(item['type'].toString(), _tintOf(theme), _iconOf(theme)),
                    _pill('Division ${item['division']}', theme.hintColor.withOpacity(0.12), theme.hintColor),
                    _pill('Sem ${item['semester']}', theme.hintColor.withOpacity(0.12), theme.hintColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }

  // =====================================================================
  // 5. ADMIN VIEW (HOD & Principal)
  // =====================================================================
  Widget _buildAdminView() {
    final depts = _filteredDepartments;
    final faculty = _filteredFaculty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Department Overview'),
        const SizedBox(height: 14),
        if (depts.isEmpty)
          _emptyNote(Icons.search_off_rounded, 'No departments match your search.')
        else
          ...depts.map(_buildDepartmentCard),
        const SizedBox(height: 14),
        _sectionTitle('Faculty Schedule'),
        const SizedBox(height: 14),
        if (faculty.isEmpty)
          _emptyNote(Icons.search_off_rounded, 'No faculty match your search.')
        else
          _groupedCard(faculty.map(_facultyRow).toList()),
      ],
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.account_tree_outlined, color: _iconOf(theme), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  department['department'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _headingOf(theme)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _statItem('Classes', department['classes'].toString()),
                _statDivider(),
                _statItem('Lectures', department['lectures'].toString()),
                _statDivider(),
                _statItem('Faculty', department['faculty'].toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 30, color: Theme.of(context).dividerColor);
  }

  Widget _statItem(String title, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _headingOf(theme))),
          const SizedBox(height: 3),
          Text(title, style: TextStyle(fontSize: 11.5, color: theme.hintColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _facultyRow(Map<String, dynamic> faculty) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faculty['name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _headingOf(theme)),
                ),
                const SizedBox(height: 2),
                Text(
                  faculty['subject'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '${faculty['room']} • ${faculty['time']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // 6. DETAILS SHEET
  // =====================================================================
  void _showScheduleDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(16)),
                      child: Icon(_iconForType(item['type'].toString()), color: _iconOf(theme), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['subject'].toString(),
                            style: TextStyle(fontSize: 20, height: 1.2, fontWeight: FontWeight.w800, color: _headingOf(theme)),
                          ),
                          const SizedBox(height: 3),
                          Text(item['code'].toString(), style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow(theme, Icons.access_time_outlined, 'Time', '${item['start']} - ${item['end']}'),
                _detailRow(theme, Icons.person_outline, 'Teacher', item['teacher'].toString()),
                _detailRow(theme, Icons.room_outlined, 'Room', item['room'].toString()),
                _detailRow(theme, Icons.category_outlined, 'Type', item['type'].toString()),
                _detailRow(theme, Icons.groups_outlined, 'Division', item['division'].toString()),
                _detailRow(theme, Icons.timeline_outlined, 'Semester', item['semester'].toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: _iconOf(theme)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Text(label, style: TextStyle(color: theme.hintColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // 7. SHARED SMALL WIDGETS + ACTIONS
  // =====================================================================
  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _headingOf(theme)),
    );
  }

  // One rounded container holding several rows separated by dividers
  Widget _groupedCard(List<Widget> rows) {
    final theme = Theme.of(context);
    final List<Widget> items = [];
    for (int i = 0; i < rows.length; i++) {
      if (i > 0) {
        items.add(Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withOpacity(0.7)));
      }
      items.add(rows[i]);
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Column(children: items),
    );
  }

  // Small message box for empty states
  Widget _emptyNote(IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.hintColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, height: 1.35, color: theme.hintColor)),
          ),
        ],
      ),
    );
  }

  String _getRoleTitle() {
    if (widget.userRole == UserRole.principal) {
      return 'Principal • Academic Administration';
    }

    if (widget.userRole == UserRole.hod) {
      return 'HOD • Department Administration';
    }

    if (_isTeacher) {
      return 'Faculty • Teaching Schedule';
    }

    return 'Student • Academic Schedule';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showMessage('Timetable export will be connected to the report module.');
        break;

      case 'print':
        _showMessage('Print functionality will be connected later.');
        break;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// =====================================================================
// Header background: blueprint grid + rings (same look as other screens)
// =====================================================================
class _HeaderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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

    final ring = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width - 30, size.height - 40);
    for (final r in [36.0, 64.0, 92.0]) {
      canvas.drawCircle(center, r, ring);
    }

    final dot = Paint()..color = Colors.white.withOpacity(0.45);
    canvas.drawCircle(Offset(center.dx - 36, center.dy), 3, dot);
    canvas.drawCircle(Offset(center.dx, center.dy - 64), 3, dot);
    canvas.drawCircle(Offset(center.dx - 92, center.dy), 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}