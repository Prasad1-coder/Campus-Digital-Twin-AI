import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AuthService _authService = AuthService();

  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);
  static const Color _gridColor = Color(0xFFE0E0E0);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _isPrincipal => _currentUser?.role == UserRole.principal;

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
        title: Text(
          _isPrincipal ? "College Analytics" : "Department Analytics",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Quick Stats Cards
            _buildQuickStatsGrid(),
            const SizedBox(height: 24),
            
            // 2. Placement Growth Line Chart
            _buildSectionTitle("Placement Growth", Icons.trending_up_rounded),
            const SizedBox(height: 16),
            _buildPlacementLineChart(),
            const SizedBox(height: 24),
            
            // 3. Department Attendance Bar Chart
            _buildSectionTitle("Department Attendance", Icons.bar_chart_rounded),
            const SizedBox(height: 16),
            _buildAttendanceBarChart(),
            const SizedBox(height: 24),
            
            // 4. Student Distribution Pie Chart
            _buildSectionTitle("Student Distribution", Icons.pie_chart_rounded),
            const SizedBox(height: 16),
            _buildBranchPieChart(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  WIDGETS
  // ============================================================

  Widget _buildQuickStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard("Total Students", "2,450", Icons.groups_rounded, Colors.blue),
        _statCard("Placed Students", "1,890", Icons.work_rounded, Colors.green),
        _statCard("Avg Package", "8.4 LPA", Icons.currency_rupee_rounded, Colors.orange),
        _statCard("Companies", "48", Icons.business_rounded, Colors.purple),
      ],
    );
  }

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
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
      ],
    );
  }

  // ---------------- LINE CHART (Placement Growth) ----------------
  Widget _buildPlacementLineChart() {
    return Container(
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
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
                          case 0: text = const Text('2020', style: style); break;
                          case 1: text = const Text('2021', style: style); break;
                          case 2: text = const Text('2022', style: style); break;
                          case 3: text = const Text('2023', style: style); break;
                          case 4: text = const Text('2024', style: style); break;
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
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 45),
                      FlSpot(1, 55),
                      FlSpot(2, 68),
                      FlSpot(3, 78),
                      FlSpot(4, 87),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [_accent, _primary]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [_primary.withOpacity(0.3), _primary.withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text("Overall Placement %", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ---------------- BAR CHART (Department Attendance) ----------------
  Widget _buildAttendanceBarChart() {
    return Container(
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
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(color: _gridColor, strokeWidth: 1, dashArray: [4]),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('CSE', style: style); break;
                          case 1: text = const Text('IT', style: style); break;
                          case 2: text = const Text('ENTC', style: style); break;
                          case 3: text = const Text('MECH', style: style); break;
                          case 4: text = const Text('CIVIL', style: style); break;
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
                  _makeBarData(0, 85, Colors.blue),
                  _makeBarData(1, 78, Colors.purple),
                  _makeBarData(2, 92, Colors.teal),
                  _makeBarData(3, 65, Colors.orange),
                  _makeBarData(4, 70, Colors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text("Avg Attendance %", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
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

  // ---------------- PIE CHART (Student Branch Distribution) ----------------
  Widget _buildBranchPieChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      color: Colors.blue,
                      radius: 45,
                      title: '40%',
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: 25,
                      color: Colors.purple,
                      radius: 40,
                      title: '25%',
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: 20,
                      color: Colors.teal,
                      radius: 35,
                      title: '20%',
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: 15,
                      color: Colors.orange,
                      radius: 30,
                      title: '15%',
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem("CSE", Colors.blue),
                _legendItem("IT", Colors.purple),
                _legendItem("ENTC", Colors.teal),
                _legendItem("MECH", Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
        ],
      ),
    );
  }
}