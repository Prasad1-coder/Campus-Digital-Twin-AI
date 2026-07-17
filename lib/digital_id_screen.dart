import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'profile_screen.dart';

class DigitalIdScreen extends StatefulWidget {
  final UserRole userRole;

  const DigitalIdScreen({super.key, this.userRole = UserRole.student});

  @override
  State<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

class _DigitalIdScreenState extends State<DigitalIdScreen> with SingleTickerProviderStateMixin {
  File? profileImage;
  int themeIndex = 0;
  bool isDownloading = false;
  bool isFlipped = false; // 👈 naya - card flip ke liye

  final GlobalKey _cardKey = GlobalKey();

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  final List<List<Color>> themes = [
    [Colors.blue, const Color(0xFF1565C0)],
    [Colors.purple, const Color(0xFF6A1B9A)],
    [Colors.teal, const Color(0xFF00695C)],
    [const Color(0xFF37474F), const Color(0xFF102027)],
    [Colors.orange, const Color(0xFFE65100)],
  ];

  final List<String> themeNames = ["Ocean Blue", "Royal Purple", "Emerald Teal", "Midnight Dark", "Sunset Orange"];

  Map<String, String> get _studentData => {
        "name": "Prasad",
        "id": "ST2026001",
        "roll": "123",
        "dept": "Computer Engineering",
        "validTill": "30 June 2027",
      };

  Map<String, String> get _teacherData => {
        "name": "Dr. Rajesh Sharma",
        "id": "FAC2019045",
        "dept": "Chemistry Department",
        "validTill": "31 March 2028",
      };

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.lightImpact();
    if (isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => isFlipped = !isFlipped);
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => profileImage = File(picked.path));
    }
  }

  void _changeTheme() {
    HapticFeedback.mediumImpact();
    setState(() => themeIndex = (themeIndex + 1) % themes.length);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎨 Theme: ${themeNames[themeIndex]}"),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
        backgroundColor: themes[themeIndex][0],
      ),
    );
  }

  // 👇 FIX: "gal" nahi, "Gal" (capital G) - ye class hai, static methods isi se call hote hain
  Future<void> _downloadId() async {
    // Agar card abhi flipped hai to pehle front pe le aao (front side hi download honi chahiye)
    if (isFlipped) {
      _flipController.reverse();
      setState(() => isFlipped = false);
      await Future.delayed(const Duration(milliseconds: 550));
    }

    setState(() => isDownloading = true);
    HapticFeedback.mediumImpact();

    try {
      // Permission check - kuch devices pe explicit check better hota hai
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception("Gallery permission denied");
        }
      }

      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      await Gal.putImageBytes(pngBytes, name: "digital_id_${DateTime.now().millisecondsSinceEpoch}");

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text("ID Card gallery mein save ho gaya!"),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(14),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Download fail hua: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(14),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  void _viewQr(String qrPayload, Color color) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.qr_code_scanner_rounded, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text("Scan for Verification", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: qrPayload, size: 220, version: QrVersions.auto),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userRole == UserRole.student;
    final data = isStudent ? _studentData : _teacherData;
    final cardColors = themes[themeIndex];
    final primaryColor = cardColors[0];

    final qrPayload = jsonEncode({
      "id": data["id"],
      "name": data["name"],
      "role": isStudent ? "student" : "teacher",
      "dept": data["dept"],
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Digital ID", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // 👇 Tap to flip - front/back dono sides
          GestureDetector(
            onTap: _toggleFlip,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * 3.14159;
                final showFront = _flipAnimation.value < 0.5;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                  child: showFront
                      ? _buildFrontCard(data, cardColors, primaryColor, qrPayload, isStudent)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(3.14159),
                          child: _buildBackCard(cardColors, primaryColor),
                        ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          Center(
            child: Text(
              "💫 Tap card to flip",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Text("Actions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(themeNames[themeIndex], style: TextStyle(fontSize: 10.5, color: primaryColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              _ActionTile(
                icon: isDownloading ? Icons.hourglass_top_rounded : Icons.download_outlined,
                label: isDownloading ? "Saving..." : "Download ID",
                color: Colors.blue,
                onTap: isDownloading ? null : _downloadId,
              ),
              _ActionTile(
                icon: Icons.share_outlined,
                label: "Share ID",
                color: Colors.green,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Share.share("${data["name"]} - ${isStudent ? "Student" : "Faculty"} ID: ${data["id"]}\n${data["dept"]}");
                },
              ),
              _ActionTile(
                icon: Icons.photo_camera_outlined,
                label: "Change Photo",
                color: Colors.orange,
                onTap: _pickImage,
              ),
              _ActionTile(
                icon: Icons.qr_code_2_rounded,
                label: "View QR",
                color: Colors.purple,
                onTap: () => _viewQr(qrPayload, primaryColor),
              ),
              _ActionTile(
                icon: Icons.palette_outlined,
                label: "Change Theme",
                color: Colors.teal,
                onTap: _changeTheme,
              ),
              _ActionTile(
                icon: Icons.flip_camera_android_outlined,
                label: "Flip Card",
                color: Colors.indigo,
                onTap: _toggleFlip,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 👇 Front side - poori details
  Widget _buildFrontCard(Map<String, String> data, List<Color> cardColors, Color primaryColor, String qrPayload, bool isStudent) {
    return RepaintBoundary(
      key: _cardKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: cardColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("DIGITAL ID", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text("Verified", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFE3F2FD),
                          backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                          child: profileImage == null
                              ? Icon(isStudent ? Icons.person : Icons.person_2_outlined, size: 42, color: primaryColor)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data["name"]!, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(data["dept"]!, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                      const SizedBox(height: 10),
                      if (isStudent) Text("Roll No: ${data["roll"]}", style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text("ID: ${data["id"]}", style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _viewQr(qrPayload, primaryColor),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: QrImageView(data: qrPayload, size: 56, version: QrVersions.auto),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withOpacity(0.25)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_available_outlined, color: Colors.white70, size: 15),
                const SizedBox(width: 6),
                Text("Valid Till: ${data["validTill"]}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 👇 Back side - naya feature: emergency info + barcode-jaisa design
  Widget _buildBackCard(List<Color> cardColors, Color primaryColor) {
    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: cardColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text("CARD INFORMATION", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📌 Ye card college property hai", style: TextStyle(color: Colors.white, fontSize: 12, height: 1.6)),
                Text("📌 Kho jaye to turant office ko inform karein", style: TextStyle(color: Colors.white, fontSize: 12, height: 1.6)),
                Text("📌 Card sirf identification ke liye valid hai", style: TextStyle(color: Colors.white, fontSize: 12, height: 1.6)),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                // simple barcode-look decoration
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(30, (i) {
                    return Container(
                      width: 2,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 0.8),
                      color: Colors.white.withOpacity(i % 3 == 0 ? 0.9 : 0.4),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                const Text("XYZ ENGINEERING COLLEGE", style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}