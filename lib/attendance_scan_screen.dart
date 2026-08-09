import 'package:flutter/material.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen>
    with SingleTickerProviderStateMixin {
  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  // ---------- Animation & State ----------
  late AnimationController _scanController;
  bool _isScanning = false;
  bool? _scanSuccess; // null = idle, true = success, false = failed

  // ---------- Mock Stats Data ----------
  final int _todayScanCount = 4;
  final String _lastScanTime = "10:45 AM";
  final String _lastScanSubject = "Data Structures (CS201)";

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Continuous scanning animation
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  // ---------- Scan Simulation Logic ----------
  void _simulateScan() {
    setState(() {
      _isScanning = true;
      _scanSuccess = null; // Reset state
    });

    // Simulate camera processing delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          // Randomly succeed or fail for UI demonstration
          _scanSuccess = true; 
        });
      }
    });
  }

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
            gradient: LinearGradient(
              colors: [_primaryDark, _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        title: const Text(
          "QR Attendance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCameraPreviewCard(),
            const SizedBox(height: 24),
            // Conditionally show Success/Fail UI or empty space
            if (_scanSuccess != null) _buildResultCard(_scanSuccess!),
            if (_scanSuccess != null) const SizedBox(height: 24),
            _buildStatsGrid(),
          ],
        ),
      ),
    );
  }

  // ---------- Camera Preview with Animation ----------
  Widget _buildCameraPreviewCard() {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Mock Camera Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade900, Colors.black],
                ),
              ),
              child: Center(
                child: Icon(Icons.qr_code_scanner,
                    size: 120, color: Colors.white.withOpacity(0.1)),
              ),
            ),

            // QR Frame Overlay
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            // Scanning Animation Line
            if (_isScanning)
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  final value = _scanController.value;
                  final yOffset = (value * 200) - 100; // Move from -100 to 100
                  return Transform.translate(
                    offset: Offset(0, yOffset),
                    child: Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, _primary, Colors.transparent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Overlay Text / Button
            Positioned(
              bottom: 20,
              child: _isScanning
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Scanning...",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _simulateScan,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text("Start Scanning"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Success / Failed UI ----------
  Widget _buildResultCard(bool success) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: success ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: success ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              success ? Icons.check : Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  success ? "Attendance Marked!" : "Invalid QR Code",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  success
                      ? "Data Structures (CS201) at $_lastScanTime"
                      : "Please scan a valid classroom QR code.",
                  style: TextStyle(
                    fontSize: 12,
                    color: success ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ---------- Stats Grid ----------
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard("Today's Scans", _todayScanCount.toString(), Icons.qr_code_scanner_rounded),
        _statCard("Last Scan", _lastScanTime, Icons.history_rounded),
        _statCard("Current Subject", "CS201", Icons.book_outlined),
        _statCard("Room", "204", Icons.meeting_room_outlined),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _primary, size: 22),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}