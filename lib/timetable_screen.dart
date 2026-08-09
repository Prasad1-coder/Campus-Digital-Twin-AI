import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'permission_model.dart';

class TimetableScreen extends StatefulWidget {
  final UserRole userRole;
  
  const TimetableScreen({super.key, this.userRole = UserRole.student});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final AuthService _authService = AuthService();
  
  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  int _selectedDay = 0; // 0=Mon, 1=Tue...
  final TextEditingController _searchController = TextEditingController();

  UserModel? get _currentUser => _authService.getCurrentUser();
  PermissionModel? get _permissions => _authService.getCurrentPermissions();

  bool get isStudent => widget.userRole == UserRole.student;
  bool get isTeacher => widget.userRole == UserRole.teacher;
  bool get isAdmin => !isStudent && !isTeacher; // HOD & Principal

  bool _hasAccess(String module, String action) {
    return _authService.hasPermission(module, action);
  }

  final List<String> _days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  // Dummy Data for Student & Teacher Daily Schedule
  final List<Map<String, dynamic>> _dailySchedule = [
    {"time": "09:00 - 10:00", "subject": "Data Structures", "code": "CS201", "room": "204", "faculty": "Dr. Sharma", "year": "SE Computer", "isCurrent": true, "isFree": false, "isLab": false},
    {"time": "10:00 - 11:00", "subject": "Operating Systems", "code": "CS202", "room": "204", "faculty": "Dr. Rao", "year": "SE Computer", "isCurrent": false, "isFree": false, "isLab": false},
    {"time": "11:15 - 12:15", "subject": "DBMS", "code": "CS203", "room": "301", "faculty": "Prof. Singh", "year": "TE Computer", "isCurrent": false, "isFree": false, "isLab": false},
    {"time": "12:15 - 01:00", "subject": "Lunch Break", "code": "", "room": "Canteen", "faculty": "", "year": "", "isCurrent": false, "isFree": true, "isLab": false},
    {"time": "01:00 - 02:00", "subject": "Computer Networks", "code": "CS204", "room": "301", "faculty": "Dr. Mehta", "year": "TE Computer", "isCurrent": false, "isFree": false, "isLab": false},
    {"time": "02:00 - 04:00", "subject": "DBMS Lab", "code": "CS203L", "room": "Lab 1", "faculty": "Prof. Singh", "year": "SE Computer", "isCurrent": false, "isFree": false, "isLab": true},
  ];

  // Dummy Data for HOD/Principal Overview
  final List<Map<String, dynamic>> _deptOverview = [
    {"dept": "Computer Engineering", "ongoing": 4, "free": 2, "color": Colors.blue},
    {"dept": "Mechanical Engineering", "ongoing": 3, "free": 3, "color": Colors.orange},
    {"dept": "Civil Engineering", "ongoing": 2, "free": 4, "color": Colors.green},
    {"dept": "Electrical Engineering", "ongoing": 5, "free": 1, "color": Colors.purple},
  ];

  final List<Map<String, dynamic>> _facultyList = [
    {"name": "Dr. Sharma", "subject": "Data Structures (CS201)", "room": "204", "status": "Teaching", "load": "12 hrs/week"},
    {"name": "Dr. Rao", "subject": "Free Period", "room": "-", "status": "Free", "load": "10 hrs/week"},
    {"name": "Prof. Singh", "subject": "DBMS Lab (CS203L)", "room": "Lab 1", "status": "Teaching", "load": "14 hrs/week"},
    {"name": "Dr. Mehta", "subject": "Free Period", "room": "-", "status": "Free", "load": "11 hrs/week"},
  ];

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          isStudent ? "My Timetable" : isTeacher ? "Teaching Schedule" : "College Timetable",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today_outlined, color: Colors.white), onPressed: () {}),
          if (isAdmin && _hasAccess('timetable', 'canManage'))
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'generate', child: Text('Auto-Generate (AI)')),
                const PopupMenuItem(value: 'clash', child: Text('Detect Clashes')),
              ],
              onSelected: (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(val == 'generate' ? "AI Timetable Optimization ready for backend." : "No clashes detected.")),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  if (isStudent || isTeacher) _buildStudentTeacherView(),
                  if (isAdmin) _buildAdminView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  WIDGETS
  // ============================================================

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          bool isSelected = _selectedDay == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [_primaryDark, _primary]) : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Text(
                  _days[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : _primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: isStudent ? "Search subject..." : isTeacher ? "Search class..." : "Search department/faculty...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ---------------- STUDENT & TEACHER VIEW ----------------
  Widget _buildStudentTeacherView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats
        Row(
          children: [
            _quickStatCard("Classes", "5", Icons.class_outlined),
            const SizedBox(width: 12),
            _quickStatCard("Ongoing", "1", Icons.play_circle_outline),
            const SizedBox(width: 12),
            _quickStatCard("Free", "1", Icons.coffee_rounded),
          ],
        ),
        const SizedBox(height: 20),
        const Text("Today's Timeline", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        
        // Timeline List
        ..._dailySchedule.map((lecture) => _timelineCard(lecture)).toList(),
      ],
    );
  }

  Widget _timelineCard(Map<String, dynamic> l) {
    bool isCurrent = l["isCurrent"];
    bool isFree = l["isFree"];
    bool isLab = l["isLab"];

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 40, bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFree ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isCurrent ? _primary : Colors.transparent, width: 2),
              boxShadow: [BoxShadow(color: _primary.withOpacity(isCurrent ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l["subject"],
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w800, 
                          color: isFree ? Colors.grey : (isCurrent ? _primaryDark : _textDark),
                          decoration: isFree ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
                        child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                      )
                    else if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                        child: Text("FREE", style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.w900)),
                      )
                    else if (isLab)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text("LAB", style: TextStyle(color: Colors.purple.shade700, fontSize: 9, fontWeight: FontWeight.w900)),
                      )
                  ],
                ),
                if (!isFree) ...[
                  const SizedBox(height: 6),
                  Text(
                    isStudent ? "${l["code"]} • ${l["faculty"]}" : "${l["code"]} • ${l["year"]}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(l["time"], style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (!isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(6)),
                        child: Text("Room ${l["room"]}", style: const TextStyle(fontSize: 10, color: _primaryDark, fontWeight: FontWeight.w700)),
                      ),
                    if (isTeacher && !isFree && _hasAccess('timetable', 'canEdit'))
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Edit functionality ready for backend.")),
                          );
                        },
                      )
                  ],
                ),
              ],
            ),
          ),
        ),
        // Timeline Dot & Line
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isCurrent ? _primary : (isFree ? Colors.grey.shade300 : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(color: isFree ? Colors.grey.shade400 : _primary, width: 3),
                ),
              ),
              Expanded(child: Container(width: 2, color: _softBlue)),
            ],
          ),
        )
      ],
    );
  }

  Widget _quickStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: _primary, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textDark)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ---------------- HOD & PRINCIPAL VIEW ----------------
  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Department Overview", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: _deptOverview.map((d) => _deptCard(d)).toList(),
        ),
        const SizedBox(height: 24),
        const Text("Faculty Schedule (Live)", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        ..._facultyList.map((f) => _facultyCard(f)).toList(),
      ],
    );
  }

  Widget _deptCard(Map<String, dynamic> d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (d["color"] as Color).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.business_outlined, color: d["color"] as Color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text("${d["ongoing"]} Live", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d["dept"], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text("${d["free"]} Classes Free", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  Widget _facultyCard(Map<String, dynamic> f) {
    bool isTeaching = f["status"] == "Teaching";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isTeaching ? _softBlue : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isTeaching ? _primary : Colors.grey.shade300,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f["name"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
                Text(f["subject"], style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(f["status"], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isTeaching ? Colors.green : Colors.grey)),
              const SizedBox(height: 4),
              Text(f["load"], style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }
}