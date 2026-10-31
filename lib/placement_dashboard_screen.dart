import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class PlacementDashboardScreen extends StatefulWidget {
  const PlacementDashboardScreen({super.key});

  @override
  State<PlacementDashboardScreen> createState() =>
      _PlacementDashboardScreenState();
}

class _PlacementDashboardScreenState extends State<PlacementDashboardScreen> {
  static const blue = Color(0xFF1565C0);
  static const background = Color(0xFFF5F8FC);

  final _auth = AuthService();
  final _searchController = TextEditingController();
  String _search = '';

  UserModel? get _user => _auth.getCurrentUser();
  bool get _isStudent => _user?.role == UserRole.student;
  bool get _canManage => _auth.hasPermission('placement', 'canManage');
  bool get _canViewAnalytics => _auth.hasPermission('analytics', 'canView');

  // Demo data only. Replace with Firestore/API data when connected.
  final List<Map<String, String>> _jobs = [
    {'company': 'Google', 'role': 'Software Engineer', 'package': '₹28 LPA', 'location': 'Bengaluru'},
    {'company': 'Microsoft', 'role': 'Software Developer', 'package': '₹25 LPA', 'location': 'Hyderabad'},
    {'company': 'Amazon', 'role': 'Data Analyst', 'package': '₹12 LPA', 'location': 'Pune'},
  ];

  final List<Map<String, String>> _internships = [
    {'company': 'Flipkart', 'role': 'Software Intern', 'details': '6 months • Remote', 'stipend': '₹50k/month'},
    {'company': 'Zomato', 'role': 'Data Analyst Intern', 'details': '4 months • Hybrid', 'stipend': '₹40k/month'},
  ];

  final List<Map<String, String>> _drives = [
    {'company': 'TCS Digital', 'details': 'Date and eligibility to be announced'},
    {'company': 'Infosys', 'details': 'Date and eligibility to be announced'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Map<String, String> item) {
    final query = _search.trim().toLowerCase();
    return query.isEmpty ||
        item.values.any((value) => value.toLowerCase().contains(query));
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _jobs.where(_matches).toList();
    final internships = _internships.where(_matches).toList();
    final drives = _drives.where(_matches).toList();

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              onPressed: () => _message('Connect the Create Drive form to enable this action.'),
              icon: const Icon(Icons.add),
              label: const Text('Add Drive'),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: blue,
              automaticallyImplyLeading: false,
              title: const Row(
                children: [
                  Icon(Icons.work_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Placement Portal', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('Campus Digital Twin AI', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => _message('Notifications are not connected yet.'),
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _banner(),
                    const SizedBox(height: 16),
                    _searchBox(),
                    const SizedBox(height: 22),
                    _title('Placement Opportunities'),
                    const SizedBox(height: 10),
                    if (jobs.isEmpty) _empty('No matching jobs found.') else ...jobs.map(_jobCard),
                    const SizedBox(height: 18),
                    _title('Internships'),
                    const SizedBox(height: 10),
                    if (internships.isEmpty) _empty('No matching internships found.') else ...internships.map(_internshipCard),
                    const SizedBox(height: 18),
                    _title('Placement Drives'),
                    const SizedBox(height: 10),
                    if (drives.isEmpty) _empty('No matching drives found.') else ...drives.map(_driveCard),
                    if (_isStudent) ...[
                      const SizedBox(height: 18),
                      _infoCard(Icons.lightbulb_outline, 'Career tip',
                          'Keep your resume updated and practise interview questions regularly.'),
                    ],
                    if (_canViewAnalytics) ...[
                      const SizedBox(height: 18),
                      _infoCard(Icons.insights_outlined, 'Placement Analytics',
                          'Connect real placement data to display reports and statistics.'),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), blue, Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CAREER HUB', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 11)),
            SizedBox(height: 10),
            Text('Build your future.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Explore jobs, internships and placement drives.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );

  Widget _searchBox() => TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _search = value),
        decoration: InputDecoration(
          hintText: 'Search company, role or location',
          prefixIcon: const Icon(Icons.search, color: blue),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      );

  Widget _title(String text) => Text(
        text,
        style: const TextStyle(color: Color(0xFF172554), fontSize: 18, fontWeight: FontWeight.bold),
      );

  Widget _jobCard(Map<String, String> item) => _card(
        Row(
          children: [
            _companyIcon(item['company']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['role']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${item['company']} • ${item['location']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(item['package']!, style: const TextStyle(color: blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _message('Connect the application workflow to enable this action.'),
              child: Text(_canManage ? 'Manage' : 'View'),
            ),
          ],
        ),
      );

  Widget _internshipCard(Map<String, String> item) => _card(
        Row(
          children: [
            _companyIcon(item['company']!),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['role']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${item['company']} • ${item['details']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(item['stipend']!, style: const TextStyle(color: blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _driveCard(Map<String, String> item) => _card(
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.event_available, color: blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['company']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(item['details']!, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _infoCard(IconData icon, String title, String description) => _card(
        Row(
          children: [
            Icon(icon, color: blue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _companyIcon(String name) => CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE3F2FD),
        child: Text(name[0], style: const TextStyle(color: blue, fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _card(Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(color: blue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: child,
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      );
}
