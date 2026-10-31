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

class _PlacementDashboardScreenState
    extends State<PlacementDashboardScreen> {
  static const Color _blue = Color(0xFF1565C0);

  final AuthService _auth = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  UserModel? get _user => _auth.getCurrentUser();

  bool get _isStudent => _user?.role == UserRole.student;

  bool get _canManage =>
      _auth.hasPermission('placement', 'canManage');

  bool get _canViewAnalytics =>
      _auth.hasPermission('analytics', 'canView');

  // Demo data. Connect these lists to Firestore/API later.
  final List<Map<String, String>> _jobs = [
    {
      'company': 'Google',
      'role': 'Software Engineer',
      'package': '₹28 LPA',
      'location': 'Bengaluru',
    },
    {
      'company': 'Microsoft',
      'role': 'Software Developer',
      'package': '₹25 LPA',
      'location': 'Hyderabad',
    },
    {
      'company': 'Amazon',
      'role': 'Data Analyst',
      'package': '₹12 LPA',
      'location': 'Pune',
    },
  ];

  final List<Map<String, String>> _internships = [
    {
      'company': 'Flipkart',
      'role': 'Software Intern',
      'details': '6 months • Remote',
      'stipend': '₹50k/month',
    },
    {
      'company': 'Zomato',
      'role': 'Data Analyst Intern',
      'details': '4 months • Hybrid',
      'stipend': '₹40k/month',
    },
  ];

  final List<Map<String, String>> _drives = [
    {
      'company': 'TCS Digital',
      'details': 'Date and eligibility to be announced',
    },
    {
      'company': 'Infosys',
      'details': 'Date and eligibility to be announced',
    },
  ];

  // Theme-aware colors
  Color _primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  Color _surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  Color _textColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  Color _mutedColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  Color _borderColor(BuildContext context) =>
      Theme.of(context).colorScheme.outline.withOpacity(0.25);

  Color _softPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Map<String, String> item) {
    final query = _search.trim().toLowerCase();

    return query.isEmpty ||
        item.values.any(
          (value) => value.toLowerCase().contains(query),
        );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _jobs.where(_matches).toList();
    final internships = _internships.where(_matches).toList();
    final drives = _drives.where(_matches).toList();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              backgroundColor: _primary(context),
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 3,
              onPressed: () {
                _message(
                  'Connect the Create Drive form to enable this action.',
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Drive'),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _banner(context),
                    const SizedBox(height: 20),
                    _searchBox(context),
                    const SizedBox(height: 26),

                    _sectionHeader(
                      context,
                      'Placement Opportunities',
                      Icons.work_outline,
                    ),
                    const SizedBox(height: 12),

                    if (jobs.isEmpty)
                      _empty(context, 'No matching jobs found.')
                    else
                      ...jobs.map((job) => _jobCard(context, job)),

                    const SizedBox(height: 24),

                    _sectionHeader(
                      context,
                      'Internships',
                      Icons.school_outlined,
                    ),
                    const SizedBox(height: 12),

                    if (internships.isEmpty)
                      _empty(context, 'No matching internships found.')
                    else
                      ...internships.map(
                        (item) => _internshipCard(context, item),
                      ),

                    const SizedBox(height: 24),

                    _sectionHeader(
                      context,
                      'Placement Drives',
                      Icons.event_available_outlined,
                    ),
                    const SizedBox(height: 12),

                    if (drives.isEmpty)
                      _empty(context, 'No matching drives found.')
                    else
                      ...drives.map(
                        (item) => _driveCard(context, item),
                      ),

                    if (_isStudent) ...[
                      const SizedBox(height: 24),
                      _infoCard(
                        context,
                        Icons.lightbulb_outline,
                        'Career Tip',
                        'Keep your resume updated and practise interview questions regularly.',
                      ),
                    ],

                    if (_canViewAnalytics) ...[
                      const SizedBox(height: 16),
                      _infoCard(
                        context,
                        Icons.insights_outlined,
                        'Placement Analytics',
                        'Connect actual placement data to display reports and statistics.',
                      ),
                    ],

                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // App Bar
  Widget _appBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: _isDark(context)
          ? const Color(0xFF101B2D)
          : const Color(0xFF1565C0),
      title: const Row(
        children: [
          Icon(
            Icons.work_outline_rounded,
            color: Colors.white,
            size: 25,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Placement Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Campus Digital Twin AI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            _message('Notifications are not connected yet.');
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // Banner
  Widget _banner(BuildContext context) {
    final isDark = _isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF102A50),
                  Color(0xFF164B80),
                  Color(0xFF176B91),
                ]
              : const [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF42A5F5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(isDark ? 0.12 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -15,
            child: Icon(
              Icons.rocket_launch_outlined,
              size: 105,
              color: Colors.white.withOpacity(0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CAREER HUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Build your future.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Explore jobs, internships and placement drives.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search
  Widget _searchBox(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _search = value);
      },
      style: TextStyle(
        color: _textColor(context),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search company, role or location',
        hintStyle: TextStyle(
          color: _mutedColor(context),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: _primary(context),
        ),
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
        fillColor: _surface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: _borderColor(context),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: _borderColor(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: _primary(context),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // Section Header
  Widget _sectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _softPrimary(context).withOpacity(0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 19,
            color: _primary(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _textColor(context),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Job Card
  Widget _jobCard(
    BuildContext context,
    Map<String, String> item,
  ) {
    return _card(
      context,
      Row(
        children: [
          _companyIcon(context, item['company']!),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['role']!,
                  style: TextStyle(
                    color: _textColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item['company']} • ${item['location']}',
                  style: TextStyle(
                    color: _mutedColor(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['package']!,
                  style: TextStyle(
                    color: _primary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          TextButton(
            onPressed: () {
              _message(
                'Connect the application workflow to enable this action.',
              );
            },
            child: Text(
              _canManage ? 'Manage' : 'View',
              style: TextStyle(
                color: _primary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Internship Card
  Widget _internshipCard(
    BuildContext context,
    Map<String, String> item,
  ) {
    return _card(
      context,
      Row(
        children: [
          _companyIcon(context, item['company']!),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['role']!,
                  style: TextStyle(
                    color: _textColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item['company']} • ${item['details']}',
                  style: TextStyle(
                    color: _mutedColor(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['stipend']!,
                  style: TextStyle(
                    color: _primary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placement Drive Card
  Widget _driveCard(
    BuildContext context,
    Map<String, String> item,
  ) {
    return _card(
      context,
      Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: _softPrimary(context).withOpacity(0.55),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: _primary(context),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['company']!,
                  style: TextStyle(
                    color: _textColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item['details']!,
                  style: TextStyle(
                    color: _mutedColor(context),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Information Card
  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return _card(
      context,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _primary(context),
            size: 27,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: _mutedColor(context),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Company Icon
  Widget _companyIcon(
    BuildContext context,
    String name,
  ) {
    return CircleAvatar(
      radius: 23,
      backgroundColor: _softPrimary(context).withOpacity(0.55),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: _primary(context),
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Common Card
  Widget _card(
    BuildContext context,
    Widget child,
  ) {
    final isDark = _isDark(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _borderColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // Empty Search Result
  Widget _empty(
    BuildContext context,
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _borderColor(context),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 28,
            color: _mutedColor(context),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: _mutedColor(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}