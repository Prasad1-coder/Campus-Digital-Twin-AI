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
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class DigitalIdScreen extends StatefulWidget {
  const DigitalIdScreen({super.key}); // 👈 FIX: const constructor

  @override
  State<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

class _DigitalIdScreenState extends State<DigitalIdScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final GlobalKey _cardKey = GlobalKey();
  
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  
  File? _profileImage;
  bool _isFlipped = false;
  bool _isLost = false;
  bool _isDownloading = false;

  // ---------- Theme ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _user => _authService.getCurrentUser();
  bool get _isStudent => _user?.role == UserRole.student;
  bool get _canVerify => _user?.role == UserRole.hod || _user?.role == UserRole.principal;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600), 
      vsync: this
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.lightImpact();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _downloadId() async {
    if (_isFlipped) {
      _flipController.reverse();
      setState(() => _isFlipped = false);
      await Future.delayed(const Duration(milliseconds: 650));
    }

    setState(() => _isDownloading = true);
    HapticFeedback.mediumImpact();

    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      await Gal.putImageBytes(pngBytes, name: "digital_id_${_user?.id ?? 'guest'}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text("ID Card saved to gallery!"),
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
            content: Text("❌ Download failed: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(14),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _shareId() {
    HapticFeedback.selectionClick();
    Share.share("Check out my Campus Digital ID: ${_user?.fullName ?? 'Guest'} (${_user?.collegeId ?? 'N/A'}). Verified via Campus Digital Twin AI.");
  }

  void _toggleLostMode() {
    HapticFeedback.heavyImpact();
    setState(() => _isLost = !_isLost);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLost ? "🚨 Card Marked as Lost. Access Deactivated." : "✅ Card Reactivated."),
        backgroundColor: _isLost ? Colors.red.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  void _showQrDialog() {
    HapticFeedback.selectionClick();
    final String qrData = jsonEncode({
      "id": _user?.id,
      "name": _user?.fullName,
      "role": _user?.role.name,
      "dept": _user?.department
    });

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
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.qr_code_scanner_rounded, color: _primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text("Scan for Verification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _primary)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16)
                ),
                child: QrImageView(
                  data: qrData,
                  size: 220,
                  version: QrVersions.auto
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
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

  void _verifyUser() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Verify Identity", style: TextStyle(fontWeight: FontWeight.w800, color: _textDark)),
        content: const Text("Use camera to scan student/faculty QR code for instant verification and attendance marking. (UI Ready)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Scanner opening... (UI Placeholder)")),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text("Open Scanner"),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              pinned: true,
              backgroundColor: _primary,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.badge, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smart Digital ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Campus Digital Twin AI', style: TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
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
                                ? _buildFrontCard()
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(3.14159),
                                    child: _buildBackCard(),
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "💫 Tap card to flip",
                        style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildActionsGrid(),
                    const SizedBox(height: 24),
                    _buildFutureReadyGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FRONT CARD ----------------
  Widget _buildFrontCard() {
    return RepaintBoundary(
      key: _cardKey,
      child: Stack(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10)
                )
              ],
              image: const DecorationImage(
                image: AssetImage('assets/bg_id_card.png'), // Fallback if asset exists, else gradient
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(_primaryDark, BlendMode.srcOver),
              ),
              gradient: const LinearGradient(
                colors: [_primaryDark, _primary, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text("CAMPUS DIGITAL TWIN AI",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1
                            )
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                              SizedBox(width: 4),
                              Text("Verified",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold
                                )
                              ),
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
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: _softBlue,
                                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                                  child: _profileImage == null
                                      ? const Icon(Icons.person, size: 45, color: _primary)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2)
                                  ),
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
                              Text(_user?.fullName ?? "Guest User",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800
                                )
                              ),
                              const SizedBox(height: 4),
                              Text(_user?.designation ?? "Student",
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _infoChip("ID: ${_user?.collegeId ?? 'N/A'}"),
                                  if (_isStudent) _infoChip("Sem: ${_user?.semester ?? 6}"),
                                  if (_isStudent) _infoChip("Div: ${_user?.division ?? 'A'}"),
                                  if (!_isStudent) _infoChip("Dept: ${_user?.department ?? 'N/A'}"),
                                ],
                              )
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _showQrDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: QrImageView(
                              data: _user?.id ?? "guest",
                              size: 55,
                              version: QrVersions.auto
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_available_outlined, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Text(_isStudent ? "Valid Till: 30 June 2027" : "Valid Till: 31 March 2028",
                              style: const TextStyle(color: Colors.white70, fontSize: 11)
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _accessChip(Icons.library_books),
                            _accessChip(Icons.science),
                            _accessChip(Icons.directions_bus),
                            _accessChip(Icons.meeting_room),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_user?.role == UserRole.hod || _user?.role == UserRole.principal)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _user?.role == UserRole.principal ? Colors.amber : Colors.purple,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomLeft: Radius.circular(12))
                ),
                child: Text(
                  _user?.role == UserRole.principal ? "SUPER ADMIN" : "DEPT HEAD",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (_isLost)
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "DEACTIVATED",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _accessChip(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2),
        ],
      ),
      child: Icon(icon, size: 10, color: _primary),
    );
  }

  // ---------------- BACK CARD ----------------
  Widget _buildBackCard() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_primaryDark, _primary, _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20),
            color: Colors.black.withOpacity(0.85),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBox("BLOOD GROUP", "B+"),
                    _infoBox("EMERGENCY", _user?.phoneNumber ?? "+91 98765 43210"),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Terms & Conditions",
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const Text(
                  "• This card is non-transferable.\n• If found, please return to the college office.\n• Misuse of this card is a punishable offense.",
                  style: TextStyle(color: Colors.white60, fontSize: 9, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(25, (i) {
                              double width = (i % 3 == 0) ? 2.5 : (i % 2 == 0) ? 1.0 : 1.5;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                width: width,
                                height: 25,
                                color: Colors.black87,
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "XYZ COLLEGE • ${_user?.collegeId ?? 'N/A'}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_user?.role == UserRole.principal)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(Icons.draw, color: Colors.white.withOpacity(0.8), size: 32),
                          const Text("Authorized Signature", style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                        ],
                      )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 8,
              fontWeight: FontWeight.bold
            )
          ),
          const SizedBox(height: 2),
          Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold
            )
          ),
        ],
      ),
    );
  }

  // ---------------- ACTIONS GRID ----------------
  Widget _buildActionsGrid() {
    final theme = Theme.of(context);
    List<Map<String, dynamic>> actions = [
      {"icon": Icons.qr_code_2_rounded, "label": "Show QR", "color": Colors.purple, "onTap": _showQrDialog},
      {"icon": _isDownloading ? Icons.hourglass_top_rounded : Icons.download_outlined, "label": _isDownloading ? "Saving..." : "Download", "color": Colors.blue, "onTap": _isDownloading ? () {} : _downloadId},
      {"icon": Icons.share_outlined, "label": "Share ID", "color": Colors.green, "onTap": _shareId},
    ];

    if (_canVerify) {
      actions.add({"icon": Icons.verified_user_outlined, "label": "Verify User", "color": Colors.orange, "onTap": _verifyUser});
    } else {
      actions.add({"icon": _isLost ? Icons.lock_open_outlined : Icons.report_problem_outlined, "label": _isLost ? "Reactivate" : "Report Lost", "color": _isLost ? Colors.green : Colors.red, "onTap": _toggleLostMode});
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: actions.map((a) {
        return GestureDetector(
          onTap: a['onTap'],
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor, // 👈 FIX: Adapts to Dark Mode
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: (a['color'] as Color).withOpacity(0.1), blurRadius: 8)
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a['icon'] as IconData, color: a['color'] as Color, size: 24),
                const SizedBox(height: 8),
                Text(a['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)), // 👈 FIX
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFutureReadyGrid() {
    final theme = Theme.of(context);
    final features = [
      {"icon": Icons.nfc_outlined, "label": "NFC Pay"},
      {"icon": Icons.local_library_outlined, "label": "Library"},
      {"icon": Icons.meeting_room_outlined, "label": "Hostel"},
      {"icon": Icons.event_available_outlined, "label": "Events"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Smart Access", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: features.map((a) {
            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor, // 👈 FIX: Adapts to Dark Mode
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor), // 👈 FIX
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a['icon'] as IconData, color: _primary, size: 22),
                  const SizedBox(height: 6),
                  Text(a['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.hintColor)), // 👈 FIX
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}