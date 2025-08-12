import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/brand/presentation/screens/exhibition_details_screen.dart';
import '../../features/brand/presentation/screens/application_form_screen.dart';
import '../../features/brand/presentation/screens/edit_profile_screen.dart';
import '../../features/brand/presentation/screens/stall_selection_screen.dart';
import '../../features/organizer/presentation/screens/exhibition_form_screen.dart';
import '../../features/organizer/presentation/screens/notifications_screen.dart';
import '../../features/organizer/presentation/screens/organizer_exhibitions_screen.dart';
import '../../features/organizer/presentation/screens/application_list_screen.dart';
import '../../features/organizer/presentation/screens/application_details_screen.dart';
import '../../features/organizer/presentation/screens/notification_settings_screen.dart';
import '../../features/organizer/presentation/screens/privacy_settings_screen.dart';
import '../../features/organizer/presentation/screens/support_screen.dart';
import '../../features/brand/presentation/screens/brand_stalls_screen.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String exhibitionDetails = '/exhibition-details';
  static const String applicationForm = '/application-form';
  static const String editProfile = '/edit-profile';
  static const String stallSelection = '/stall-selection';
  static const String exhibitionForm = '/exhibition-form';
  static const String notifications = '/notifications';
  static const String exhibitions = '/exhibitions';
  static const String applications = '/applications';
  static const String applicationDetails = '/application-details';
  static const String notificationSettings = '/notification-settings';
  static const String privacySettings = '/privacy-settings';
  static const String support = '/support';
  static const String brandStalls = '/brand-stalls';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case auth:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        );
      case signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: args['email'] as String,
            userId: args['userId'] as String,
          ),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case exhibitionDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ExhibitionDetailsScreen(
            exhibition: args['exhibition'] as Map<String, dynamic>,
          ),
        );
      case applicationForm:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ApplicationFormScreen(
            exhibition: args['exhibition'] as Map<String, dynamic>,
            selectedStall: args['selectedStall'] as Map<String, dynamic>?,
          ),
        );
      case editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        );
      case stallSelection:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => StallSelectionScreen(
            exhibition: args['exhibition'] as Map<String, dynamic>,
          ),
        );
      case exhibitionForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ExhibitionFormScreen(
            existingExhibition: args?['exhibition'] as Map<String, dynamic>?,
          ),
        );
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );
      case exhibitions:
        return MaterialPageRoute(
          builder: (_) => const OrganizerExhibitionsScreen(),
        );
      case applications:
        return MaterialPageRoute(
          builder: (_) => const ApplicationListScreen(),
        );
      case applicationDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ApplicationDetailsScreen(
            application: args as Map<String, dynamic>,
          ),
        );
      case notificationSettings:
        return MaterialPageRoute(
          builder: (_) => const NotificationSettingsScreen(),
        );
      case privacySettings:
        return MaterialPageRoute(
          builder: (_) => const PrivacySettingsScreen(),
        );
      case support:
        return MaterialPageRoute(
          builder: (_) => const SupportScreen(),
        );
      case brandStalls:
        return MaterialPageRoute(
          builder: (_) => const BrandStallsScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
    }
  }
}
