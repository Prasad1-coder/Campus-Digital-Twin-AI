import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'services/auth_service.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 👇 FIX: Wrapped in try-catch to catch exact Firebase error
  try {
    await Firebase.initializeApp();
    print("✅ Firebase Initialized Successfully!");
  } catch (e) {
    print("❌ Firebase Initialization Error: $e");
  }
  
  await ThemeController.instance.init();
  runApp(const CampusApp());
}

class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.theme,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Campus Digital Twin AI',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: mode,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('mr'),
          ],
          home: const SplashScreen(),
        );
      },
    );
  }

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
        color: Colors.white,
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

  ThemeData _buildDarkTheme() {
    const Color primaryColor = Color(0xFF42A5F5);
    const Color scaffoldBgColor = Color(0xFF121212);

    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: scaffoldBgColor,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.5),
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

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

  void _checkAuthStatus() async {
    if (!mounted) return;

    try {
      // 1. Try to Restore Login Session
      await _authService.tryRestoreSession();

      // 2. Route based on login status
      if (_authService.isLoggedIn && _authService.getCurrentRole() != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userRole: _authService.getCurrentRole()!,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print("❌ Auth Restore Error: $e");
      // Agar session restore mein error aaye toh direct login page bhej do
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
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