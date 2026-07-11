import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'profile_screen.dart'; // UserRole enum yahan se aata hai

// 👇 Simple in-memory attendance record store
class _AttendanceRecord {
  final String studentName;
  final String subject;
  final DateTime time;
  _AttendanceRecord({required this.studentName, required this.subject, required this.time});
}

class _AttendanceStore {
  static final List<_AttendanceRecord> records = [];

  static bool alreadyMarkedToday(String studentName, String subject) {
    final today = DateTime.now();
    return records.any((r) =>
        r.studentName == studentName &&
        r.subject == subject &&
        r.time.year == today.year &&
        r.time.month == today.month &&
        r.time.day == today.day);
  }

  static void mark(String studentName, String subject) {
    records.add(_AttendanceRecord(studentName: studentName, subject: subject, time: DateTime.now()));
  }
}

class AttendanceScreen extends StatefulWidget {
  final UserRole userRole;
  final String currentUserName;

  const AttendanceScreen({
    super.key,
    this.userRole = UserRole.student,
    this.currentUserName = "Prasad",
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final List<Map<String, dynamic>> subjects = const [
    {"name": "Data Structures", "icon": Icons.book_outlined, "attendance": 92, "color": Colors.blue},
    {"name": "Python Programming", "icon": Icons.code_outlined, "attendance": 88, "color": Colors.purple},
    {"name": "DBMS", "icon": Icons.storage_outlined, "attendance": 95, "color": Colors.green},
    {"name": "Computer Networks", "icon": Icons.memory_outlined, "attendance": 90, "color": Colors.orange},
    {"name": "Operating Systems", "icon": Icons.dns_outlined, "attendance": 78, "color": Colors.red},
  ];

  double get _overallAttendance {
    final total = subjects.fold<int>(0, (sum, s) => sum + (s["attendance"] as int));
    return total / subjects.length;
  }

  Color _statusColor(int percent) {
    if (percent >= 85) return Colors.green;
    if (percent >= 75) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.userRole == UserRole.teacher;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Attendance", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: Icon(isTeacher ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded),
        label: Text(isTeacher ? "Generate QR" : "Scan QR", style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () {
          if (isTeacher) {
            _openSubjectPicker(context);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => _ScanScreen(studentName: widget.currentUserName)));
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        children: [
          // 👇 Overall attendance ring card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
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
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _overallAttendance / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                      Text(
                        "${_overallAttendance.toStringAsFixed(0)}%",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Overall Attendance",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _overallAttendance >= 75
                            ? "Great job! You're on track 🎉"
                            : "⚠️ Below required 75% minimum",
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          Text(
            "Subject-wise Breakdown",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 14),

          ...subjects.map((subject) {
            final percent = subject["attendance"] as int;
            final color = _statusColor(percent);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (subject["color"] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(subject["icon"] as IconData, color: subject["color"] as Color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subject["name"] as String,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ),
                      Text(
                        "$percent%",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                      ),
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
          }),
        ],
      ),
    );
  }

  void _openSubjectPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("Select Subject", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                ...subjects.map((s) {
                  return ListTile(
                    leading: Icon(s["icon"] as IconData, color: Colors.blue),
                    title: Text(s["name"] as String),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => _GenerateScreen(subject: s["name"] as String)),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// TEACHER SIDE — QR GENERATOR SCREEN
// ============================================================
class _GenerateScreen extends StatefulWidget {
  final String subject;
  const _GenerateScreen({required this.subject});

  @override
  State<_GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<_GenerateScreen> {
  late String sessionId;
  Timer? timer;
  int secondsLeft = 20;

  @override
  void initState() {
    super.initState();
    _refresh();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        secondsLeft--;
        if (secondsLeft <= 0) _refresh();
      });
    });
  }

  void _refresh() {
    setState(() {
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      secondsLeft = 20;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({"subject": widget.subject, "session": sessionId});
    final todayRecords = _AttendanceStore.records.where((r) => r.subject == widget.subject
        && r.time.day == DateTime.now().day
        && r.time.month == DateTime.now().month).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("${widget.subject} - QR"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: QrImageView(data: qrData, version: QrVersions.auto, size: 240),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text("🔄 Naya code $secondsLeft sec mein", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text("Marked Today (${todayRecords.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          if (todayRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("Abhi koi scan nahi hua", style: TextStyle(color: Colors.grey.shade500))),
            )
          else
            ...todayRecords.reversed.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 10),
                      Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text("${r.time.hour}:${r.time.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ============================================================
// STUDENT SIDE — QR SCANNER SCREEN
// ============================================================
class _ScanScreen extends StatefulWidget {
  final String studentName;
  const _ScanScreen({required this.studentName});

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (isProcessing) return;
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() => isProcessing = true);

    try {
      final data = jsonDecode(rawValue);
      final String subject = data["subject"];

      if (_AttendanceStore.alreadyMarkedToday(widget.studentName, subject)) {
        _showResult(false, "⚠️ $subject ki attendance already mark hai aaj");
      } else {
        _AttendanceStore.mark(widget.studentName, subject);
        _showResult(true, "✅ $subject - Attendance marked!");
      }
    } catch (e) {
      _showResult(false, "❌ Invalid QR code");
    }
  }

  void _showResult(bool success, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle : Icons.error_outline, color: success ? Colors.green : Colors.orange, size: 56),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isProcessing = false);
            },
            child: const Text("Scan Again"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Attendance QR"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () => cameraController.toggleTorch()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16)),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
              child: const Text("Teacher ke QR ko frame ke andar rakho", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}