import 'package:flutter/material.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String selectedFilter = "All";

  final List<Map<String, String>> books = const [
    {
      "title": "Data Structures",
      "author": "Mark Allen Weiss",
      "status": "Available",
      "rack": "A-12",
      "subject": "Computer",
    },
    {
      "title": "Python Programming",
      "author": "Guido van Rossum",
      "status": "Issued",
      "rack": "B-08",
      "subject": "Computer",
    },
    {
      "title": "Operating System",
      "author": "Silberschatz Galvin",
      "status": "Available",
      "rack": "C-15",
      "subject": "Computer ",
    },
    {
      "title": "Database Management",
      "author": "Korth",
      "status": "Available",
      "rack": "D-05",
      "subject": "Computer",
    },
    {
      "title": "Organic Chemistry",
      "author": "Morrison Boyd",
      "status": "Issued",
      "rack": "E-02",
      "subject": "Chemistry",
    },
    {
      "title": "Engineering Math",
      "author": "B.S.Grewal",
      "status": "Available",
      "rack": "F-09",
      "subject": "Math",
    },
  ];

  List<Map<String, String>> get _filteredBooks {
    return books.where((book) {
      final matchesSearch = book["title"]!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          book["author"]!.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFilter = selectedFilter == "All" || book["status"] == selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _availableCount => books.where((b) => b["status"] == "Available").length;
  int get _issuedCount => books.where((b) => b["status"] == "Issued").length;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Smart Library", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 👇 Gradient header with stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        icon: Icons.menu_book_outlined,
                        label: "Total Books",
                        value: "${books.length}",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.check_circle_outline,
                        label: "Available",
                        value: "$_availableCount",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.access_time_outlined,
                        label: "Issued",
                        value: "$_issuedCount",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 👇 Search bar - overlapping header, card design
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6)),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search by title or author...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                            onPressed: () {
                              searchController.clear();
                              setState(() => searchQuery = "");
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // 👇 Filter chips
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 6),
            child: Row(
              children: [
                _FilterChip(
                  label: "All",
                  isSelected: selectedFilter == "All",
                  onTap: () => setState(() => selectedFilter = "All"),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: "Available",
                  isSelected: selectedFilter == "Available",
                  onTap: () => setState(() => selectedFilter = "Available"),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: "Issued",
                  isSelected: selectedFilter == "Issued",
                  onTap: () => setState(() => selectedFilter = "Issued"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 👇 Book list
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(query: searchQuery)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final book = filtered[index];
                      final isAvailable = book["status"] == "Available";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.menu_book_outlined, color: Colors.blue, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book["title"]!,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    book["author"]!,
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.shelves, size: 13, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Rack ${book["rack"]}",
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          book["subject"]!,
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isAvailable ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAvailable ? Icons.check_circle : Icons.schedule,
                                    size: 12,
                                    color: isAvailable ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    book["status"]!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isAvailable ? Colors.green.shade700 : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            query.isEmpty ? "No books in this category" : "No books found for \"$query\"",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}