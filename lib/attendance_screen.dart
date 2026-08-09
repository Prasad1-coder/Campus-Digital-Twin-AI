import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'permission_model.dart';

class AttendanceScreen extends StatefulWidget {
  final UserRole userRole;
  final String currentUserName;

  const AttendanceScreen({
    super.key,
    required this.userRole,
    required this.currentUserName,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AuthService _authService = AuthService();
  
  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  PermissionModel? get _permissions => _authService.getCurrentPermissions();

  bool _hasAccess(String module, String action) {
    return _authService.hasPermission(module, action);
  }

  bool get isStudent => widget.userRole == UserRole.student;
  bool get isTeacher => widget.userRole == UserRole.teacher;
  bool get isAdmin => !isStudent && !isTeacher;

  // Dummy Data
  final List<Map<String, dynamic>> _subjects = [
    {"name": "Data Structures", "code": "CS201", "att": 85, "total": 40, "present": 34, "faculty": "Dr. Sharma", "color": Colors.blue},
    {"name": "Operating Systems", "code": "CS202", "att": 72, "total": 40, "present": 29, "faculty": "Dr. Rao", "color": Colors.purple},
    {"name": "DBMS", "code": "CS203", "att": 91, "total": 38, "present": 35, "faculty": "Prof. Singh", "color": Colors.green},
    {"name": "Computer Networks", "code": "CS204", "att": 68, "total": 42, "present": 29, "faculty": "Dr. Mehta", "color": Colors.orange},
  ];

  final List<Map<String, dynamic>> _teacherClasses = [
    {"subject": "Data Structures", "year": "SE Computer", "time": "09:00 AM", "room": "204", "total": 60, "present": 55, "absent": 5},
    {"subject": "Advanced Java", "year": "TE Computer", "time": "11:00 AM", "room": "301", "total": 55, "present": 50, "absent": 5},
    {"subject": "DBMS Lab", "year": "SE Computer", "time": "02:00 PM", "room": "Lab 1", "total": 30, "present": 28, "absent": 2},
  ];

  final List<Map<String, dynamic>> _deptStats = [
    {"dept": "Computer Eng", "att": 89, "color": Colors.blue},
    {"dept": "Mechanical", "att": 76, "color": Colors.orange},
    {"dept": "Civil", "att": 82, "color": Colors.green},
    {"dept": "Electrical", "att": 71, "color": Colors.red},
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
          isStudent ? "My Attendance" : "Attendance Management",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded, color: Colors.white), onPressed: () {}),
          if (_hasAccess('attendance', 'canExport'))
            IconButton(icon: const Icon(Icons.download_outlined, color: Colors.white), onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exporting report... (UI Placeholder)")));
            }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isStudent
            ? _buildStudentView()
            : isTeacher
                ? _buildTeacherView()
                : _buildAdminView(),
      ),
    );
  }

  // ============================================================
  //  STUDENT VIEW
  // ============================================================
  Widget _buildStudentView() {
    int totalAtt = 82;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: totalAtt / 100),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12,
                            backgroundColor: _softBlue,
                            color: totalAtt < 75 ? Colors.red : Colors.green,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("${(value * 100).toInt()}%", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _textDark)),
                              const Text("Overall", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (totalAtt < 75)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text("Low Attendance! Defaulter Risk.", style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  )
                else
                  Text("Good Standing! Keep it up.", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle("Subject-wise Attendance"),
        const SizedBox(height: 12),
        ..._subjects.map((s) => _studentSubjectCard(s)).toList(),
        const SizedBox(height: 24),
        _sectionTitle("Today's Status"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primaryDark, _primary]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
          ),
          child: Column(
            children: [
              _statusRow("Data Structures", "09:00 AM", true),
              const Divider(color: Colors.white24, height: 20),
              _statusRow("Operating Systems", "11:00 AM", true),
              const Divider(color: Colors.white24, height: 20),
              _statusRow("DBMS", "02:00 PM", false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _studentSubjectCard(Map<String, dynamic> s) {
    final percent = s["att"] as int;
    final color = percent < 75 ? Colors.red : (percent < 85 ? Colors.orange : Colors.green);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (s["color"] as Color).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.book_outlined, color: s["color"] as Color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
                    Text("${s["code"]} • ${s["faculty"]}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Text("$percent%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 7,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String sub, String time, bool present) {
    return Row(
      children: [
        Icon(present ? Icons.check_circle : Icons.cancel, color: present ? Colors.greenAccent : Colors.redAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(sub, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // ============================================================
  //  TEACHER VIEW
  // ============================================================
  Widget _buildTeacherView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Quick Statistics"),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _statCard("Classes Today", "3", Icons.class_outlined),
            _statCard("Students Marked", "133", Icons.people_alt_outlined),
            _statCard("Pending", "1", Icons.pending_actions),
            _statCard("Avg Attendance", "87%", Icons.percent),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle("Today's Classes"),
        const SizedBox(height: 12),
        ..._teacherClasses.map((c) => _teacherClassCard(c)).toList(),
        const SizedBox(height: 24),
        _sectionTitle("Future Ready Attendance"),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _futureTool(Icons.qr_code_scanner_rounded, "QR", Colors.blue),
            _futureTool(Icons.face_retouching_natural_rounded, "Face", Colors.purple),
            _futureTool(Icons.location_on_rounded, "GPS", Colors.orange),
            _futureTool(Icons.wifi_off_rounded, "Offline", Colors.green),
          ],
        )
      ],
    );
  }

  Widget _teacherClassCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBlue),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(8)),
                child: Text(c["time"], style: const TextStyle(color: _primaryDark, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(c["subject"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark))),
            ],
          ),
          const SizedBox(height: 8),
          Text("${c["year"]} • Room ${c["room"]}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _attendancePill("P", c["present"], Colors.green),
                  const SizedBox(width: 6),
                  _attendancePill("A", c["absent"], Colors.red),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showMarkAttendanceSheet(c),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text("Mark", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _attendancePill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text("$label: $count", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Widget _futureTool(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
      ],
    );
  }

  void _showMarkAttendanceSheet(Map<String, dynamic> classData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryDark, _primary]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Mark Attendance\n${classData["subject"]} - ${classData["year"]}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(child: Text("Student ${index + 1}", style: const TextStyle(fontWeight: FontWeight.w600))),
                          Row(
                            children: [
                              _markButton("P", Colors.green),
                              _markButton("A", Colors.red),
                              _markButton("L", Colors.orange),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _markButton(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  HOD & PRINCIPAL VIEW (ADMIN)
  // ============================================================
  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Analytics Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primaryDark, _primary]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("College Overview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text("Live", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _adminMetric("84%", "Overall Att"),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _adminMetric("142", "Defaulters"),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _adminMetric("45", "Classes Today"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle("Department Analytics"),
        const SizedBox(height: 12),
        // Custom Bar Chart UI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
          ),
          child: Column(
            children: [
              ..._deptStats.map((d) => _deptBarChart(d)).toList(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle("Quick Actions"),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _statCard("Teachers", "45", Icons.school_outlined),
            _statCard("Students", "1.2k", Icons.groups_outlined),
            _statCard("Reports", "12", Icons.summarize_outlined),
            _statCard("Export", "PDF", Icons.picture_as_pdf_outlined),
          ],
        ),
      ],
    );
  }

  Widget _deptBarChart(Map<String, dynamic> d) {
    final percent = d["att"] as int;
    final color = d["color"] as Color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(d["dept"], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDark))),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                ),
                FractionallySizedBox(
                  widthFactor: percent / 100,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
                      borderRadius: BorderRadius.circular(6)
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 40, child: Text("$percent%", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color))),
        ],
      ),
    );
  }

  Widget _adminMetric(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // ============================================================
  //  REUSABLE WIDGETS
  // ============================================================
  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark));
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _primary, size: 22),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textDark)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}