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
import '../../features/passenger/tracking/screens/tracking_screen.dart';
import '../../features/passenger/history/screens/trip_history_screen.dart';
import '../../features/passenger/profile/screens/passenger_profile_screen.dart';
import '../../features/passenger/sos/screens/sos_screen.dart';

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
  static const String otp = '/otp';
  static const String roleSelection = '/role-selection';
  
  // Passenger Routes
  static const String passengerHome = '/passenger';
  static const String booking = '/passenger/booking';
  static const String tracking = '/passenger/tracking/:rideId';
  static const String tripHistory = '/passenger/history';
  static const String passengerProfile = '/passenger/profile';
  static const String sos = '/passenger/sos';
  
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
        path: Routes.otp,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phoneNumber: phone);
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Trips',
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
    if (location.startsWith(Routes.tripHistory)) return 1;
    if (location.startsWith(Routes.passengerProfile)) return 2;
    return 0;
  }
  
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(Routes.passengerHome);
        break;
      case 1:
        context.go(Routes.tripHistory);
        break;
      case 2:
        context.go(Routes.passengerProfile);
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
