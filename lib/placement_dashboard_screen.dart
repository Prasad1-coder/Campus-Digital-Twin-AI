import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'permission_model.dart';

/// ============================================================
///  Placement & Internship Dashboard (Role-Based ERP)
///  Campus Digital Twin AI
///  Material 3 • Blue & White • No Backend • Dummy Data
/// ============================================================

class PlacementDashboardScreen extends StatefulWidget {
  const PlacementDashboardScreen({super.key});

  @override
  State<PlacementDashboardScreen> createState() =>
      _PlacementDashboardScreenState();
}

class _PlacementDashboardScreenState extends State<PlacementDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final AuthService _authService = AuthService();
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedCategory = 0;

  // ---------- Theme constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  // ---------- Role & Permissions ----------
  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _isStudent => _currentUser?.role == UserRole.student;
  bool get _canManage => _authService.hasPermission('placement', 'canManage'); // Teacher/HOD/Principal
  bool get _canViewAnalytics => _authService.hasPermission('analytics', 'canView'); // HOD/Principal

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- Dummy Data ----------
  final List<Map<String, dynamic>> _stats = [
    {'icon': Icons.business_center, 'value': '248', 'title': 'Total Companies', 'trend': '+12%', 'color': Colors.blue},
    {'icon': Icons.work_outline, 'value': '1,456', 'title': 'Active Jobs', 'trend': '+8%', 'color': Colors.indigo},
    {'icon': Icons.school_outlined, 'value': '320', 'title': 'Internships', 'trend': '+15%', 'color': Colors.teal},
    {'icon': Icons.assignment_turned_in_outlined, 'value': '14', 'title': 'My Applications', 'trend': '+3', 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.code, 'name': 'IT'},
    {'icon': Icons.developer_mode, 'name': 'Software'},
    {'icon': Icons.engineering, 'name': 'Core Eng.'},
    {'icon': Icons.account_balance, 'name': 'Government'},
    {'icon': Icons.attach_money, 'name': 'Finance'},
    {'icon': Icons.campaign, 'name': 'Marketing'},
    {'icon': Icons.school, 'name': 'Internship'},
    {'icon': Icons.laptop_mac, 'name': 'Remote'},
  ];

  final List<Map<String, dynamic>> _featured = [
    {'name': 'Google', 'logo': 'G', 'role': 'Software Engineer', 'ctc': '₹28 LPA', 'location': 'Bangalore', 'eligibility': 'CGPA 7.5+', 'color': Colors.red},
    {'name': 'Microsoft', 'logo': 'M', 'role': 'SDE - I', 'ctc': '₹25 LPA', 'location': 'Hyderabad', 'eligibility': 'CGPA 8.0+', 'color': Colors.blue},
    {'name': 'Amazon', 'logo': 'A', 'role': 'SDE - I', 'ctc': '₹22 LPA', 'location': 'Pune', 'eligibility': 'CGPA 7.0+', 'color': Colors.orange},
    {'name': 'Goldman Sachs', 'logo': 'G', 'role': 'Analyst', 'ctc': '₹21 LPA', 'location': 'Mumbai', 'eligibility': 'CGPA 8.5+', 'color': Colors.indigo},
  ];

  final List<Map<String, dynamic>> _internships = [
    {'name': 'Flipkart', 'logo': 'F', 'role': 'SDE Intern', 'duration': '6 Months', 'stipend': '₹50k/mo', 'mode': 'Remote', 'color': Colors.yellow.shade800},
    {'name': 'Swiggy', 'logo': 'S', 'role': 'Product Intern', 'duration': '3 Months', 'stipend': '₹35k/mo', 'mode': 'Onsite', 'color': Colors.orange},
    {'name': 'Zomato', 'logo': 'Z', 'role': 'Data Analyst', 'duration': '4 Months', 'stipend': '₹40k/mo', 'mode': 'Hybrid', 'color': Colors.red},
    {'name': 'Paytm', 'logo': 'P', 'role': 'ML Intern', 'duration': '6 Months', 'stipend': '₹45k/mo', 'mode': 'Remote', 'color': Colors.blue},
  ];

  final List<Map<String, dynamic>> _drives = [
    {'name': 'TCS Digital', 'date': '15 Dec 2024', 'venue': 'Auditorium Block-A', 'deadline': '12 Dec 2024', 'branches': 'CSE, IT, ECE'},
    {'name': 'Infosys', 'date': '20 Dec 2024', 'venue': 'Seminar Hall-2', 'deadline': '18 Dec 2024', 'branches': 'All Branches'},
    {'name': 'Wipro Elite', 'date': '22 Dec 2024', 'venue': 'Online (Virtual)', 'deadline': '20 Dec 2024', 'branches': 'CSE, IT, ECE, EEE'},
    {'name': 'Capgemini', 'date': '28 Dec 2024', 'venue': 'Auditorium Block-B', 'deadline': '26 Dec 2024', 'branches': 'CSE, IT'},
  ];

  final List<Map<String, dynamic>> _placementStats = [
    {'icon': Icons.trending_up, 'value': '₹52 LPA', 'title': 'Highest Package', 'color': Colors.green},
    {'icon': Icons.bar_chart, 'value': '₹8.4 LPA', 'title': 'Average Package', 'color': Colors.blue},
    {'icon': Icons.people_alt_outlined, 'value': '1,240', 'title': 'Students Placed', 'color': Colors.indigo},
    {'icon': Icons.apartment, 'value': '186', 'title': 'Companies Visited', 'color': Colors.purple},
    {'icon': Icons.percent, 'value': '87%', 'title': 'Placement Rate', 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> _trending = [
    {'name': 'Adobe', 'role': 'Product Engineer', 'hiring': '12 roles', 'color': Colors.red},
    {'name': 'Atlassian', 'role': 'Backend Dev', 'hiring': '8 roles', 'color': Colors.blue},
    {'name': 'Uber', 'role': 'SDE - II', 'hiring': '5 roles', 'color': Colors.black87},
    {'name': 'Myntra', 'role': 'Frontend Dev', 'hiring': '15 roles', 'color': Colors.pink},
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.business, 'label': 'Companies'},
    {'icon': Icons.school, 'label': 'Internships'},
    {'icon': Icons.assignment, 'label': 'Applications'},
    {'icon': Icons.description, 'label': 'Resume'},
    {'icon': Icons.bookmark, 'label': 'Saved Jobs'},
    {'icon': Icons.calendar_today, 'label': 'Calendar'},
  ];

  final List<Map<String, dynamic>> _aiButtons = [
    {'icon': Icons.description_outlined, 'label': 'Resume Review'},
    {'icon': Icons.quiz_outlined, 'label': 'Interview Questions'},
    {'icon': Icons.lightbulb_outline, 'label': 'Career Guidance'},
    {'icon': Icons.psychology, 'label': 'Skill Recommendations'},
    {'icon': Icons.tips_and_updates_outlined, 'label': 'Company Prep Tips'},
  ];

  final List<Map<String, String>> _news = [
    {'title': 'Google on-campus drive announced', 'time': '2h ago'},
    {'title': 'Microsoft fresher hiring opens', 'time': '5h ago'},
    {'title': 'Internship fair on 18 December', 'time': '1d ago'},
  ];

  // New Dummy Data for Student & Admin Modules
  final List<Map<String, dynamic>> _applications = [
    {'company': 'Google', 'role': 'Software Engineer', 'status': 'Interview', 'color': Colors.red, 'date': '10 Dec'},
    {'company': 'Microsoft', 'role': 'SDE - I', 'status': 'Offer Received', 'color': Colors.blue, 'date': '08 Dec'},
    {'company': 'Amazon', 'role': 'SDE - I', 'status': 'Applied', 'color': Colors.orange, 'date': '05 Dec'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text("Add Company / Drive", style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Open Create Company Form (UI Ready)")));
              },
            )
          : null,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildBanner()),
                SliverToBoxAdapter(child: _buildSearch()),
                SliverToBoxAdapter(child: _buildSectionTitle('Quick Statistics')),
                SliverToBoxAdapter(child: _buildStats()),
                SliverToBoxAdapter(child: _buildSectionTitle('Job Categories')),
                SliverToBoxAdapter(child: _buildCategories()),
                
                // Role Specific Student Sections
                if (_isStudent) ...[
                  SliverToBoxAdapter(child: _buildSectionTitle('My Applications')),
                  SliverToBoxAdapter(child: _buildApplications()),
                  SliverToBoxAdapter(child: _buildResumeScoreCard()),
                ],
                
                // Role Specific Admin Sections
                if (_canManage) ...[
                  SliverToBoxAdapter(child: _buildSectionTitle('Manage Drives & Applicants')),
                  SliverToBoxAdapter(child: _buildAdminQuickActions()),
                ],

                SliverToBoxAdapter(child: _buildSectionTitle('Featured Companies')),
                SliverToBoxAdapter(child: _buildFeatured()),
                SliverToBoxAdapter(child: _buildSectionTitle('Internship Opportunities')),
                SliverToBoxAdapter(child: _buildInternships()),
                SliverToBoxAdapter(child: _buildSectionTitle('Upcoming Placement Drives')),
                SliverToBoxAdapter(child: _buildDrives()),
                
                if (_canViewAnalytics) ...[
                  SliverToBoxAdapter(child: _buildSectionTitle(_canManage ? 'College Analytics' : 'Department Analytics')),
                ] else ...[
                  SliverToBoxAdapter(child: _buildSectionTitle('Placement Insights')),
                ],
                SliverToBoxAdapter(child: _buildPlacementStats()),
                
                SliverToBoxAdapter(child: _buildAIAssistant()),
                SliverToBoxAdapter(child: _buildSectionTitle('Trending Opportunities')),
                SliverToBoxAdapter(child: _buildTrending()),
                SliverToBoxAdapter(child: _buildSectionTitle('Quick Actions')),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildBottomSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- App Bar ----------------
  Widget _buildAppBar() {
    return SliverAppBar(
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
            child: const Icon(Icons.work, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Placement Portal',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text('Campus Digital Twin AI',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ---------------- Banner ----------------
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_primaryDark, _primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('💼 Career Hub',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Placement & Internship Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find Jobs, Internships & Build Your Career',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _bannerChip('🔥 1,456 Jobs'),
                    const SizedBox(width: 8),
                    _bannerChip('🎯 87% Placed'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.white, size: 44),
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label,
          style: const TextStyle(color: _primaryDark, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // ---------------- Search ----------------
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search company, internship or job role...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: _primary),
            suffixIcon: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  // ---------------- Section Title ----------------
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          Text('See All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _primary,
              )),
        ],
      ),
    );
  }

  // ---------------- Stats ----------------
  Widget _buildStats() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, i) {
        final s = _stats[i];
        return _StatCard(
          icon: s['icon'] as IconData,
          value: s['value'] as String,
          title: s['title'] as String,
          trend: s['trend'] as String,
          color: s['color'] as Color,
        );
      },
    );
  }

  // ---------------- Categories ----------------
  Widget _buildCategories() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = _categories[i];
          final selected = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 78,
              decoration: BoxDecoration(
                color: selected ? _primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(c['icon'] as IconData,
                      color: selected ? Colors.white : _primary, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    c['name'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- Student Applications ----------------
  Widget _buildApplications() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _applications.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final app = _applications[i];
          Color statusColor = Colors.orange;
          if (app['status'] == 'Offer Received') statusColor = Colors.green;
          if (app['status'] == 'Interview') statusColor = Colors.blue;

          return Container(
            width: 220,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: (app['color'] as Color).withOpacity(0.15),
                      child: Text((app['company'] as String)[0], style: TextStyle(color: app['color'] as Color, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(app['company'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(app['role'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(app['date'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(app['status'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- Resume Score Card ----------------
  Widget _buildResumeScoreCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ATS Resume Score", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  value: 0.85,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              const Text("85% - Excellent! Add 2 more projects.", style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text("Improve", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primaryDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  // ---------------- Admin Quick Actions ----------------
  Widget _buildAdminQuickActions() {
    final actions = [
      {"title": "Shortlist", "icon": Icons.playlist_add_check_rounded, "color": Colors.blue},
      {"title": "Schedule", "icon": Icons.event_available_outlined, "color": Colors.orange},
      {"title": "Upload Results", "icon": Icons.upload_file_outlined, "color": Colors.green},
      {"title": "Send Notify", "icon": Icons.notifications_active_outlined, "color": Colors.red},
    ];
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${a['title']} (UI Ready)")));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: (a['color'] as Color).withOpacity(0.1), blurRadius: 8)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a['icon'] as IconData, color: a['color'] as Color, size: 24),
                const SizedBox(height: 6),
                Text(a['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- Featured Companies ----------------
  Widget _buildFeatured() {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => _FeaturedCard(data: _featured[i], canManage: _canManage),
      ),
    );
  }

  // ---------------- Internships ----------------
  Widget _buildInternships() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _internships.length,
      itemBuilder: (context, i) => _InternshipCard(data: _internships[i], canManage: _canManage),
    );
  }

  // ---------------- Drives ----------------
  Widget _buildDrives() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _drives.length,
      itemBuilder: (context, i) => _DriveCard(data: _drives[i], canManage: _canManage),
    );
  }

  // ---------------- Placement Stats ----------------
  Widget _buildPlacementStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color.fromARGB(255, 48, 149, 227)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(_canViewAnalytics ? 'Analytics 2024' : 'Placement Insights',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Live',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _placementStats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, i) {
              final s = _placementStats[i];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s['icon'] as IconData, color: Colors.white, size: 22),
                    const SizedBox(height: 6),
                    Text(s['value'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(s['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 9)),
                  ],
                ),
              );
            },
          ),
          if (_canViewAnalytics) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, color: Colors.white, size: 16),
                    label: const Text("Export Report", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  // ---------------- AI Assistant ----------------
  Widget _buildAIAssistant() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🤖', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Career Assistant',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Your personalized AI-powered career guide',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _aiButtons.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
            ),
            itemBuilder: (context, i) {
              final b = _aiButtons[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(b['icon'] as IconData, color: _primaryDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(b['label'] as String,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A237E))),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- Trending ----------------
  Widget _buildTrending() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _trending.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final t = _trending[i];
          return Container(
            width: 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: (t['color'] as Color).withOpacity(0.15),
                      child: Text(
                        (t['name'] as String)[0],
                        style: TextStyle(
                            color: t['color'] as Color,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t['name'] as String,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 16),
                  ],
                ),
                Text(t['role'] as String,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t['hiring'] as String,
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward, color: _primary, size: 16),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- Quick Actions ----------------
  Widget _buildQuickActions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _quickActions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final q = _quickActions[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(q['icon'] as IconData, color: _primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(q['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }

  // ---------------- Bottom Section ----------------
  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _bottomCard(
              'Latest Placement News',
              Icons.article_outlined,
              _news.map((n) => '${n['title']} • ${n['time']}').toList(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                _bottomCard(
                  'Upcoming Drives',
                  Icons.event_available,
                  const ['TCS - 15 Dec', 'Infosys - 20 Dec', 'Wipro - 22 Dec'],
                ),
                const SizedBox(height: 10),
                _bottomCard(
                  'Career Tips',
                  Icons.tips_and_updates_outlined,
                  const [
                    'Update resume monthly',
                    'Practice DSA daily',
                    'Build LinkedIn profile'
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomCard(String title, IconData icon, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: _primaryDark)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e,
                        style: const TextStyle(fontSize: 11, color: Colors.black87)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  REUSABLE WIDGETS
// ============================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final String trend;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.title,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.green.shade700, size: 11),
                    const SizedBox(width: 2),
                    Text(trend,
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
              const SizedBox(height: 2),
              Text(title,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool canManage;
  const _FeaturedCard({required this.data, required this.canManage});

  @override
  Widget build(BuildContext context) {
    final color = data['color'] as Color;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.15),
                child: Text(data['logo'] as String,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w800, fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] as String,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(data['role'] as String,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (val) {},
                )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${data['ctc']}  •  CTC',
                style: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
          const Spacer(),
          _infoRow(Icons.location_on_outlined, data['location'] as String),
          const SizedBox(height: 4),
          _infoRow(Icons.check_circle_outline, data['eligibility'] as String),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(canManage ? 'View Applicants' : 'Apply Now',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _InternshipCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool canManage;
  const _InternshipCard({required this.data, required this.canManage});

  @override
  Widget build(BuildContext context) {
    final color = data['color'] as Color;
    final isRemote = (data['mode'] as String) == 'Remote';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: Text(data['logo'] as String,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['role'] as String,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                Text('${data['name']} • ${data['duration']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(data['stipend'] as String,
                          style: const TextStyle(
                              color: Color(0xFF0D47A1),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRemote
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRemote ? Icons.wifi : Icons.place,
                            size: 10,
                            color: isRemote
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 3),
                          Text(data['mode'] as String,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isRemote 
                                      ? Colors.green.shade700 
                                      : Colors.orange.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(canManage ? 'Manage' : 'Apply', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DriveCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool canManage;
  const _DriveCard({required this.data, required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] as String,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    Text('Drive Date: ${data['date']}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Reg: ${data['deadline']}',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _row(Icons.location_on_outlined, 'Venue: ${data['venue']}'),
                const SizedBox(height: 4),
                _row(Icons.school_outlined, 'Branches: ${data['branches']}'),
              ],
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {}, 
                  icon: const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  label: const Text("Applicants", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("Manage", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1565C0)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 11.5, color: Colors.black87)),
        ),
      ],
    );
  }
}