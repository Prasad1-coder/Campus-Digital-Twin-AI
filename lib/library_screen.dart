import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _canManage => _authService.hasPermission('library', 'canManage');

  // Master list of books
  final List<Map<String, dynamic>> _allPopularBooks = [
    {"title": "Clean Code", "author": "Robert C. Martin", "color": Colors.blue, "available": true, "type": "Physical"},
    {"title": "The Pragmatic Programmer", "author": "Andrew Hunt", "color": Colors.purple, "available": true, "type": "Physical"},
    {"title": "Design Patterns", "author": "Erich Gamma", "color": Colors.orange, "available": false, "type": "Digital"},
    {"title": "Artificial Intelligence", "author": "Stuart Russell", "color": Colors.red, "available": true, "type": "Physical"},
  ];

  // Filtered list for UI
  List<Map<String, dynamic>> _filteredBooks = [];

  // Made issued books mutable (not final)
  final List<Map<String, dynamic>> _issuedBooks = [
    {"title": "Introduction to Algorithms", "author": "Thomas H. Cormen", "due": "12 Dec 2024", "fine": 0, "color": Colors.green},
    {"title": "Database System Concepts", "author": "Silberschatz", "due": "05 Dec 2024", "fine": 20, "color": Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _filteredBooks = _allPopularBooks;
  }

  // Actual Search Logic
  void _filterBooks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBooks = _allPopularBooks;
      } else {
        _filteredBooks = _allPopularBooks.where((book) {
          return (book["title"] as String).toLowerCase().contains(query.toLowerCase()) ||
                 (book["author"] as String).toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Actual Renew Logic
  void _renewBook(int index) {
    setState(() {
      _issuedBooks[index]["due"] = "15 Jan 2025"; // Extended due date
      _issuedBooks[index]["fine"] = 0; // Reset fine
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${_issuedBooks[index]["title"]} Renewed! New Due Date: 15 Jan 2025"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Actual Return Logic
  void _returnBook(int index) {
    String bookTitle = _issuedBooks[index]["title"];
    setState(() {
      _issuedBooks.removeAt(index); // Remove book from list
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$bookTitle Returned Successfully! 📚"),
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
        title: const Text("Smart Library", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR/Barcode Scanner ready.")));
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar now calls _filterBooks
            _buildSearchBar(),
            const SizedBox(height: 20),
            
            if (_canManage) ...[
              _buildLibraryStaffActions(),
              const SizedBox(height: 24),
            ],
            
            // My Issued Books Section
            const Text("My Issued Books", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 16),
            
            // 👇 FIX: Replaced ternary with if-else collection element
            if (_issuedBooks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No books currently issued."),
                )
              )
            else
              ..._issuedBooks.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> b = entry.value;
                return _buildIssuedBookCard(b, index); // Pass index to update specific book
              }),

            const SizedBox(height: 24),

            // Popular Books Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Popular Books", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
                TextButton(onPressed: () {}, child: const Text("See All", style: TextStyle(color: _primary, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredBooks.length, // Using filtered list
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final b = _filteredBooks[index];
                  return _buildPopularBookCard(b);
                },
              ),
            ),
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
        onChanged: _filterBooks, // Real-time search
        decoration: InputDecoration(
          hintText: "Search by title, author, or ISBN...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
          border: InputBorder.none,
        ),
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
        const Text("Quick Actions", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
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
                    Flexible(
                      child: Text(
                        a["title"] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Added index parameter to target the specific book
  Widget _buildIssuedBookCard(Map<String, dynamic> b, int index) {
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
                Text(b["title"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(b["author"], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 14, color: isOverdue ? Colors.red : Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text("Due: ${b["due"]}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red : Colors.grey.shade700)),
                    if (isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text("Fine: ₹${b["fine"]}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
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
                // Calls _renewBook with index
                onPressed: () => _renewBook(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Renew", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                // Calls _returnBook with index
                onPressed: () => _returnBook(index),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Return", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPopularBookCard(Map<String, dynamic> b) {
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
                height: 180,
                width: 130,
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
                  child: Text(isAvailable ? "Available" : "Issued", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(b["title"], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(b["author"], style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}