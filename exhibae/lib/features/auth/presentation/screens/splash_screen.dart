import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final SupabaseService _supabaseService = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Check authentication and navigate accordingly
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Check if user is already authenticated
      final user = _supabaseService.currentUser;
      final hasSession = await _supabaseService.hasStoredSession();
      
      if (user != null && hasSession) {
        // User is authenticated, navigate to appropriate screen based on role
        _navigateBasedOnRole(user);
      } else {
        // User is not authenticated, navigate to login screen
        _navigateToLogin();
      }
    } catch (e) {
      // Handle any errors by navigating to login screen
      _navigateToLogin();
    }
  }

  void _navigateBasedOnRole(User user) {
    if (user.userMetadata['role'] == 'admin') {
      Navigator.pushReplacementNamed(context, AppRouter.adminHome);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.gradientBlack,
              AppTheme.gradientPink,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App Logo
                              Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: AppTheme.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: AppTheme.borderLightGray,
                                  ),
                                ),
                                child: const AppLogo(
                                  size: 60,
                                  backgroundColor: AppTheme.white,
                                  logoColor: AppTheme.gradientBlack,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // App Name
                              Text(
                                'Exhibae',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your Gateway to Amazing Exhibitions',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Loading indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
