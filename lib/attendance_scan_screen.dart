import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

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

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();

  bool get isStudent => widget.userRole == UserRole.student;
  bool get isTeacher => widget.userRole == UserRole.teacher;
  bool get isAdmin => !isStudent && !isTeacher;

  final List<Map<String, dynamic>> _subjects = [
    {"name": "Data Structures", "code": "CS201", "att": 85, "total": 40, "present": 34, "faculty": "Dr. Sharma", "color": Colors.blue},
    {"name": "Operating Systems", "code": "CS202", "att": 72, "total": 40, "present": 29, "faculty": "Dr. Rao", "color": Colors.purple},
  ];

  // 👇 FIX: Added 'isMarked' and 'presentCount' to track state
  final List<Map<String, dynamic>> _teacherClasses = [
    {"subject": "Data Structures", "year": "SE Computer", "time": "09:00 AM", "room": "204", "total": 60, "present": 0, "absent": 0, "isMarked": false},
    {"subject": "Advanced Java", "year": "TE Computer", "time": "11:00 AM", "room": "301", "total": 55, "present": 0, "absent": 0, "isMarked": false},
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isStudent ? _buildStudentView() : (isTeacher ? _buildTeacherView() : _buildAdminView()),
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
                Text(totalAtt < 75 ? "Low Attendance! Defaulter Risk." : "Good Standing! Keep it up.", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text("Subject-wise Attendance", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 12),
        ..._subjects.map((s) => _buildStudentSubjectCard(s)).toList(),
      ],
    );
  }

  Widget _buildStudentSubjectCard(Map<String, dynamic> s) {
    final percent = s["att"] as int;
    final color = percent < 75 ? Colors.red : (percent < 85 ? Colors.orange : Colors.green);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
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
            child: LinearProgressIndicator(value: percent / 100, minHeight: 7, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(color)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  TEACHER VIEW
  // ============================================================
  Widget _buildTeacherView() {
    int markedClasses = _teacherClasses.where((c) => c["isMarked"] == true).length;
    int pendingClasses = _teacherClasses.length - markedClasses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard("Classes Today", "${_teacherClasses.length}", Icons.class_outlined),
            _buildStatCard("Students Marked", "133", Icons.people_alt_outlined),
            _buildStatCard("Pending", "$pendingClasses", Icons.pending_actions),
            _buildStatCard("Avg Attendance", "87%", Icons.percent),
          ],
        ),
        const SizedBox(height: 24),
        const Text("Today's Classes", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 12),
        ..._teacherClasses.map((c) => _buildTeacherClassCard(c)).toList(),
      ],
    );
  }

  Widget _buildTeacherClassCard(Map<String, dynamic> c) {
    bool isMarked = c["isMarked"] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _softBlue)),
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
              if (isMarked)
                Row(
                  children: [
                    _attendancePill("P", c["present"], Colors.green),
                    const SizedBox(width: 6),
                    _attendancePill("A", c["absent"], Colors.red),
                  ],
                )
              else
                const Text("Not Marked Yet", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              // 👇 FIX: Button changes based on status
              ElevatedButton.icon(
                onPressed: () => _showMarkAttendanceSheet(c),
                icon: Icon(isMarked ? Icons.edit_outlined : Icons.check_circle_outline, size: 16),
                label: Text(isMarked ? "Edit" : "Mark", style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: isMarked ? Colors.grey : _primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              )
            ],
          )
        ],
      ),
    );
  }

  // 👇 FIX: Bottom Sheet with actual Marking Logic
  void _showMarkAttendanceSheet(Map<String, dynamic> classData) {
    // Generate dummy students for this class
    List<Map<String, dynamic>> students = List.generate(10, (index) => {
      "name": "Student ${index + 1}",
      "roll": "T${index + 1}",
      "status": "U" // U = Unmarked, P = Present, A = Absent
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_primaryDark, _primary]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        var student = students[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.person)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(student["name"], style: const TextStyle(fontWeight: FontWeight.w600))),
                              // P Button
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    student["status"] = "P";
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: student["status"] == "P" ? Colors.green : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text("P", style: TextStyle(color: student["status"] == "P" ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // A Button
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    student["status"] = "A";
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: student["status"] == "A" ? Colors.red : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text("A", style: TextStyle(color: student["status"] == "A" ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Calculate Present/Absent
                        int present = students.where((s) => s["status"] == "P").length;
                        int absent = students.where((s) => s["status"] == "A").length;

                        setState(() {
                          classData["present"] = present;
                          classData["absent"] = absent;
                          classData["isMarked"] = true; // Mark as completed
                        });
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Attendance Saved! P: $present, A: $absent"), backgroundColor: Colors.green),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                      child: const Text("Save Attendance"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _attendancePill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text("$label: $count", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  // ============================================================
  //  ADMIN VIEW (HOD/Principal)
  // ============================================================
  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primaryDark, _primary]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _adminMetric("84%", "Overall Att"),
              Container(width: 1, height: 40, color: Colors.white24),
              _adminMetric("142", "Defaulters"),
              Container(width: 1, height: 40, color: Colors.white24),
              _adminMetric("45", "Classes Today"),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text("Department Analytics", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Column(
            children: [
              _deptBarChart("Computer Eng", 89, Colors.blue),
              _deptBarChart("Mechanical", 76, Colors.orange),
              _deptBarChart("Civil", 82, Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deptBarChart(String dept, int percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(dept, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDark))),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                Container(height: 12, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
                FractionallySizedBox(
                  widthFactor: percent / 100,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.7), color]), borderRadius: BorderRadius.circular(6)),
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
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _primary, size: 22),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark)),
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}