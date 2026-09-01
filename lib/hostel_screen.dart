import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class HostelScreen extends StatefulWidget {
  const HostelScreen({super.key});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  final AuthService _authService = AuthService();

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _isStudent => _currentUser?.role == UserRole.student;

  // Dummy Out-Pass Requests
  final List<Map<String, dynamic>> _outPassRequests = [
    {"name": "Prasad Patil", "room": "Room 204", "dates": "15 Dec - 17 Dec", "status": "Pending"},
    {"name": "Amit Kumar", "room": "Room 204", "dates": "16 Dec - 18 Dec", "status": "Pending"},
    {"name": "Rahul Singh", "room": "Room 302", "dates": "20 Dec - 22 Dec", "status": "Approved"},
  ];

  // 👇 FIX: Logic to apply for out-pass
  void _applyOutPass() {
    setState(() {
      // In real app, this would send to DB. For now, just show success.
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Out-Pass Request Sent to Warden ✅"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  // 👇 FIX: Logic to approve/reject
  void _updateRequestStatus(int index, String newStatus) {
    setState(() {
      _outPassRequests[index]["status"] = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Request $newStatus for ${_outPassRequests[index]["name"]}"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: newStatus == "Approved" ? Colors.green : Colors.red,
      ),
    );
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
            gradient: LinearGradient(colors: [_primaryDark, _primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        title: const Text("Hostel Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
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
        // Room Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Block A - Room 204", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                    child: const Text("Allocated", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              _infoRow(Icons.bed_outlined, "Bed No: B-12"),
              _infoRow(Icons.person_outline, "Roommate: Amit Kumar (CSE)"),
              _infoRow(Icons.stairs_outlined, "Floor: 2nd Floor"),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Out-Pass Application
        const Text("Hostel Out-Pass (Leave)", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _softBlue, width: 1.2)),
          child: Column(
            children: [
              const Text("Going home for the weekend? Apply for an out-pass below. Warden approval required.", style: TextStyle(fontSize: 13, color: Colors.black54), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _dateChip(Icons.calendar_today, "Out: 15 Dec")),
                  Expanded(child: _dateChip(Icons.calendar_today, "In: 17 Dec")),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyOutPass, // 👈 Working
                  icon: const Icon(Icons.send_rounded),
                  label: const Text("Apply for Out-Pass", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Mess Menu
        const Text("Today's Mess Menu", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
        const SizedBox(height: 16),
        _messCard("Breakfast", "Poha, boiled eggs, bananas, tea/coffee"),
        _messCard("Lunch", "Veg Biryani, raita, salad, ice cream"),
      ],
    );
  }

  Widget _dateChip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)),
        ],
      ),
    );
  }

  Widget _messCard(String time, String items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.fastfood_outlined, color: _primary, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)), const SizedBox(height: 4), Text(items, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))])),
        ],
      ),
    );
  }

  // ============================================================
  //  ADMIN VIEW (Warden)
  // ============================================================
  Widget _buildAdminView() {
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
            _statCard("Total Rooms", "120", Icons.meeting_room_rounded, Colors.blue),
            _statCard("Occupied", "112", Icons.bed_rounded, Colors.green),
            _statCard("Vacant", "08", Icons.event_available_rounded, Colors.orange),
            _statCard("Pending Leaves", "01", Icons.pending_actions_rounded, Colors.red),
          ],
        ),
        const SizedBox(height: 24),

        // Pending Out-Pass Approvals
        const Text("Pending Out-Pass Requests", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
        const SizedBox(height: 16),
        // 👇 FIX: Dynamic List with actual Approve/Reject buttons
        ..._outPassRequests.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> req = entry.value;
          return _buildOutPassCard(index, req);
        }).toList(),
      ],
    );
  }

  Widget _buildOutPassCard(int index, Map<String, dynamic> req) {
    bool isPending = req["status"] == "Pending";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isPending ? Colors.orange.shade100 : Colors.green.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                Text("${req["room"]} • ${req["dates"]}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(req["status"], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPending ? Colors.orange.shade700 : Colors.green.shade700)),
                )
              ],
            ),
          ),
          // 👇 FIX: Action buttons logic
          if (isPending)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  onPressed: () => _updateRequestStatus(index, "Rejected"),
                ),
                IconButton(
                  icon: const Icon(Icons.check_rounded, color: Colors.green),
                  onPressed: () => _updateRequestStatus(index, "Approved"),
                ),
              ],
            )
        ],
      ),
    );
  }

  // ============================================================
  //  REUSABLE WIDGETS
  // ============================================================
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [Icon(icon, color: Colors.white70, size: 16), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)))],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
          Flexible(child: Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}