import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  State<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen> {
  final AuthService _authService = AuthService();

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  bool get _isStudent => _currentUser?.role == UserRole.student;

  // Dummy Active Token
  int _activeToken = 42;
  int _eta = 8;
  bool _isPaid = false;

  // Dummy Menu
  final List<Map<String, dynamic>> _menu = [
    {"name": "Vada Pav", "desc": "Mumbai style with chutney", "price": 25, "cat": "Snacks", "icon": Icons.lunch_dining_outlined, "color": Colors.orange},
    {"name": "Masala Dosa", "desc": "Crispy dosa with potato filling", "price": 60, "cat": "Breakfast", "icon": Icons.dinner_dining_outlined, "color": Colors.amber},
    {"name": "Veg Thali", "desc": "4 Rotis, Dal, Sabzi, Rice, Salad", "price": 80, "cat": "Lunch", "icon": Icons.food_bank_outlined, "color": Colors.green},
    {"name": "Cold Coffee", "desc": "Thick and creamy", "price": 40, "cat": "Beverages", "icon": Icons.local_cafe_outlined, "color": Colors.brown},
  ];

  void _placeOrder(Map<String, dynamic> item) {
    setState(() {
      _activeToken++; // New token generated
      _eta = 10; // Reset ETA
      _isPaid = false; // New order needs payment
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ ${item["name"]} ordered! Token No: $_activeToken"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _payNow() {
    setState(() {
      _isPaid = true;
      _eta = 5; // ETA reduces after payment
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("💰 Payment Successful! Order Confirmed."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: const Text("Smart Canteen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isStudent ? _buildStudentView() : _buildAdminView(),
      ),
    );
  }

  // ============================================================
  //  STUDENT VIEW
  // ============================================================
  Widget _buildStudentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active Token Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Active Token", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isPaid ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_isPaid ? "Paid" : "Payment Due", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
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
                      Text("#A$_activeToken", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Ready in", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("$_eta Min", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              // 👇 FIX: Pay Now Button Working
              if (!_isPaid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _payNow,
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text("Pay Now (₹120)", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Menu Section
        const Text("Today's Menu", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
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
            return _buildFoodCard(food);
          },
        ),
      ],
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
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
            child: Container(
              decoration: BoxDecoration(
                color: (food["color"] as Color).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Icon(food["icon"] as IconData, size: 40, color: food["color"] as Color),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food["name"], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("₹${food["price"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
                    // 👇 FIX: Order Button Working
                    GestureDetector(
                      onTap: () => _placeOrder(food),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ============================================================
  //  ADMIN VIEW (Canteen Manager)
  // ============================================================
  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard("Today's Sales", "₹4,250", Icons.payments_outlined, Colors.green),
            _buildStatCard("Pending Orders", "12", Icons.pending_actions, Colors.orange),
            _buildStatCard("Tokens Served", "85", Icons.verified_outlined, Colors.blue),
            _buildStatCard("Low Stock", "2 Items", Icons.warning_amber_rounded, Colors.red),
          ],
        ),
        const SizedBox(height: 24),
        // Can add order management list here in future
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 22),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
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
}