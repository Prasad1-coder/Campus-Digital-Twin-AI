import 'package:flutter/material.dart';
import 'ai_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'timetable_screen.dart';
import 'attendance_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> items = const [
    {"title": "AI Assistant", "icon": Icons.smart_toy},
    {"title": "Campus Map", "icon": Icons.map},
    {"title": "Timetable", "icon": Icons.calendar_month},
    {"title": "Attendance", "icon": Icons.check_circle},
    {"title": "Library", "icon": Icons.menu_book},
    {"title": "Canteen", "icon": Icons.restaurant},
  ];

  void _openAI() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIScreen()),
    );
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  void _openTimetable() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimetableScreen()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AttendanceScreen()),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Library Screen Coming Soon")),
        );
        break;
      case 5:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Canteen Screen Coming Soon")),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Digital Twin AI"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Prasad"),
              accountEmail: Text("prasad@college.edu"),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text("AI Assistant"),
              onTap: () {
                Navigator.pop(context);
                _openAI();
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Campus Map"),
              onTap: () {
                Navigator.pop(context);
                _openMap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("Timetable"),
              onTap: () {
                Navigator.pop(context);
                _openTimetable();
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("Attendance"),
              onTap: () {
                Navigator.pop(context);
                _openAttendance();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy),
        label: const Text("AI Chat"),
        onPressed: _openAI,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: "AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Prasad 👋",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your AI Campus Assistant",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    child: Icon(Icons.person, size: 30),
                  ),
                  SizedBox(width: 13),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Prasad",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "computer engineering",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _onGridItemTap(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[index]["icon"] as IconData,
                            size: 50,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            items[index]["title"] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}