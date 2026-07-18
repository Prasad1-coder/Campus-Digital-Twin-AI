import 'dart:math';
import 'package:flutter/material.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool isRefreshing = false;
  DateTime lastUpdated = DateTime.now();

  Future<void> _refresh() async {
    setState(() => isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      isRefreshing = false;
      lastUpdated = DateTime.now();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Analytics refreshed"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(14),
        ),
      );
    }
  }

  String get _todayDate {
    final now = DateTime.now();
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${now.day} ${months[now.month - 1]} ${now.year}";
  }

  String get _lastUpdatedText {
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    return "${diff.inHours}h ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.blue,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text("AI Analytics Dashboard",
                                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.only(left: 46),
                            child: Text("Real-time Campus Intelligence",
                                style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 14, top: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text(_todayDate, style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: isRefreshing
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded),
                        onPressed: isRefreshing ? null : _refresh,
                        tooltip: "Refresh",
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionLabel(title: "Overview"),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: const [
                      _SummaryCard(icon: Icons.groups_rounded, label: "Total Students", value: "1,248", change: "+3.2%", positive: true, color: Colors.blue),
                      _SummaryCard(icon: Icons.co_present_rounded, label: "Total Teachers", value: "86", change: "+1.1%", positive: true, color: Colors.purple),
                      _SummaryCard(icon: Icons.fact_check_rounded, label: "Today's Attendance", value: "91.4%", change: "+5.0%", positive: true, color: Colors.green),
                      _SummaryCard(icon: Icons.menu_book_rounded, label: "Books Issued", value: "342", change: "+8.4%", positive: true, color: Colors.orange),
                      _SummaryCard(icon: Icons.campaign_rounded, label: "Active Notices", value: "18", change: "-2.0%", positive: false, color: Colors.red),
                      _SummaryCard(icon: Icons.celebration_rounded, label: "Upcoming Events", value: "6", change: "+12%", positive: true, color: Colors.teal),
                      _SummaryCard(icon: Icons.smart_toy_rounded, label: "AI Assistant Usage", value: "874", change: "+21%", positive: true, color: Colors.indigo),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const _SectionLabel(title: "Attendance Analytics", icon: Icons.fact_check_outlined),
                  const SizedBox(height: 12),
                  _AnalyticsCard(
                    color: Colors.green,
                    trendLabel: "Trending up",
                    trendUp: true,
                    rows: const [
                      _StatRow(label: "Today's Attendance", value: "91.4%"),
                      _StatRow(label: "Weekly Attendance", value: "88.7%"),
                      _StatRow(label: "Monthly Attendance", value: "86.2%"),
                    ],
                    footer: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Department-wise", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                        const SizedBox(height: 10),
                        const _MiniBar(label: "Computer Engg", percent: 0.93, color: Colors.blue),
                        const _MiniBar(label: "Chemistry", percent: 0.87, color: Colors.purple),
                        const _MiniBar(label: "Mechanical", percent: 0.81, color: Colors.orange),
                        const SizedBox(height: 14),
                        Text("Class-wise", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                        const SizedBox(height: 10),
                        const _MiniBar(label: "Semester 4 - Div B", percent: 0.95, color: Colors.green),
                        const _MiniBar(label: "Semester 2 - Div A", percent: 0.68, color: Colors.red),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const _SectionLabel(title: "Library Analytics", icon: Icons.menu_book_outlined),
                  const SizedBox(height: 12),
                  _AnalyticsCard(
                    color: Colors.orange,
                    trendLabel: "Active today",
                    trendUp: true,
                    rows: const [
                      _StatRow(label: "Books Issued Today", value: "34"),
                      _StatRow(label: "Books Returned", value: "27"),
                      _StatRow(label: "Overdue Books", value: "9"),
                      _StatRow(label: "Library Visitors", value: "162"),
                    ],
                    footer: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoChipRow(icon: Icons.star_rounded, label: "Most Popular Book", value: "Data Structures - Weiss"),
                        const SizedBox(height: 8),
                        _InfoChipRow(icon: Icons.apartment_rounded, label: "Most Active Dept", value: "Computer Engineering"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const _SectionLabel(title: "Notice Analytics", icon: Icons.campaign_outlined),
                  const SizedBox(height: 12),
                  _AnalyticsCard(
                    color: Colors.red,
                    trendLabel: "High engagement",
                    trendUp: true,
                    rows: const [
                      _StatRow(label: "Total Notices", value: "18"),
                      _StatRow(label: "Notice Reach", value: "1,120 students"),
                    ],
                    footer: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _CircleStat(label: "Viewed", percent: 0.94, color: Colors.green)),
                            const SizedBox(width: 16),
                            Expanded(child: _CircleStat(label: "Unread", percent: 0.06, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _InfoChipRow(icon: Icons.push_pin_rounded, label: "Most Viewed Notice", value: "Semester End Exam Timetable"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const _SectionLabel(title: "Event Analytics", icon: Icons.celebration_outlined),
                  const SizedBox(height: 12),
                  _AnalyticsCard(
                    color: Colors.teal,
                    trendLabel: "Registrations rising",
                    trendUp: true,
                    rows: const [
                      _StatRow(label: "Upcoming Events", value: "6"),
                      _StatRow(label: "Total Registrations", value: "873"),
                      _StatRow(label: "Avg Attendance Rate", value: "76%"),
                    ],
                    footer: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoChipRow(icon: Icons.emoji_events_rounded, label: "Most Popular Event", value: "TechFest 2026 - Hackathon"),
                        const SizedBox(height: 10),
                        // 👇 FIX: cascade (..add) hataya, ab ek clean Row hai spread operator ke saath
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                                  i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                )),
                            const SizedBox(width: 8),
                            const Text("4.6 Feedback Rating", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  _InsightCard(
                    icon: Icons.auto_awesome_rounded,
                    title: "🤖 AI Insights",
                    gradientColors: const [Colors.blue, Color(0xFF1565C0)],
                    points: const [
                      "Attendance increased by 5% compared to last week.",
                      "Library usage is highest today among all weekdays.",
                      "Most students searched for Python books.",
                      "Notice engagement reached 94% reach rate.",
                      "AI Assistant answered 874 student questions today.",
                    ],
                  ),

                  const SizedBox(height: 18),

                  _InsightCard(
                    icon: Icons.psychology_alt_rounded,
                    title: "🔮 AI Predictions",
                    gradientColors: const [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                    points: const [
                      "Tomorrow's attendance may reach 94%.",
                      "Library rush expected around 1:00 PM.",
                      "TechFest registrations likely to increase by 18%.",
                      "⚠️ Low attendance warning for Semester 2 - Div A.",
                    ],
                  ),

                  const SizedBox(height: 28),

                  const _SectionLabel(title: "Quick Actions"),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.6,
                    children: [
                      _QuickActionButton(
                        icon: Icons.download_rounded,
                        label: "Download Report",
                        color: Colors.blue,
                        onTap: () => _showComingSoon(context, "Download Report"),
                      ),
                      _QuickActionButton(
                        icon: Icons.picture_as_pdf_rounded,
                        label: "Export PDF",
                        color: Colors.red,
                        onTap: () => _showComingSoon(context, "Export PDF"),
                      ),
                      _QuickActionButton(
                        icon: Icons.refresh_rounded,
                        label: "Refresh Data",
                        color: Colors.green,
                        onTap: _refresh,
                      ),
                      _QuickActionButton(
                        icon: Icons.share_rounded,
                        label: "Share Analytics",
                        color: Colors.purple,
                        onTap: () => _showComingSoon(context, "Share Analytics"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Column(
                      children: [
                        Text("Last updated: $_lastUpdatedText",
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: Colors.blue.shade300),
                            const SizedBox(width: 5),
                            Text("Made with Campus Digital Twin AI",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("📄 $feature - coming soon"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData? icon;
  const _SectionLabel({required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: Colors.blue),
          const SizedBox(width: 7),
        ],
        Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
      ],
    );
  }
}

class _SummaryCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final bool positive;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
    required this.color,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    Future.delayed(Duration(milliseconds: 80 + Random().nextInt(200)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(widget.icon, color: widget.color, size: 19),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (widget.positive ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 11, color: widget.positive ? Colors.green.shade700 : Colors.red.shade700),
                      const SizedBox(width: 2),
                      Text(widget.change,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: widget.positive ? Colors.green.shade700 : Colors.red.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(widget.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(widget.label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final Color color;
  final String trendLabel;
  final bool trendUp;
  final List<_StatRow> rows;
  final Widget footer;

  const _AnalyticsCard({
    required this.color,
    required this.trendLabel,
    required this.trendUp,
    required this.rows,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(trendLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
              Icon(trendUp ? Icons.show_chart_rounded : Icons.trending_down_rounded, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 14),
          ...rows,
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 14),
          footer,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  const _MiniBar({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              Text("${(percent * 100).toInt()}%", style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChipRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChipRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleStat extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  const _CircleStat({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Color> gradientColors;
  final List<String> points;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.gradientColors,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 5, height: 5,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}