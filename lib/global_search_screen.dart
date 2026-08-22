import 'package:flutter/material.dart';
import 'attendance_screen.dart';
import 'library_screen.dart';
import 'notice_screen.dart';
import 'events_screen.dart';
import 'timetable_screen.dart';
import 'services/auth_service.dart';
import 'user_role.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  String _query = "";
  final FocusNode _focusNode = FocusNode();

  // Dummy Database for Global Search
  final List<Map<String, dynamic>> _allData = [
    {"title": "Tech Fest 2024", "category": "Event", "icon": Icons.celebration_outlined, "color": Colors.purple, "screen": const EventsScreen()},
    {"title": "Annual Sports Day", "category": "Event", "icon": Icons.sports_soccer_outlined, "color": Colors.orange, "screen": const EventsScreen()},
    {"title": "Library Book Due Reminder", "category": "Notice", "icon": Icons.campaign_outlined, "color": Colors.red, "screen": const NoticeScreen()},
    {"title": "TCS Placement Drive", "category": "Notice", "icon": Icons.campaign_outlined, "color": Colors.blue, "screen": const NoticeScreen()},
    {"title": "Clean Code", "category": "Library Book", "icon": Icons.menu_book_outlined, "color": Colors.green, "screen": const LibraryScreen()},
    {"title": "Artificial Intelligence", "category": "Library Book", "icon": Icons.menu_book_outlined, "color": Colors.indigo, "screen": const LibraryScreen()},
    {"title": "DBMS Lecture", "category": "Timetable", "icon": Icons.calendar_month_outlined, "color": Colors.teal, "screen": const TimetableScreen()},
    {"title": "Data Structures", "category": "Timetable", "icon": Icons.calendar_month_outlined, "color": Colors.brown, "screen": const TimetableScreen()},
  ];

  List<Map<String, dynamic>> get _filteredData {
    if (_query.isEmpty) return [];
    return _allData.where((item) => item["title"].toLowerCase().contains(_query.toLowerCase())).toList();
  }

  @override
  void initState() {
    super.initState();
    // Automatically open keyboard when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserRole role = _authService.getCurrentUser()?.role ?? UserRole.student;

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
        title: _buildSearchField(),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _query.isEmpty ? _buildSuggestions() : _buildSearchResults(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: (val) => setState(() => _query = val),
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          hintText: "Search events, notices, books...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = "");
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Links", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _quickLinkCard("Notices", Icons.campaign_outlined, Colors.red, const NoticeScreen()),
              _quickLinkCard("Events", Icons.celebration_outlined, Colors.purple, const EventsScreen()),
              _quickLinkCard("Library", Icons.menu_book_outlined, Colors.green, const LibraryScreen()),
              _quickLinkCard("Timetable", Icons.calendar_month_outlined, Colors.teal, const TimetableScreen()),
              _quickLinkCard("Attendance", Icons.fact_check_outlined, Colors.blue, AttendanceScreen(userRole: _authService.getCurrentUser()?.role ?? UserRole.student, currentUserName: _authService.getCurrentUser()?.fullName ?? "User")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickLinkCard(String title, IconData icon, Color color, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _filteredData;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No results found for '$_query'", style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = results[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item["screen"])),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: item["color"].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(item["icon"], color: item["color"], size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item["title"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(height: 4),
                      Text(item["category"], style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}