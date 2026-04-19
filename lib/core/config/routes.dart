import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';

import '../../features/passenger/home/screens/passenger_home_screen.dart';
import '../../features/passenger/booking/screens/booking_screen.dart';
import '../../features/passenger/booking/screens/chat_screen.dart';
import '../../features/passenger/booking/screens/rewards_screen.dart';
import '../../features/passenger/booking/screens/driver_searching_screen.dart';
import '../../features/passenger/tracking/screens/tracking_screen.dart';
import '../../features/passenger/history/screens/trip_history_screen.dart';
import '../../features/passenger/profile/screens/passenger_profile_screen.dart';
import '../../features/passenger/sos/screens/sos_screen.dart';
import '../../features/passenger/ride/screens/ride_details_screen.dart';
import '../../features/passenger/payments/screens/payment_methods_screen.dart';
import '../../features/passenger/payments/screens/billing_screen.dart';
import '../../features/passenger/payments/screens/receipt_screen.dart';
import '../../features/passenger/notifications/screens/notifications_screen.dart';

import '../../features/driver/home/screens/driver_home_screen.dart';
import '../../features/driver/earnings/screens/earnings_screen.dart';
import '../../features/driver/documents/screens/documents_screen.dart';
import '../../features/driver/profile/screens/driver_profile_screen.dart';

import '../../features/admin/dashboard/screens/admin_dashboard_screen.dart';

/// Route paths
class Routes {
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String roleSelection = '/role-selection';

  // Passenger Routes
  static const String passengerHome = '/passenger';
  static const String passengerHomeTab = '/passenger/home';
  static const String passengerServicesTab = '/passenger/services';
  static const String passengerActivityTab = '/passenger/activity';
  static const String passengerAccountTab = '/passenger/account';
  static const String passengerForYouTab = '/passenger/for-you';
  static const String booking = '/passenger/booking';
  static const String driverSearching = '/passenger/searching';
  static const String tracking = '/passenger/tracking/:rideId';
  static const String tripHistory = '/passenger/history';
  static const String passengerProfile = '/passenger/profile';
  static const String sos = '/passenger/sos';
  static const String rideDetails = '/passenger/ride-details';
  static const String paymentMethods = '/passenger/payment-methods';
  static const String billing = '/passenger/billing';
  static const String receipt = '/passenger/receipt';
  static const String notifications = '/passenger/notifications';
  static const String chat = '/passenger/chat';
  static const String rewards = '/passenger/rewards';

  // Driver Routes
  static const String driverHome = '/driver';
  static const String driverEarnings = '/driver/earnings';
  static const String driverDocuments = '/driver/documents';
  static const String driverProfile = '/driver/profile';

  // Admin Routes
  static const String adminDashboard = '/admin';
}

/// App Router Configuration
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Auth Routes
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (context, state) {
          final contact = state.extra as String? ?? '';
          return OtpScreen(contact: contact);
        },
      ),
      GoRoute(
        path: Routes.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Passenger Routes
      ShellRoute(
        builder: (context, state, child) => PassengerShell(child: child),
        routes: [
          GoRoute(
            path: Routes.passengerHome,
            redirect: (context, state) => Routes.passengerHomeTab,
          ),
          GoRoute(
            path: Routes.passengerHomeTab,
            builder: (context, state) => const PassengerHomeScreen(),
          ),
          GoRoute(
            path: Routes.passengerServicesTab,
            builder: (context, state) => const TripHistoryScreen(),
          ),
          GoRoute(
            path: Routes.passengerActivityTab,
            builder: (context, state) => const TripHistoryScreen(),
          ),
          GoRoute(
            path: Routes.passengerAccountTab,
            builder: (context, state) => const PassengerProfileScreen(),
          ),
          GoRoute(
            path: Routes.passengerForYouTab,
            builder: (context, state) => const PassengerHomeScreen(),
          ),
          GoRoute(
            path: Routes.tripHistory,
            builder: (context, state) => const TripHistoryScreen(),
          ),
          GoRoute(
            path: Routes.passengerProfile,
            builder: (context, state) => const PassengerProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.booking,
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: Routes.driverSearching,
        builder: (context, state) => const DriverSearchingScreen(),
      ),
      GoRoute(
        path: Routes.tracking,
        builder: (context, state) {
          final rideId = state.pathParameters['rideId'] ?? '';
          return TrackingScreen(rideId: rideId);
        },
      ),
      GoRoute(
        path: Routes.sos,
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: Routes.rideDetails,
        builder: (context, state) => const RideDetailsScreen(),
      ),
      GoRoute(
        path: Routes.paymentMethods,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: Routes.billing,
        builder: (context, state) => const BillingScreen(),
      ),
      GoRoute(
        path: Routes.receipt,
        builder: (context, state) => const ReceiptScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: Routes.rewards,
        builder: (context, state) => const RewardsScreen(),
      ),

      // Driver Routes
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(
            path: Routes.driverHome,
            builder: (context, state) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: Routes.driverEarnings,
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: Routes.driverDocuments,
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: Routes.driverProfile,
            builder: (context, state) => const DriverProfileScreen(),
          ),
        ],
      ),

      // Admin Routes
      GoRoute(
        path: Routes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Passenger Shell with Bottom Navigation
class PassengerShell extends StatelessWidget {
  final Widget child;

  const PassengerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'For You',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(Routes.passengerServicesTab)) return 1;
    if (location.startsWith(Routes.passengerActivityTab) ||
        location.startsWith(Routes.tripHistory)) return 2;
    if (location.startsWith(Routes.passengerAccountTab) ||
        location.startsWith(Routes.passengerProfile)) return 3;
    if (location.startsWith(Routes.passengerForYouTab)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(Routes.passengerHomeTab);
        break;
      case 1:
        context.go(Routes.passengerServicesTab);
        break;
      case 2:
        context.go(Routes.passengerActivityTab);
        break;
      case 3:
        context.go(Routes.passengerAccountTab);
        break;
      case 4:
        context.go(Routes.passengerForYouTab);
        break;
    }
  }
}

/// Driver Shell with Bottom Navigation
class DriverShell extends StatelessWidget {
  final Widget child;

  const DriverShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(Routes.driverEarnings)) return 1;
    if (location.startsWith(Routes.driverDocuments)) return 2;
    if (location.startsWith(Routes.driverProfile)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(Routes.driverHome);
        break;
      case 1:
        context.go(Routes.driverEarnings);
        break;
      case 2:
        context.go(Routes.driverDocuments);
        break;
      case 3:
        context.go(Routes.driverProfile);
        break;
    }
  }
}
