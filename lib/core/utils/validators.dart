/// Validation utilities for form fields
library;

class Validators {
  /// Validate phone number (Indian format)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and country code
    final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    return null;
  }
  
  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validate OTP
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    
    return null;
  }
  
  /// Validate name
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    return null;
  }
  
  /// Validate vehicle registration number
  static String? vehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required';
    }
    
    // Indian vehicle registration format
    final vehicleRegex = RegExp(
      r'^[A-Z]{2}[\s-]?\d{1,2}[\s-]?[A-Z]{1,3}[\s-]?\d{1,4}$',
      caseSensitive: false,
    );
    
    if (!vehicleRegex.hasMatch(value)) {
      return 'Please enter a valid vehicle number';
    }
    
    return null;
  }
  
  /// Validate license number
  static String? licenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    
    if (value.length < 10) {
      return 'Please enter a valid license number';
    }
    
    return null;
  }
  
  /// Validate amount
  static String? amount(String? value, {double min = 0, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount < min) {
      return 'Amount must be at least ₹${min.toInt()}';
    }
    
    if (max != null && amount > max) {
      return 'Amount must be less than ₹${max.toInt()}';
    }
    
    return null;
  }
  
  /// Validate promo code
  static String? promoCode(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Promo code is optional
    }
    
    if (value.length < 4) {
      return 'Promo code must be at least 4 characters';
    }
    
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.toUpperCase())) {
      return 'Promo code can only contain letters and numbers';
    }
    
    return null;
  }
  
  /// Required field validator
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
