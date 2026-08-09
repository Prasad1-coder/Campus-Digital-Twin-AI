import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'services/auth_service.dart';

// ============================================================
//  Campus Digital Twin AI - Main Entry Point
//  Architecture: Clean Architecture & Scalable RBAC Ready
// ============================================================

void main() {
  // Ensure Flutter bindings are initialized before making any native calls
  // (e.g., SecureStorage, SharedPreferences, Firebase).
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTE: Dependency Injection (e.g., GetIt, Provider) can be initialized here
  // before runApp() is called in the future.
  
  runApp(const CampusApp());
}

class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Digital Twin AI',
      
      // ----------------- THEME ARCHITECTURE -----------------
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(), // Ready for future implementation
      themeMode: ThemeMode.light,   // Default to Light Mode

      // ----------------- LOCALIZATION ARCHITECTURE -----------------
      // Ready for future multilingual support (English, Hindi, Marathi)
      supportedLocales: const [
        Locale('en'), // Default
        Locale('hi'), // Hindi (Future)
        Locale('mr'), // Marathi (Future)
      ],
      // Note: Add flutter_localizations package in pubspec.yaml later to use delegates
      
      // ----------------- NAVIGATION & ROUTES -----------------
      home: const SplashScreen(), // Initial Screen
    );
  }

  // ----------------- LIGHT THEME CONFIGURATION -----------------
  ThemeData _buildLightTheme() {
    const Color primaryColor = Color(0xFF1565C0);
    const Color scaffoldBgColor = Color(0xFFF5F9FF);

    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: scaffoldBgColor,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ----------------- DARK THEME ARCHITECTURE (For Future) -----------------
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
        brightness: Brightness.dark,
      ),
      // Add dark specific configurations here later
    );
  }
}

// ============================================================
//  SPLASH SCREEN (Initial Loader & Auth State Check)
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward().then((_) => _checkAuthStatus());
  }

  /// Checks if the user is already authenticated and routes accordingly.
  /// 
  /// In a production environment with SecureStorage or Firebase, this method
  /// would asynchronously attempt to restore the session (e.g., read JWT token).
  void _checkAuthStatus() {
    if (!mounted) return;
    
    // Simulate async session restoration for future readiness
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      if (_authService.isLoggedIn && _authService.getCurrentRole() != null) {
        // User is logged in, navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userRole: _authService.getCurrentRole()!,
            ),
          ),
        );
      } else {
        // User is not logged in, navigate to Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: ScaleTransition(
          scale: _controller,
          child: const Icon(
            Icons.school_rounded,
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}