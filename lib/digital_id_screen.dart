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
import 'permission_model.dart';

class DigitalIdScreen extends StatefulWidget {
  const DigitalIdScreen({super.key});

  @override
  State<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

// FIX: "SingleAnimationControllerStateMixin" does not exist in Flutter.
// The correct mixin for a single AnimationController + vsync is:
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
  static const Color _lightBg = Color(0xFFF4F7FC);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _user => _authService.getCurrentUser();
  bool get _isStudent => _user?.role == UserRole.student;
  bool get _canVerify =>
      _authService.hasPermission('attendance', 'canManage') ||
      _authService.hasPermission('attendance', 'canApprove');

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
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
    Share.share(
      "Check out my Campus Digital ID: ${_user?.fullName ?? 'Guest'} (${_user?.collegeId ?? 'N/A'}). Verified via Campus Digital Twin AI.",
    );
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
      "dept": _user?.department,
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary.withOpacity(0.12), _accent.withOpacity(0.12)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_scanner_rounded, color: _primary, size: 26),
              ),
              const SizedBox(height: 14),
              Text("Scan for Verification",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
              const SizedBox(height: 4),
              Text("Show this code to campus staff", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  size: 220,
                  version: QrVersions.auto,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _primaryDark),
                  dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _primary),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w700)),
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
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: _primary, size: 22),
            const SizedBox(width: 8),
            const Text("Verify Identity", style: TextStyle(fontWeight: FontWeight.w800, color: _textDark)),
          ],
        ),
        content: const Text(
          "Use camera to scan student/faculty QR code for instant verification and attendance marking. (UI Ready)",
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Scanner opening... (UI Placeholder)"),
                  backgroundColor: _primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text("Open Scanner"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              pinned: true,
              elevation: 0,
              backgroundColor: _primary,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryDark, _primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              title: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smart Digital ID',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Campus Digital Twin AI', style: TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
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
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
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
                    const SizedBox(height: 14),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 14, color: _primary),
                            const SizedBox(width: 6),
                            Text(
                              "Tap card to flip",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Quick Actions",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark)),
                    ),
                    const SizedBox(height: 12),
                    _buildActionsGrid(),
                    const SizedBox(height: 26),
                    _buildFutureReadyGrid(),
                    const SizedBox(height: 12),
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
    final bool isSpecialRole = _user?.role == UserRole.hod || _user?.role == UserRole.principal;

    return RepaintBoundary(
      key: _cardKey,
      child: Stack(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              // NOTE: removed the DecorationImage(AssetImage('assets/bg_id_card.png'))
              // that was here before — that asset isn't declared in pubspec.yaml,
              // so it would throw an "Unable to load asset" error at runtime.
              // A gradient alone gives the same premium look without the crash risk.
              gradient: const LinearGradient(
                colors: [_primaryDark, _primary, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: Stack(
              children: [
                // subtle decorative circles for a premium card feel
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -40,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text("CAMPUS DIGITAL TWIN AI",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                              SizedBox(width: 4),
                              Text("Verified",
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8)],
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
                                    border: Border.all(color: Colors.white, width: 2),
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
                              Text(
                                _user?.fullName ?? "Guest User",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _user?.designation ?? "Student",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _infoChip("ID: ${_user?.collegeId ?? 'N/A'}"),
                                  if (_isStudent) _infoChip("Sem: ${_user?.semester ?? 6}"),
                                  if (_isStudent) _infoChip("Div: ${_user?.division ?? 'A'}"),
                                  if (!_isStudent) _infoChip("Dept: ${_user?.department ?? 'N/A'}"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
                          ),
                          child: GestureDetector(
                            onTap: _showQrDialog,
                            child: QrImageView(data: _user?.id ?? "guest", size: 55, version: QrVersions.auto),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event_available_outlined, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _isStudent ? "Valid Till: 30 June 2027" : "Valid Till: 31 March 2028",
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Role ribbon — sits cleanly in the rounded corner, matches card radius now (26)
          if (isSpecialRole)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _user?.role == UserRole.principal ? Colors.amber.shade700 : Colors.purple.shade600,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(26),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Text(
                  _user?.role == UserRole.principal ? "SUPER ADMIN" : "DEPT HEAD",
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          if (_isLost)
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.redAccent, width: 3),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.red.withOpacity(0.08),
                    ),
                    child: const Text(
                      "DEACTIVATED",
                      style: TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 3)],
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
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 18),
            color: Colors.black.withOpacity(0.85),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _infoBox("BLOOD GROUP", "B+")),
                      const SizedBox(width: 10),
                      Expanded(child: _infoBox("EMERGENCY", _user?.phoneNumber ?? "+91 98765 43210")),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.gavel_rounded, size: 11, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 5),
                      const Text("Terms & Conditions",
                          style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "• This card is non-transferable.\n• If found, please return to the college office.\n• Misuse of this card is a punishable offense.",
                    style: TextStyle(color: Colors.white60, fontSize: 8.5, height: 1.4),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                          const SizedBox(height: 6),
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
                            Icon(Icons.draw_rounded, color: Colors.white.withOpacity(0.85), size: 30),
                            const SizedBox(height: 2),
                            const Text("Authorized Signature",
                                style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ---------------- ACTIONS GRID ----------------
  Widget _buildActionsGrid() {
    List<Map<String, dynamic>> actions = [
      {"icon": Icons.qr_code_2_rounded, "label": "Show QR", "color": Colors.purple, "onTap": _showQrDialog},
      {
        "icon": _isDownloading ? Icons.hourglass_top_rounded : Icons.download_rounded,
        "label": _isDownloading ? "Saving..." : "Download",
        "color": Colors.blue,
        "onTap": _isDownloading ? () {} : _downloadId,
      },
      {"icon": Icons.share_rounded, "label": "Share ID", "color": Colors.green, "onTap": _shareId},
    ];

    if (_canVerify) {
      actions.add({"icon": Icons.verified_user_rounded, "label": "Verify User", "color": Colors.orange, "onTap": _verifyUser});
    } else {
      actions.add({
        "icon": _isLost ? Icons.lock_open_rounded : Icons.report_problem_rounded,
        "label": _isLost ? "Reactivate" : "Report Lost",
        "color": _isLost ? Colors.green : Colors.red,
        "onTap": _toggleLostMode,
      });
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: actions.map((a) {
        final Color color = a['color'] as Color;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: a['onTap'],
            borderRadius: BorderRadius.circular(18),
            splashColor: color.withOpacity(0.15),
            highlightColor: color.withOpacity(0.08),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(a['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(a['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- SMART ACCESS GRID ----------------
  Widget _buildFutureReadyGrid() {
    final features = [
      {"icon": Icons.nfc_rounded, "label": "NFC Pay", "color": Colors.indigo},
      {"icon": Icons.local_library_rounded, "label": "Library", "color": Colors.teal},
      {"icon": Icons.meeting_room_rounded, "label": "Hostel", "color": Colors.deepOrange},
      {"icon": Icons.event_available_rounded, "label": "Events", "color": Colors.pink},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Smart Access", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: features.map((a) {
            final Color color = a['color'] as Color;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(a['icon'] as IconData, color: color, size: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(a['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}