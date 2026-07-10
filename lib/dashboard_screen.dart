import 'package:flutter/material.dart';
import 'ai_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'timetable_screen.dart';
import 'attendance_screen.dart';
import 'library_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserRole userRole; // 👈 naya - login se aayega

  const DashboardScreen({super.key, required this.userRole});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> items = const [
    {"title": "AI Assistant", "icon": Icons.smart_toy_outlined},
    {"title": "Campus Map", "icon": Icons.map_outlined},
    {"title": "Timetable", "icon": Icons.calendar_month_outlined},
    {"title": "Attendance", "icon": Icons.fact_check_outlined},
    {"title": "Library", "icon": Icons.menu_book_outlined},
    {"title": "Canteen", "icon": Icons.restaurant_outlined},
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // 👇 Role ke hisaab se naam/subtitle dikhane ke liye
  String get _displayName => widget.userRole == UserRole.student ? "Prasad" : "Dr. Rajesh Sharma";
  String get _displaySubtitle =>
      widget.userRole == UserRole.student ? "Computer Engineering" : "Chemistry Department";

  void _openAI() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AIScreen()));
  }

  void _openMap() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
  }

  void _openTimetable() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(role: widget.userRole)), // 👈 role pass kiya
    );
  }

  void _openAttendance() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen()));
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        _openAI();
        break;
      case 1:
        _openMap();
        break;
      case 2:
        _openAttendance();
        break;
      case 3:
        _openProfile();
        break;
    }
  }

  void _onGridItemTap(int index) {
    switch (index) {
      case 0:
        _openAI();
        break;
      case 1:
        _openMap();
        break;
      case 2:
        _openTimetable();
        break;
      case 3:
        _openAttendance();
        break;
      case 4:
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const LibraryScreen(),
    ),
  );
  break;
      case 5:
        _showComingSoon("Canteen");
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature module coming soon"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Campus Digital Twin AI",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                accountName: Text(
                  _displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail: Text(
                  widget.userRole == UserRole.student ? "prasad@college.edu" : "rajesh.sharma@college.edu",
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _drawerTile(Icons.home_outlined, "Home", () => Navigator.pop(context)),
            _drawerTile(Icons.smart_toy_outlined, "AI Assistant", () {
              Navigator.pop(context);
              _openAI();
            }),
            _drawerTile(Icons.map_outlined, "Campus Map", () {
              Navigator.pop(context);
              _openMap();
            }),
            _drawerTile(Icons.calendar_month_outlined, "Timetable", () {
              Navigator.pop(context);
              _openTimetable();
            }),
            _drawerTile(Icons.fact_check_outlined, "Attendance", () {
              Navigator.pop(context);
              _openAttendance();
            }),
            const Divider(height: 24),
            _drawerTile(Icons.settings_outlined, "Settings", () => Navigator.pop(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text("AI Chat", style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _openAI,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          onTap: _onNavTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: "AI"),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Map"),
            BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: "Attendance"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$_greeting, ${_displayName.split(' ').first} 👋",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                "Your AI Campus Assistant",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.person, size: 30, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _displaySubtitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _openProfile,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Text(
                "Quick Access",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  return _DashboardCard(
                    title: items[index]["title"] as String,
                    icon: items[index]["icon"] as IconData,
                    onTap: () => _onGridItemTap(index),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}