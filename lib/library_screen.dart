import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';

// ---------- Same colour palette (unchanged) ----------
const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _accent = Color(0xFF42A5F5);
const Color _lightBg = Color(0xFFF5F9FF);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

// Helpers so light + dark mode both look good
Color _tintOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _primary.withOpacity(0.20) : _softBlue;

Color _iconOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _accent : _primary;

Color _headingOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : _textDark;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // =====================================================================
  // 1. DATA & LOGIC
  // =====================================================================
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  bool get _canManage => _authService.hasPermission('library', 'canManage');

  bool _showAll = false; // "See all" toggles shelf <-> grid

  // Master list of books
  final List<Map<String, dynamic>> _allPopularBooks = [
    {"title": "Clean Code", "author": "Robert C. Martin", "color": Colors.blue, "available": true, "type": "Physical"},
    {"title": "The Pragmatic Programmer", "author": "Andrew Hunt", "color": Colors.purple, "available": true, "type": "Physical"},
    {"title": "Design Patterns", "author": "Erich Gamma", "color": Colors.orange, "available": false, "type": "Digital"},
    {"title": "Artificial Intelligence", "author": "Stuart Russell", "color": Colors.red, "available": true, "type": "Physical"},
  ];

  // Made issued books mutable (not final)
  final List<Map<String, dynamic>> _issuedBooks = [
    {"title": "Introduction to Algorithms", "author": "Thomas H. Cormen", "due": "12 Dec 2024", "fine": 0, "color": Colors.green},
    {"title": "Database System Concepts", "author": "Silberschatz", "due": "05 Dec 2024", "fine": 20, "color": Colors.indigo},
  ];

  // Search result (recalculated on every build from the search box text)
  List<Map<String, dynamic>> get _filteredBooks {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allPopularBooks;
    return _allPopularBooks.where((book) {
      return (book["title"] as String).toLowerCase().contains(query) ||
          (book["author"] as String).toLowerCase().contains(query);
    }).toList();
  }

  // Numbers for the header
  int get _overdueCount => _issuedBooks.where((b) => (b["fine"] as int) > 0).length;
  int get _totalFine => _issuedBooks.fold<int>(0, (sum, b) => sum + (b["fine"] as int));

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}";
  }

  // Renew: due date moves 14 days ahead from today, fine is cleared
  void _renewBook(int index) {
    final String newDue = _formatDate(DateTime.now().add(const Duration(days: 14)));
    setState(() {
      _issuedBooks[index]["due"] = newDue;
      _issuedBooks[index]["fine"] = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${_issuedBooks[index]["title"]} Renewed! New Due Date: $newDue"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Return: book is removed from the issued list
  void _returnBook(int index) {
    String bookTitle = _issuedBooks[index]["title"];
    setState(() {
      _issuedBooks.removeAt(index);
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =====================================================================
  // 2. BUILD (screen skeleton)
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : _lightBg,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + search bar floating over its bottom edge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeader(),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: -28,
                    child: _buildSearchBar(),
                  ),
                ],
              ),
              const SizedBox(height: 54),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_canManage) ...[
                      _buildLibraryStaffActions(),
                      const SizedBox(height: 26),
                    ],
                    _buildIssuedSection(),
                    const SizedBox(height: 26),
                    _buildPopularSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // 3. HEADER + SEARCH
  // =====================================================================
  Widget _buildHeader() {
    final bool canGoBack = Navigator.of(context).canPop();
    final int issued = _issuedBooks.length;
    final int overdue = _overdueCount;

    String subtitle;
    if (overdue > 0) {
      subtitle = "$overdue overdue • ₹$_totalFine fine";
    } else if (issued == 0) {
      subtitle = "Browse the popular shelf below";
    } else {
      subtitle = "All books are on time";
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HeaderGridPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (canGoBack) ...[
                        _headerButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: "Back",
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Expanded(
                        child: Text(
                          "Smart Library",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ),
                      _headerButton(
                        icon: Icons.qr_code_scanner_rounded,
                        tooltip: "Scan book",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("QR/Barcode Scanner ready.")),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    issued == 1 ? "1 book issued" : "$issued books issued",
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        overdue > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: overdue > 0 ? Colors.amberAccent : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}), // real-time search
        style: TextStyle(fontSize: 14.5, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: "Search by title or author...",
          hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: _iconOf(theme)),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: "Clear",
                  icon: Icon(Icons.close_rounded, color: theme.hintColor, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // =====================================================================
  // 4. STAFF QUICK ACTIONS (only if canManage)
  // =====================================================================
  Widget _buildLibraryStaffActions() {
    final theme = Theme.of(context);
    final actions = [
      {"title": "Issue Book", "icon": Icons.bookmark_add_outlined, "color": Colors.green},
      {"title": "Return Book", "icon": Icons.bookmark_remove_outlined, "color": Colors.orange},
      {"title": "Add Book", "icon": Icons.post_add_outlined, "color": Colors.blue},
      {"title": "Manage", "icon": Icons.manage_accounts_outlined, "color": Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Quick Actions"),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) {
            final a = actions[index];
            final Color c = a["color"] as Color;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${a["title"]} action ready.")),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: c.withOpacity(0.18)),
                      ),
                      child: Icon(a["icon"] as IconData, color: c, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        a["title"] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // =====================================================================
  // 5. MY ISSUED BOOKS
  // =====================================================================
  Widget _buildIssuedSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle("My Issued Books"),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(10)),
              child: Text(
                "${_issuedBooks.length}",
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _iconOf(theme)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_issuedBooks.isEmpty)
          _emptyNote(Icons.check_circle_outline_rounded, "No books currently issued.")
        else
          ..._issuedBooks.asMap().entries.map((entry) {
            return _buildIssuedBookCard(entry.value, entry.key); // index targets the specific book
          }),
      ],
    );
  }

  Widget _buildIssuedBookCard(Map<String, dynamic> b, int index) {
    final theme = Theme.of(context);
    final bool isOverdue = (b["fine"] as int) > 0;
    final Color base = b["color"] as Color;
    final Color dueColor = isOverdue ? Colors.red : theme.hintColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? Colors.red.withOpacity(0.35) : theme.dividerColor.withOpacity(0.6),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini book cover
              Container(
                width: 52,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [base, base.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Positioned(left: 7, top: 0, bottom: 0, child: Container(width: 2, color: Colors.white.withOpacity(0.25))),
                    const Center(child: Icon(Icons.book_rounded, color: Colors.white, size: 22)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b["title"] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w800, color: _headingOf(theme)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      b["author"] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    const SizedBox(height: 10),
                    // Wrap = never overflows on small phones
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red.withOpacity(0.10) : theme.hintColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy_rounded, size: 13, color: dueColor),
                              const SizedBox(width: 4),
                              Text(
                                "Due: ${b["due"]}",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dueColor),
                              ),
                            ],
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              "Fine: ₹${b["fine"]}",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red.shade700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _returnBook(index),
                  icon: const Icon(Icons.keyboard_return_rounded, size: 16),
                  label: const Text("Return", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _renewBook(index),
                  icon: const Icon(Icons.autorenew_rounded, size: 16),
                  label: const Text("Renew", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // 6. POPULAR BOOKS (shelf or grid)
  // =====================================================================
  Widget _buildPopularSection() {
    final theme = Theme.of(context);
    final books = _filteredBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle("Popular Books")),
            if (books.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _showAll = !_showAll),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                  decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAll ? "Show less" : "See all",
                        style: TextStyle(color: _iconOf(theme), fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _showAll ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
                        size: 16,
                        color: _iconOf(theme),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (books.isEmpty)
          _emptyNote(Icons.search_off_rounded, "No books match your search.")
        else if (_showAll)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: books.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              mainAxisExtent: 240,
            ),
            itemBuilder: (context, index) => _buildPopularBookCard(books[index]),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return SizedBox(width: 140, child: _buildPopularBookCard(books[index]));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPopularBookCard(Map<String, dynamic> b) {
    final theme = Theme.of(context);
    final bool isAvailable = b["available"] as bool;
    final bool isDigital = b["type"] == "Digital";
    final Color base = b["color"] as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 176,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [base, base.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: base.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Stack(
            children: [
              // book spine line
              Positioned(left: 10, top: 0, bottom: 0, child: Container(width: 2, color: Colors.white.withOpacity(0.25))),
              Center(
                child: Icon(
                  isDigital ? Icons.menu_book_rounded : Icons.book_rounded,
                  size: 42,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              // availability
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? "Available" : "Issued",
                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              // type (Physical / Digital)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    b["type"] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          b["title"] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _headingOf(theme)),
        ),
        const SizedBox(height: 2),
        Text(
          b["author"] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, color: theme.hintColor),
        ),
      ],
    );
  }

  // =====================================================================
  // 7. SHARED SMALL WIDGETS
  // =====================================================================
  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _headingOf(theme)),
    );
  }

  Widget _emptyNote(IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.hintColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, height: 1.35, color: theme.hintColor)),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Header background: blueprint grid + rings (same look as other screens)
// =====================================================================
class _HeaderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final ring = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width - 30, size.height - 40);
    for (final r in [36.0, 64.0, 92.0]) {
      canvas.drawCircle(center, r, ring);
    }

    final dot = Paint()..color = Colors.white.withOpacity(0.45);
    canvas.drawCircle(Offset(center.dx - 36, center.dy), 3, dot);
    canvas.drawCircle(Offset(center.dx, center.dy - 64), 3, dot);
    canvas.drawCircle(Offset(center.dx - 92, center.dy), 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}