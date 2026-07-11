import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'profile_screen.dart';

class DigitalIdScreen extends StatelessWidget {
  final UserRole userRole;

  const DigitalIdScreen({super.key, this.userRole = UserRole.student});

  Map<String, String> get _studentData => {
        "name": "Prasad",
        "id": "STU-2026-0187",
        "roll": "CE-2026-101",
        "dept": "Computer Engineering",
        "year": "2nd Year / Semester 4",
        "blood": "B+",
        "emergency": "+91 9876543210",
        "email": "prasad@college.edu",
        "validTill": "June 2028",
      };

  Map<String, String> get _teacherData => {
        "name": "Dr. Rajesh Sharma",
        "id": "FAC-2019-045",
        "dept": "Chemistry Department",
        "designation": "Assistant Professor",
        "email": "rajesh.sharma@college.edu",
        "mobile": "+91 9876543210",
        "joining": "12 June 2019",
      };

  @override
  Widget build(BuildContext context) {
    final isStudent = userRole == UserRole.student;
    final data = isStudent ? _studentData : _teacherData;

    final qrPayload = jsonEncode({
      "id": data["id"],
      "name": data["name"],
      "role": isStudent ? "student" : "teacher",
      "dept": data["dept"],
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Digital ID Card", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // 👇 ID Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text("XYZ Engineering College",
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            isStudent ? "STUDENT" : "FACULTY",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -35),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFFE3F2FD),
                            child: Icon(isStudent ? Icons.person : Icons.person_2_outlined, size: 46, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(data["name"]!, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 3),
                        Text(isStudent ? data["dept"]! : data["designation"]!, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text("Active", style: TextStyle(fontSize: 11.5, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          Container(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 16),
                          if (isStudent) ...[
                            _idRow("ID Number", data["id"]!, Icons.badge_outlined),
                            _idRow("Roll Number", data["roll"]!, Icons.numbers_outlined),
                            _idRow("Year / Sem", data["year"]!, Icons.timeline_outlined),
                            _idRow("Blood Group", data["blood"]!, Icons.bloodtype_outlined),
                            _idRow("Emergency Contact", data["emergency"]!, Icons.phone_in_talk_outlined),
                            _idRow("Email", data["email"]!, Icons.email_outlined),
                            _idRow("Valid Till", data["validTill"]!, Icons.event_available_outlined),
                          ] else ...[
                            _idRow("Employee ID", data["id"]!, Icons.badge_outlined),
                            _idRow("Department", data["dept"]!, Icons.apartment_outlined),
                            _idRow("Email", data["email"]!, Icons.email_outlined),
                            _idRow("Mobile", data["mobile"]!, Icons.phone_outlined),
                            _idRow("Joining Date", data["joining"]!, Icons.event_outlined),
                          ],
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 18),

                          // 👇 SIRF STUDENT ke paas QR dikhega - Teacher ke paas nahi
                          if (isStudent) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: QrImageView(data: qrPayload, size: 130, version: QrVersions.auto),
                            ),
                            const SizedBox(height: 8),
                            Text("Scan for verification / attendance", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ] else ...[
                            // 👇 TEACHER ke paas sirf Scan button hai, QR nahi
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, size: 40, color: Colors.blue.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Student ka ID scan karke attendance mark karo",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const _ScanStudentIdScreen()),
                                        );
                                      },
                                      icon: const Icon(Icons.qr_code_scanner),
                                      label: const Text("Scan Student ID"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 👇 Sirf Copy ID rakha - Download/Share hata diya "sirf ID hi rakho" ke hisaab se
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data["id"]!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${data["id"]} copied!"),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(14),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text("Copy ID"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: Colors.blue),
                foregroundColor: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _idRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEACHER SIDE — Scan Student ID Screen
// Student ka QR scan karte hi uski ID details sync hoke dikhti hain
// ============================================================
class _ScanStudentIdScreen extends StatefulWidget {
  const _ScanStudentIdScreen();

  @override
  State<_ScanStudentIdScreen> createState() => _ScanStudentIdScreenState();
}

class _ScanStudentIdScreenState extends State<_ScanStudentIdScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (isProcessing) return;
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() => isProcessing = true);

    try {
      final data = jsonDecode(rawValue);
      _showStudentDetails(data);
    } catch (e) {
      _showError();
    }
  }

  // 👇 Ye scan hote hi student ki ID details "sync" karke dikhata hai
  void _showStudentDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 40),
                ),
                const SizedBox(height: 14),
                const Text("ID Verified ✅", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                _detailRow("Name", data["name"] ?? "-"),
                _detailRow("ID", data["id"] ?? "-"),
                _detailRow("Department", data["dept"] ?? "-"),
                _detailRow("Role", (data["role"] ?? "-").toString().toUpperCase()),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => isProcessing = false);
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text("Scan Next"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("✅ ${data["name"]} - Attendance marked")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Mark Attendance"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => isProcessing = false);
    });
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
        ],
      ),
    );
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Invalid ID QR code")));
    setState(() => isProcessing = false);
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
        title: const Text("Scan Student ID"),
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
              child: const Text("scan student id for attendence and other verifivations", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}