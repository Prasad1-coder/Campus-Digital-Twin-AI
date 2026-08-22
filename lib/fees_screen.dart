import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  static const Color _gridColor = Color(0xFFE0E0E0);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _isStudent => _currentUser?.role == UserRole.student;

  // Dummy Data - Student
  final double _totalPending = 45000;
  final List<Map<String, dynamic>> _feeBreakdown = [
    {"title": "Tuition Fee", "amount": 75000, "status": "Paid", "date": "10 Aug 2024"},
    {"title": "Hostel Fee", "amount": 30000, "status": "Paid", "date": "10 Aug 2024"},
    {"title": "Examination Fee", "amount": 45000, "status": "Pending", "date": "Due 15 Dec 2024"},
    {"title": "Library Fine", "amount": 500, "status": "Pending", "date": "Due 10 Dec 2024"},
  ];

  // Dummy Data - Admin
  final List<Map<String, dynamic>> _deptCollections = [
    {"dept": "CSE", "collected": 85, "color": Colors.blue},
    {"dept": "IT", "collected": 78, "color": Colors.purple},
    {"dept": "ENTC", "collected": 92, "color": Colors.teal},
    {"dept": "MECH", "collected": 65, "color": Colors.orange},
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
            gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total Pending Amount", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text("₹ $_totalPending", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Redirecting to Payment Gateway... (UI)")),
                    );
                  },
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Fee Breakdown
        _sectionTitle("Fee Breakdown", Icons.receipt_long_rounded),
        const SizedBox(height: 16),
        ..._feeBreakdown.map((f) => _buildFeeCard(f)).toList(),
        
        const SizedBox(height: 24),
        
        // Payment History
        _sectionTitle("Payment History", Icons.history_rounded),
        const SizedBox(height: 16),
        _buildHistoryCard("Tuition Fee", "₹75,000", "10 Aug 2024", "TXN001234"),
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

  Widget _buildHistoryCard(String title, String amount, String date, String txnId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBlue, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                Text("$date • $txnId", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.download_outlined, color: _primary), onPressed: () {}),
        ],
      ),
    );
  }

  // ============================================================
  //  ADMIN VIEW (Principal / HOD)
  // ============================================================
  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _statCard("Total Collected", "₹ 1.2Cr", Icons.account_balance_wallet_rounded, Colors.green),
            _statCard("Pending Dues", "₹ 14.5L", Icons.warning_amber_rounded, Colors.red),
            _statCard("Transactions", "1,240", Icons.receipt_rounded, Colors.blue),
            _statCard("Defaulters", "45", Icons.person_off_rounded, Colors.orange),
          ],
        ),
        const SizedBox(height: 24),

        // Department Collections Bar Chart
        _sectionTitle("Department Fee Collection", Icons.bar_chart_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(color: _gridColor, strokeWidth: 1, dashArray: [4]),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            const style = TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold);
                            Widget text;
                            switch (value.toInt()) {
                              case 0: text = const Text('CSE', style: style); break;
                              case 1: text = const Text('IT', style: style); break;
                              case 2: text = const Text('ENTC', style: style); break;
                              case 3: text = const Text('MECH', style: style); break;
                              default: text = const Text('', style: style); break;
                            }
                            return Padding(child: text, padding: const EdgeInsets.only(top: 8));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 11));
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _makeBarData(0, _deptCollections[0]["collected"].toDouble(), _deptCollections[0]["color"]),
                      _makeBarData(1, _deptCollections[1]["collected"].toDouble(), _deptCollections[1]["color"]),
                      _makeBarData(2, _deptCollections[2]["collected"].toDouble(), _deptCollections[2]["color"]),
                      _makeBarData(3, _deptCollections[3]["collected"].toDouble(), _deptCollections[3]["color"]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text("Collection %", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Export Report Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating Fee Report... (UI)")));
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

  BarChartGroupData _makeBarData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: _softBlue,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  REUSABLE WIDGETS
  // ============================================================
  Widget _statCard(String title, String value, IconData icon, Color color) {
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
      ],
    );
  }
}