import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'permission_model.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final AuthService _authService = AuthService();
  
  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  
  bool get _isStudent => _currentUser?.role == UserRole.student;
  bool get _isAdmin => _currentUser?.role == UserRole.hod || _currentUser?.role == UserRole.principal;
  bool get _canManage => _authService.hasPermission('library', 'canManage');

  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();

  // Dummy Data
  final List<String> _categories = ["All", "Computer Science", "Fiction", "History", "Science", "Business"];

  final List<Map<String, dynamic>> _popularBooks = [
    {"title": "Clean Code", "author": "Robert C. Martin", "color": Colors.blue, "available": true, "rating": 4.8, "type": "Physical"},
    {"title": "The Pragmatic Programmer", "author": "Andrew Hunt", "color": Colors.purple, "available": true, "rating": 4.7, "type": "Physical"},
    {"title": "Design Patterns", "author": "Erich Gamma", "color": Colors.orange, "available": false, "rating": 4.6, "type": "Digital"},
    {"title": "Artificial Intelligence", "author": "Stuart Russell", "color": Colors.red, "available": true, "rating": 4.9, "type": "Physical"},
  ];

  final List<Map<String, dynamic>> _issuedBooks = [
    {"title": "Introduction to Algorithms", "author": "Thomas H. Cormen", "due": "12 Dec 2024", "fine": 0, "color": Colors.green},
    {"title": "Database System Concepts", "author": "Silberschatz", "due": "05 Dec 2024", "fine": 20, "color": Colors.indigo},
  ];

  final List<Map<String, dynamic>> _deptStats = [
    {"title": "Total Books", "value": "12,450", "icon": Icons.library_books_outlined},
    {"title": "Issued", "value": "3,210", "icon": Icons.bookmark_outlined},
    {"title": "Overdue", "value": "45", "icon": Icons.warning_amber_rounded},
    {"title": "Fines Collected", "value": "₹4,500", "icon": Icons.account_balance_wallet_outlined},
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
        title: const Text("Smart Library", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR/Barcode Scanner ready for future implementation.")));
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildCategoryChips(),
            const SizedBox(height: 24),
            if (_canManage || _isAdmin) ...[
              _buildStatsGrid(),
              const SizedBox(height: 24),
            ],
            if (_canManage) ...[
              _buildLibraryStaffActions(),
              const SizedBox(height: 24),
            ],
            if (!_canManage) ...[
              _buildIssuedBooksSection(),
              const SizedBox(height: 24),
            ],
            _buildPopularBooksSection(),
            const SizedBox(height: 24),
            if (!_isStudent) _buildRecommendedSection(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  WIDGETS
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by title, author, or ISBN...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.grey),
            onPressed: () {},
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [_primaryDark, _primary]) : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isAdmin ? "Library Analytics" : "Department Statistics", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: _deptStats.map((s) => _statCard(s)).toList(),
        ),
      ],
    );
  }

  Widget _statCard(Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(s["icon"] as IconData, color: _primary, size: 22),
          Text(s["value"] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark)),
          Text(s["title"] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLibraryStaffActions() {
    final actions = [
      {"title": "Issue Book", "icon": Icons.bookmark_add_outlined, "color": Colors.green},
      {"title": "Return Book", "icon": Icons.bookmark_remove_outlined, "color": Colors.orange},
      {"title": "Add Book", "icon": Icons.post_add_outlined, "color": Colors.blue},
      {"title": "Manage", "icon": Icons.manage_accounts_outlined, "color": Colors.purple},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
          children: actions.map((a) {
            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${a["title"]} action ready.")));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: (a["color"] as Color).withOpacity(0.1), blurRadius: 8)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: (a["color"] as Color).withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(a["icon"] as IconData, color: a["color"] as Color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(a["title"] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIssuedBooksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("My Issued Books", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        ..._issuedBooks.map((b) => _issuedBookCard(b)).toList(),
      ],
    );
  }

  Widget _issuedBookCard(Map<String, dynamic> b) {
    bool isOverdue = (b["fine"] as int) > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isOverdue ? Colors.red.shade100 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [b["color"] as Color, (b["color"] as Color).withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.book, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b["title"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(b["author"], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 14, color: isOverdue ? Colors.red : Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text("Due: ${b["due"]}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isOverdue ? Colors.red : Colors.grey.shade700)),
                    if (isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text("Fine: ₹${b["fine"]}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.red.shade700)),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Renew", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Return", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPopularBooksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Popular Books", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
            TextButton(onPressed: () {}, child: const Text("See All", style: TextStyle(color: _primary, fontWeight: FontWeight.w700))),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _popularBooks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final b = _popularBooks[index];
              return _popularBookCard(b);
            },
          ),
        ),
      ],
    );
  }

  Widget _popularBookCard(Map<String, dynamic> b) {
    bool isAvailable = b["available"] as bool;
    bool isDigital = b["type"] == "Digital";
    
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [b["color"] as Color, (b["color"] as Color).withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: (b["color"] as Color).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Icon(isDigital ? Icons.menu_book_rounded : Icons.book, size: 40, color: Colors.white.withOpacity(0.8)),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isAvailable ? "Available" : "Issued", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ),
              if (isDigital)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("E-Book", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(b["title"], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(b["author"], style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AI Recommended", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Based on your search history", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text("You might like 'Deep Learning' by Ian Goodfellow", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white), onPressed: () {})
            ],
          ),
        ),
      ],
    );
  }
}