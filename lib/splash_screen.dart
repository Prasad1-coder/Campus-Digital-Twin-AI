import 'package:flutter/material.dart';

/// ============================================================
///  Splash Screen
///  Campus Digital Twin AI
/// ============================================================
/// 
/// A premium, animated Splash Screen serving as the application's
/// future entry point. It is completely independent of the existing
/// codebase and does not trigger any navigation yet.
/// 
/// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late final AnimationController _masterController;
  
  // Animations
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<double> _loadingFadeAnimation;
  late final Animation<double> _versionFadeAnimation;

  // Theme Colors
  static const Color _primaryColor = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _accentColor = Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();

    // Master Controller for the overall sequence
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 1. Logo Scale Animation (0.0s to 1.0s)
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    // 2. Text Fade Animation (0.4s to 1.2s)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // 3. Loading Indicator Fade (0.8s to 1.2s)
    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    // 4. Version Number Fade (1.2s to 1.6s)
    _versionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.9, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start the animation sequence
    _masterController.forward();

    // Initialize future app requirements
    _initializeAppRequirements();
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  /// ============================================================
  /// FUTURE-READY ARCHITECTURE PLACEHOLDERS
  /// ============================================================
  /// 
  /// This method is structured to handle future startup checks
  /// without blocking the UI. Currently, it's empty.
  Future<void> _initializeAppRequirements() async {
    // TODO: Implement these checks when backend is ready:
    //
    // 1. Internet Connectivity Check
    //    bool hasInternet = await _checkInternetConnection();
    //
    // 2. Server Status Check
    //    bool isServerOnline = await _checkServerStatus();
    //
    // 3. App Update Check
    //    bool needsUpdate = await _checkForAppUpdates();
    //
    // 4. Session Check / Auto Login
    //    UserSession? session = await _checkUserSession();
    //
    // 5. Role Detection & Routing
    //    if (session != null) {
    //      _navigateToDashboard(session.role);
    //    } else {
    //      _navigateToLogin();
    //    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Premium Blue Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryDark,
              _primaryColor,
              _accentColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Top Spacer / College Logo
                _buildCollegeHeader(),

                // Main Logo & App Name
                _buildMainLogoSection(),

                // Bottom Loading & Version
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Reusable Widgets ----------------

  /// Top section representing the college branding.
  Widget _buildCollegeHeader() {
    return FadeTransition(
      opacity: _textFadeAnimation,
      child: Column(
        children: [
          // College Logo Placeholder
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'XYZ Group of Institutions',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Center section containing the main App Logo and Name.
  Widget _buildMainLogoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Logo with Scale Animation
        ScaleTransition(
          scale: _logoScaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 64,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // App Name with Fade Animation
        FadeTransition(
          opacity: _textFadeAnimation,
          child: const Text(
            'Campus Digital Twin AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Tagline with Fade Animation
        FadeTransition(
          opacity: _textFadeAnimation,
          child: Text(
            'AI Powered Smart College ERP System',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom section containing the loading indicator and version number.
  Widget _buildBottomSection() {
    return Column(
      children: [
        // Loading Animation
        FadeTransition(
          opacity: _loadingFadeAnimation,
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Version Number
        FadeTransition(
          opacity: _versionFadeAnimation,
          child: Text(
            'Version 1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}