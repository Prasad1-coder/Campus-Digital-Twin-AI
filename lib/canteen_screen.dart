import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_role.dart';

const _primary = Color(0xFF1565C0);
const _primaryDark = Color(0xFF0D47A1);
const _textDark = Color(0xFF1A237E);

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  State<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen> {
  final _auth = AuthService();
  bool get _isStudent => _auth.getCurrentUser()?.role == UserRole.student;

  int _token = 42, _eta = 8;
  bool _isPaid = false;

  // (name, price, icon, color) -- Dart 3 records
  static const _menu = [
    ("Vada Pav", 25, Icons.lunch_dining_outlined, Colors.orange),
    ("Masala Dosa", 60, Icons.dinner_dining_outlined, Colors.amber),
    ("Veg Thali", 80, Icons.food_bank_outlined, Colors.green),
    ("Cold Coffee", 40, Icons.local_cafe_outlined, Colors.brown),
  ];

  static const _stats = [
    ("Today's Sales", "₹4,250", Icons.payments_outlined, Colors.green),
    ("Pending Orders", "12", Icons.pending_actions, Colors.orange),
    ("Tokens Served", "85", Icons.verified_outlined, Colors.blue),
    ("Low Stock", "2 Items", Icons.warning_amber_rounded, Colors.red),
  ];

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  void _placeOrder(String name) {
    setState(() {
      _token++;
      _eta = 10;
      _isPaid = false;
    });
    _snack("✅ $name ordered! Token No: $_token");
  }

  void _payNow() {
    setState(() {
      _isPaid = true;
      _eta = 5;
    });
    _snack("💰 Payment Successful! Order Confirmed.");
  }

  LinearGradient _grad(Color a, Color b) =>
      LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight);

  BoxShadow _shadow(Color c, double o, double blur) =>
      BoxShadow(color: c.withOpacity(o), blurRadius: blur, offset: Offset(0, blur / 2));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: _grad(_primaryDark, _primary),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
          title: const Text("Smart Canteen",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _isStudent ? _studentView() : _adminView(),
        ),
      );

  // ---------------- STUDENT ----------------
  Widget _studentView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tokenCard(),
          const SizedBox(height: 24),
          const Text("Today's Menu",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: _menu.map(_foodCard).toList(),
          ),
        ],
      );

  Widget _tokenCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _grad(_primary, _primaryDark),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [_shadow(_primary, 0.35, 16)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Active Token",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isPaid ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_isPaid ? "Paid" : "Payment Due",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _info("Token No.", "#A$_token", 32, CrossAxisAlignment.start),
                _info("Ready in", "$_eta Min", 24, CrossAxisAlignment.end),
              ],
            ),
            if (!_isPaid) ...[
              const SizedBox(height: 16),
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
          ],
        ),
      );

  Widget _info(String label, String value, double size, CrossAxisAlignment align) => Column(
        crossAxisAlignment: align,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: TextStyle(color: Colors.white, fontSize: size, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _foodCard((String, int, IconData, Color) f) {
    final (name, price, icon, color) = f;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_shadow(Colors.black, 0.04, 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(child: Icon(icon, size: 40, color: color)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("₹$price",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
                    GestureDetector(
                      onTap: () => _placeOrder(name),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- ADMIN ----------------
  Widget _adminView() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: _stats.map(_statCard).toList(),
      );

  Widget _statCard((String, String, IconData, Color) s) {
    final (title, value, icon, color) = s;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [_shadow(color, 0.1, 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
          Text(title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}