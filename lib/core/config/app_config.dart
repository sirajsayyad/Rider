/// Application configuration constants
library;

class AppConfig {
  // App Info
  static const String appName = 'RideConnect';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API Configuration
  static const String baseUrl = 'https://api.rideconnect.com';
  static const String wsUrl = 'wss://ws.rideconnect.com';
  
  // Demo Mode - set to false when connecting to real backend
  static const bool isDemoMode = true;
  static const String demoOtp = '123456';
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;
  static const int rideRequestTimeout = 30; // seconds to accept/reject ride
  
  // Map Configuration
  static const double defaultMapZoom = 15.0;
  static const double defaultLatitude = 28.6139; // Delhi
  static const double defaultLongitude = 77.2090;
  
  // Ride Configuration
  static const double driverSearchRadius = 5.0; // km
  static const int maxSavedLocations = 5;
  static const double minBookingDistance = 0.5; // km
  static const double maxBookingDistance = 100.0; // km
  
  // Payment Configuration
  static const double minWalletRecharge = 100.0;
  static const double maxWalletRecharge = 10000.0;
  static const double minFare = 30.0;
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';
  
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Driver Rating Thresholds
  static const double goodRating = 4.5;
  static const double averageRating = 3.5;
  
  // Commission
  static const double platformCommission = 0.20; // 20%
}
