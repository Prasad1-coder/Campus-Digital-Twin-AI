import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final AuthService _authService = AuthService();

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _isStudent => _currentUser?.role == UserRole.student;

  // 👇 FIX: Made data mutable
  double _totalPending = 45000;
  bool _isPaid = false;

  final List<Map<String, dynamic>> _feeBreakdown = [
    {"title": "Tuition Fee", "amount": 75000, "status": "Paid", "date": "10 Aug 2024"},
    {"title": "Hostel Fee", "amount": 30000, "status": "Paid", "date": "10 Aug 2024"},
    {"title": "Examination Fee", "amount": 45000, "status": "Pending", "date": "Due 15 Dec 2024"},
    {"title": "Library Fine", "amount": 500, "status": "Pending", "date": "Due 10 Dec 2024"},
  ];

  // 👇 FIX: Actual Payment Logic
  void _payNow() {
    setState(() {
      _totalPending = 0;
      _isPaid = true;
      // Update all pending items to Paid
      for (var fee in _feeBreakdown) {
        if (fee['status'] == 'Pending') {
          fee['status'] = 'Paid';
          fee['date'] = 'Paid on 10 Dec 2024';
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment Successful! 💰"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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
        title: const Text("Fees & Finance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
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
        // Pending Fees Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _isPaid ? [Colors.green, Colors.teal] : [Color(0xFF1A237E), Color(0xFF3949AB)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _isPaid ? Colors.green.withOpacity(0.3) : Colors.indigo.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total Pending Amount", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text("₹ $_totalPending", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (!_isPaid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _payNow, // 👈 Calls actual logic
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text("Pay Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                )
              else
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text("All Dues Cleared!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Fee Breakdown
        const Text("Fee Breakdown", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
        const SizedBox(height: 16),
        ..._feeBreakdown.map((f) => _buildFeeCard(f)).toList(),
      ],
    );
  }

  Widget _buildFeeCard(Map<String, dynamic> f) {
    bool isPending = f["status"] == "Pending";
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
                Text(f["title"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                Text(f["date"], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${f["amount"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPending ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  f["status"], 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPending ? Colors.red : Colors.green),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ============================================================
  //  ADMIN VIEW
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
            _buildStatCard("Total Collected", "₹ 1.2Cr", Icons.account_balance_wallet_rounded, Colors.green),
            _buildStatCard("Pending Dues", "₹ 14.5L", Icons.warning_amber_rounded, Colors.red),
            _buildStatCard("Transactions", "1,240", Icons.receipt_rounded, Colors.blue),
            _buildStatCard("Defaulters", "45", Icons.person_off_rounded, Colors.orange),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating Fee Report...")));
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text("Export Department Report"),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}