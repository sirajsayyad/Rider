import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// General helper utilities

class Helpers {
  /// Get status color based on ride status
  static Color getRideStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'arrived':
        return Colors.purple;
      case 'started':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  /// Get status text
  static String getRideStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Searching for driver';
      case 'accepted':
        return 'Driver on the way';
      case 'arrived':
        return 'Driver arrived';
      case 'started':
        return 'Trip in progress';
      case 'completed':
        return 'Trip completed';
      case 'cancelled':
        return 'Trip cancelled';
      default:
        return status;
    }
  }
  
  /// Get vehicle type display name
  static String getVehicleTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'auto':
        return 'Auto Rickshaw';
      case 'mini':
        return 'Mini';
      case 'sedan':
        return 'Sedan';
      case 'suv':
        return 'SUV';
      case 'premium':
        return 'Premium';
      case 'bike':
        return 'Bike';
      default:
        return type;
    }
  }
  
  /// Get vehicle type icon
  static IconData getVehicleTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'auto':
        return Icons.electric_rickshaw;
      case 'mini':
        return Icons.directions_car;
      case 'sedan':
        return Icons.directions_car_filled;
      case 'suv':
        return Icons.airport_shuttle;
      case 'premium':
        return Icons.local_taxi;
      case 'bike':
        return Icons.two_wheeler;
      default:
        return Icons.directions_car;
    }
  }
  
  /// Get payment method icon
  static IconData getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
  
  /// Get document type display name
  static String getDocumentTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'license':
        return 'Driving License';
      case 'vehicle_rc':
        return 'Vehicle RC';
      case 'insurance':
        return 'Insurance';
      case 'profile_photo':
        return 'Profile Photo';
      case 'vehicle_photo':
        return 'Vehicle Photo';
      default:
        return type;
    }
  }
  
  /// Get document status color
  static Color getDocumentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }
  
  /// Calculate estimated fare
  static double calculateFare({
    required double distanceKm,
    required String vehicleType,
    double surgeFactor = 1.0,
  }) {
    // Base rates per km for different vehicle types
    final Map<String, double> baseRates = {
      'auto': 12.0,
      'mini': 14.0,
      'sedan': 16.0,
      'suv': 22.0,
      'premium': 28.0,
      'bike': 8.0,
    };
    
    // Minimum fares
    final Map<String, double> minFares = {
      'auto': 30.0,
      'mini': 50.0,
      'sedan': 70.0,
      'suv': 100.0,
      'premium': 150.0,
      'bike': 20.0,
    };
    
    final rate = baseRates[vehicleType.toLowerCase()] ?? 15.0;
    final minFare = minFares[vehicleType.toLowerCase()] ?? 40.0;
    
    var fare = distanceKm * rate * surgeFactor;
    
    // Apply minimum fare
    if (fare < minFare) {
      fare = minFare;
    }
    
    return fare;
  }
  
  /// Calculate estimated time
  static int calculateETA(double distanceKm) {
    // Assuming average speed of 25 km/h in city
    const avgSpeedKmH = 25.0;
    final timeHours = distanceKm / avgSpeedKmH;
    return (timeHours * 60).round(); // Return minutes
  }
  
  /// Show snackbar
  static void showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Copy to clipboard
  static Future<void> copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showSnackbar(context, 'Copied to clipboard');
    }
  }
  
  /// Hide keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  
  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
  
  /// Get rating stars
  static List<Widget> getRatingStars(double rating, {double size = 16}) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: size));
      } else if (rating >= i - 0.5) {
        stars.add(Icon(Icons.star_half, color: Colors.amber, size: size));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.amber, size: size));
      }
    }
    return stars;
  }
  
  /// Generate random OTP for demo
  static String generateOTP() {
    return '123456'; // Fixed OTP for demo
  }
}
