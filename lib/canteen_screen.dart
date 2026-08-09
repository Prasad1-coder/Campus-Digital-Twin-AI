import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';
import 'permission_model.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  State<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen> {
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
  bool get _isTeacher => _currentUser?.role == UserRole.teacher;
  bool get _isAdmin => _currentUser?.role == UserRole.hod || _currentUser?.role == UserRole.principal;
  bool get _canManage => _authService.hasPermission('canteen', 'canManage');

  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();

  // Dummy Data
  final List<String> _categories = ["All", "Breakfast", "Lunch", "Snacks", "Dinner", "Beverages"];

  final List<Map<String, dynamic>> _menu = [
    {"name": "Vada Pav", "desc": "Mumbai style with chutney", "price": 25, "cat": "Snacks", "rating": 4.8, "color": Colors.orange, "icon": Icons.lunch_dining_outlined, "avail": true},
    {"name": "Masala Dosa", "desc": "Crispy dosa with potato filling", "price": 60, "cat": "Breakfast", "rating": 4.9, "color": Colors.amber, "icon": Icons.dinner_dining_outlined, "avail": true},
    {"name": "Veg Thali", "desc": "4 Rotis, Dal, Sabzi, Rice, Salad", "price": 80, "cat": "Lunch", "rating": 4.7, "color": Colors.green, "icon": Icons.food_bank_outlined, "avail": true},
    {"name": "Paneer Burger", "desc": "With cheese and extra veggies", "price": 50, "cat": "Snacks", "rating": 4.6, "color": Colors.red, "icon": Icons.lunch_dining, "avail": false},
    {"name": "Cold Coffee", "desc": "Thick and creamy", "price": 40, "cat": "Beverages", "rating": 4.9, "color": Colors.brown, "icon": Icons.local_cafe_outlined, "avail": true},
    {"name": "Samosa", "desc": "Hot and crispy", "price": 15, "cat": "Snacks", "rating": 4.5, "color": Colors.deepOrange, "icon": Icons.cookie_outlined, "avail": true},
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
        title: const Text("Smart Canteen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scan to Pay (UPI/QR) ready for future.")));
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
            
            // Manager Dashboard
            if (_canManage) ...[
              _buildManagerDashboard(),
              const SizedBox(height: 24),
            ],
            
            // Admin Analytics (HOD/Principal)
            if (_isAdmin && !_canManage) ...[
              _buildAdminAnalytics(),
              const SizedBox(height: 24),
            ],

            // Student & Teacher View
            if (_isStudent || _isTeacher) ...[
              _buildActiveTokenCard(),
              const SizedBox(height: 24),
            ],

            // Menu List
            _buildMenuSection(),
            const SizedBox(height: 24),
            
            // Order History
            _buildOrderHistory(),
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
          hintText: "Search for food items...",
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

  Widget _buildManagerDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Canteen Manager", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _statCard("Today's Sales", "₹4,250", Icons.payments_outlined, Colors.green),
            _statCard("Pending Orders", "12", Icons.pending_actions, Colors.orange),
            _statCard("Tokens Served", "85", Icons.verified_outlined, Colors.blue),
            _statCard("Low Stock", "2 Items", Icons.warning_amber_rounded, Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _managerAction(Icons.add_circle_outline, "Add Item"),
            _managerAction(Icons.inventory_2_outlined, "Inventory"),
            _managerAction(Icons.kitchen_outlined, "Kitchen"),
          ],
        )
      ],
    );
  }

  Widget _managerAction(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label ready for backend.")));
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _softBlue, shape: BoxShape.circle),
            child: Icon(icon, color: _primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDark)),
        ],
      ),
    );
  }

  Widget _buildAdminAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Canteen Analytics", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _statCard("Monthly Revenue", "₹1.2L", Icons.trending_up, Colors.green),
            _statCard("Peak Hour", "12:30 PM", Icons.access_time, Colors.orange),
            _statCard("Popular Food", "Vada Pav", Icons.star, Colors.amber),
            _statCard("Daily Orders", "320", Icons.receipt_long, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActiveTokenCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primaryDark, _primary]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Active Token", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              if (_isTeacher)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                  child: const Text("PRIORITY", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Token No.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("#A42", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Ready in", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("8 Min", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text("Pay Now", style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.notifications_active_outlined, color: Colors.white)
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Menu", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _menu.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final food = _menu[index];
            return _foodCard(food);
          },
        ),
      ],
    );
  }

  Widget _foodCard(Map<String, dynamic> food) {
    bool isAvail = food["avail"] as bool;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: (food["color"] as Color).withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Center(
                    child: Icon(food["icon"] as IconData, size: 40, color: food["color"] as Color),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAvail ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isAvail ? "Available" : "Sold Out", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food["name"], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text("${food["rating"]}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("₹${food["price"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _primary)),
                    Container(
                      decoration: BoxDecoration(
                        color: _canManage ? Colors.grey.shade100 : _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (_canManage) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit Item (Manager)")));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${food["name"]} added to cart")));
                          }
                        },
                        icon: Icon(_canManage ? Icons.edit : Icons.add, size: 16, color: _canManage ? Colors.grey : Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrderHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Order History", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 16),
        ...List.generate(2, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_long_outlined, color: _primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order #${1024 + index}", style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark)),
                      Text("Vada Pav, Coffee", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("₹65", style: const TextStyle(fontWeight: FontWeight.w800, color: _primary)),
                    Text(index == 0 ? "Ready" : "Served", style: TextStyle(fontSize: 11, color: index == 0 ? Colors.orange : Colors.green, fontWeight: FontWeight.w700)),
                  ],
                )
              ],
            ),
          );
        })
      ],
    );
  }
}