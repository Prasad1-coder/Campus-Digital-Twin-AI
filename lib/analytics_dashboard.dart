import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AuthService _authService = AuthService();

  static const Color _primary = Color(0xFF1565C0);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        title: const Text("Analytics Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_rounded, size: 80, color: _primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text("Analytics Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 8),
            Text("Role: ${_currentUser?.role.name.toUpperCase() ?? 'GUEST'}", style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}