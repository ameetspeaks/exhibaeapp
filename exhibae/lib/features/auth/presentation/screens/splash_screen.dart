import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    // Check authentication and navigate accordingly with a slight delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkAuthState();
      }
    });
    
    // Fallback to ensure navigation happens
    _ensureNavigation();
  }

  Future<void> _checkAuthState() async {
    try {
      // Add timeout to prevent infinite loading
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if user is already authenticated
      final user = _supabaseService.currentUser;
      final hasSession = await _supabaseService.hasStoredSession().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      
      if (mounted) {
        if (user != null && hasSession) {
          // User is authenticated, navigate to appropriate screen based on role
          _navigateBasedOnRole(user);
        } else {
          // User is not authenticated, navigate to login screen
          _navigateToLogin();
        }
      }
    } catch (e) {
      // Handle any errors by navigating to login screen
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  // Fallback method to ensure navigation happens
  void _ensureNavigation() {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _navigateToLogin();
      }
    });
  }

  void _navigateBasedOnRole(User user) {
    // Navigate based on user role
    final userMetadata = user.userMetadata;
    final role = userMetadata?['role'] as String?;
    
    switch (role) {
      case 'admin':
      case 'organizer':
        Navigator.pushReplacementNamed(context, AppRouter.home);
        break;
      case 'brand':
        Navigator.pushReplacementNamed(context, AppRouter.home);
        break;
      case 'shopper':
        Navigator.pushReplacementNamed(context, AppRouter.shopperHome);
        break;
      default:
        // Default to home screen for unknown roles
        Navigator.pushReplacementNamed(context, AppRouter.home);
        break;
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
      backgroundColor: AppTheme.backgroundPeach,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundPeach,
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
