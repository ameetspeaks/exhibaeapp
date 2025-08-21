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
import '../../features/brand/presentation/screens/favorite_exhibitions_screen.dart';
import '../../features/organizer/presentation/screens/payment_history_screen.dart';
import '../../features/organizer/presentation/screens/payment_details_screen.dart';
import '../../features/organizer/presentation/screens/brand_profiles_screen.dart';
import '../../features/organizer/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/organizer/presentation/screens/reports_screen.dart';
import '../../features/organizer/presentation/screens/stall_layout_screen.dart';
import '../../features/organizer/presentation/screens/organizer_exhibition_details_screen.dart';
import '../../features/organizer/presentation/screens/revenue_screen.dart';
import '../../features/organizer/presentation/screens/favorites_screen.dart';
import '../../features/brand/presentation/screens/payment_submission_screen.dart';
import '../../features/organizer/presentation/screens/payment_review_screen.dart';
import '../../features/brand/presentation/screens/stall_details_screen.dart';
import '../../features/shopper/presentation/screens/shopper_dashboard_screen.dart';
import '../../features/shopper/presentation/screens/shopper_home_screen.dart';
import '../../features/shopper/presentation/screens/shopper_explore_screen.dart';
import '../../features/shopper/presentation/screens/shopper_favorites_screen.dart';
import '../../features/shopper/presentation/screens/shopper_exhibition_details_screen.dart';
import '../../features/shopper/presentation/screens/shopper_profile_screen.dart';
import '../../features/shopper/presentation/screens/edit_profile_screen.dart';
import '../../features/organizer/presentation/screens/edit_profile_screen.dart';
import '../../features/auth/presentation/screens/whatsapp_login_screen.dart';
import '../../features/auth/presentation/screens/whatsapp_otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_verification_screen.dart';

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
  static const String favoriteExhibitions = '/favorite-exhibitions';
  static const String paymentHistory = '/payment-history';
  static const String paymentDetails = '/payment-details';
  static const String brandProfiles = '/brand-profiles';
  static const String analyticsDashboard = '/analytics-dashboard';
  static const String reports = '/reports';
  static const String stallLayout = '/stall-layout';
  static const String organizerExhibitionDetails = '/organizer-exhibition-details';
  static const String revenue = '/revenue';
  static const String favorites = '/favorites';
  static const String paymentSubmission = '/payment-submission';
  static const String paymentReview = '/payment-review';
  static const String stallDetails = '/stall-details';
  static const String shopperDashboard = '/shopper-dashboard';
  static const String shopperHome = '/shopper-home';
  static const String shopperExplore = '/shopper-explore';
  static const String shopperFavorites = '/shopper-favorites';
  static const String shopperExhibitionDetails = '/shopper-exhibition-details';
  static const String shopperProfile = '/shopper-profile';
  static const String shopperEditProfile = '/shopper-edit-profile';
  static const String organizerEditProfile = '/organizer-edit-profile';
  static const String whatsappLogin = '/whatsapp-login';
  static const String whatsappOtpVerification = '/whatsapp-otp-verification';
  static const String phoneVerification = '/phone-verification';

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
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => HomeScreen(
            initialTab: args?['initialTab'] as int? ?? 0,
          ),
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
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ApplicationListScreen(
            exhibitionId: args?['exhibitionId'] as String?,
            exhibitionTitle: args?['exhibitionTitle'] as String?,
          ),
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
      case favoriteExhibitions:
        return MaterialPageRoute(
          builder: (_) => const FavoriteExhibitionsScreen(),
        );
      case paymentHistory:
        return MaterialPageRoute(
          builder: (_) => const PaymentHistoryScreen(),
        );
      case paymentDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentDetailsScreen(
            applicationId: args['applicationId'] as String,
          ),
        );
      case brandProfiles:
        return MaterialPageRoute(
          builder: (_) => const BrandProfilesScreen(),
        );
      case analyticsDashboard:
        return MaterialPageRoute(
          builder: (_) => const AnalyticsDashboardScreen(),
        );
      case reports:
        return MaterialPageRoute(
          builder: (_) => const ReportsScreen(),
        );
      case stallLayout:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => StallLayoutScreen(
            exhibitionId: args['exhibitionId'] as String,
          ),
        );
      case organizerExhibitionDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OrganizerExhibitionDetailsScreen(
            exhibition: args['exhibition'] as Map<String, dynamic>,
          ),
        );
      case revenue:
        return MaterialPageRoute(
          builder: (_) => const RevenueScreen(),
        );
      case favorites:
        return MaterialPageRoute(
          builder: (_) => const FavoritesScreen(),
        );
      case paymentSubmission:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentSubmissionScreen(
            application: args['application'] as Map<String, dynamic>,
          ),
        );
      case paymentReview:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentReviewScreen(
            application: args['application'] as Map<String, dynamic>,
          ),
        );
      case stallDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => StallDetailsScreen(
            stall: args['stall'] as Map<String, dynamic>,
          ),
        );
      case shopperDashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ShopperDashboardScreen(
            initialTab: args?['initialTab'] as int? ?? 0,
          ),
        );
      case shopperHome:
        return MaterialPageRoute(
          builder: (_) => const ShopperHomeScreen(),
        );
      case shopperExplore:
        return MaterialPageRoute(
          builder: (_) => const ShopperExploreScreen(),
        );
      case shopperFavorites:
        return MaterialPageRoute(
          builder: (_) => const ShopperFavoritesScreen(),
        );
      case shopperExhibitionDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ShopperExhibitionDetailsScreen(
            exhibition: args['exhibition'] as Map<String, dynamic>,
          ),
        );
      case shopperProfile:
        return MaterialPageRoute(
          builder: (_) => const ShopperProfileScreen(),
        );
      case shopperEditProfile:
        return MaterialPageRoute(
          builder: (_) => const ShopperEditProfileScreen(),
        );
      case organizerEditProfile:
        return MaterialPageRoute(
          builder: (_) => const OrganizerEditProfileScreen(),
        );
      case whatsappLogin:
        return MaterialPageRoute(
          builder: (_) => const WhatsAppLoginScreen(),
        );
      case whatsappOtpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => WhatsAppOtpVerificationScreen(
            phoneNumber: args['phoneNumber'] as String,
            verificationType: args['verificationType'] as String,
          ),
        );
      case phoneVerification:
        return MaterialPageRoute(
          builder: (_) => const PhoneVerificationScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
    }
  }
}
