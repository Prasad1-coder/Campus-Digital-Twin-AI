import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class ExaminationScreen extends StatefulWidget {
  const ExaminationScreen({super.key});

  @override
  State<ExaminationScreen> createState() => _ExaminationScreenState();
}

class _ExaminationScreenState extends State<ExaminationScreen> {
  final AuthService _authService = AuthService();

  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _isStudent => _currentUser?.role == UserRole.student;

  // Dummy Data
  final List<Map<String, dynamic>> _examSchedule = [
    {"subject": "Data Structures (CS201)", "date": "10 Dec 2024", "time": "10:00 AM", "room": "Exam Hall A", "seat": "A-12"},
    {"subject": "DBMS (CS203)", "date": "14 Dec 2024", "time": "10:00 AM", "room": "Exam Hall B", "seat": "B-45"},
    {"subject": "Operating Systems (CS202)", "date": "18 Dec 2024", "time": "02:00 PM", "room": "Exam Hall A", "seat": "A-14"},
  ];

  final List<Map<String, dynamic>> _results = [
    {"subject": "Data Structures", "code": "CS201", "marks": 85, "credits": 4, "grade": "A"},
    {"subject": "DBMS", "code": "CS203", "marks": 92, "credits": 4, "grade": "A+"},
    {"subject": "Operating Systems", "code": "CS202", "marks": 78, "credits": 3, "grade": "B+"},
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
        title: const Text("Examinations", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined, color: Colors.white), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading Hall Ticket... (UI)")));
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isStudent ? _buildStudentView() : _buildAdminView(),
      ),
    );
  }

  // ============================================================
  //  STUDENT VIEW
  // ============================================================
  Widget _buildStudentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: [
            _statCard("SGPA", "8.4", Icons.star_rounded, Colors.orange),
            _statCard("Credits", "11", Icons.book_rounded, Colors.blue),
            _statCard("Backlogs", "0", Icons.check_circle_rounded, Colors.green),
          ],
        ),
        const SizedBox(height: 24),

        // Exam Schedule
        _sectionTitle("Upcoming Exams", Icons.calendar_month_rounded),
        const SizedBox(height: 16),
        ..._examSchedule.map((e) => _buildExamCard(e)).toList(),
        
        const SizedBox(height: 24),

        // Previous Results
        _sectionTitle("Semester 5 Results", Icons.assignment_turned_in_rounded),
        const SizedBox(height: 16),
        ..._results.map((r) => _buildResultCard(r)).toList(),
      ],
    );
  }

  Widget _buildExamCard(Map<String, dynamic> e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBlue, width: 1.2),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e["subject"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text("${e["date"]} • ${e["time"]}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chipWidget(Icons.place_outlined, "Room: ${e["room"]}"),
              const SizedBox(width: 12),
              _chipWidget(Icons.chair_alt_outlined, "Seat: ${e["seat"]}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> r) {
    Color gradeColor = r["marks"] >= 90 ? Colors.green : (r["marks"] >= 75 ? Colors.blue : Colors.orange);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r["subject"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                Text("Credits: ${r["credits"]}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${r["marks"]}/100", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: gradeColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: gradeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text("Grade: ${r["grade"]}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gradeColor)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ============================================================
  //  ADMIN VIEW (Teacher / HOD / Principal)
  // ============================================================
  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analytics Stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _statCard("Pass Percentage", "92%", Icons.percent_rounded, Colors.green),
            _statCard("Topper Marks", "96%", Icons.emoji_events_rounded, Colors.amber),
            _statCard("Students Appeared", "240", Icons.groups_rounded, Colors.blue),
            _statCard("Backlogs", "18", Icons.warning_amber_rounded, Colors.red),
          ],
        ),
        const SizedBox(height: 24),

        // Upload Marks UI
        _sectionTitle("Subject Performance", Icons.bar_chart_rounded),
        const SizedBox(height: 16),
        ..._results.map((r) => _buildSubjectPerformanceCard(r)).toList(),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Open Upload Marks Sheet (UI)")));
            },
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text("Upload Internal Marks"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSubjectPerformanceCard(Map<String, dynamic> r) {
    double passPercent = (r["marks"] / 100) * 100; // Dummy logic
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r["subject"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("Class Average: ${r["marks"]}%", style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text("Pass: ${passPercent.toInt()}%", style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: r["marks"] / 100,
              minHeight: 8,
              backgroundColor: _softBlue,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  REUSABLE WIDGETS
  // ============================================================
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
      ],
    );
  }

  Widget _chipWidget(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _primary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ],
    );
  }
}