import 'package:intl/intl.dart';

/// Formatting utilities for dates, currency, and text

class Formatters {
  /// Format currency (Indian Rupees)
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  
  /// Format currency with decimals
  static String currencyDecimal(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
  
  /// Format distance in km
  static String distance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
  
  /// Format duration in minutes
  static String duration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (mins == 0) {
      return '$hours hr';
    }
    
    return '$hours hr $mins min';
  }
  
  /// Format duration from seconds
  static String durationFromSeconds(int seconds) {
    return duration(seconds ~/ 60);
  }
  
  /// Format date
  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
  
  /// Format date short
  static String dateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }
  
  /// Format time
  static String time(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
  
  /// Format date and time
  static String dateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }
  
  /// Format relative time (e.g., "2 hours ago")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return date(dateTime);
    }
  }
  
  /// Format phone number with country code
  static String phone(String number) {
    if (number.length == 10) {
      return '+91 ${number.substring(0, 5)} ${number.substring(5)}';
    }
    return number;
  }
  
  /// Mask phone number for privacy
  static String maskPhone(String number) {
    if (number.length >= 10) {
      final last4 = number.substring(number.length - 4);
      return 'XXXXXX$last4';
    }
    return number;
  }
  
  /// Format vehicle number
  static String vehicleNumber(String number) {
    final clean = number.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    if (clean.length >= 9) {
      return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, clean.length - 4)} ${clean.substring(clean.length - 4)}';
    }
    return number.toUpperCase();
  }
  
  /// Format rating
  static String rating(double value) {
    return value.toStringAsFixed(1);
  }
  
  /// Format number with commas
  static String number(int value) {
    return NumberFormat('#,##,###').format(value);
  }
  
  /// Format compact number (e.g., 12.5K, 1.2M)
  static String compactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }
  
  /// Format percentage
  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
  
  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }
  
  /// Capitalize each word
  static String capitalizeWords(String text) {
    return text.split(' ').map(capitalize).join(' ');
  }
  
  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  /// Format file size
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// Get day of week
  static String dayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
  
  /// Get month name
  static String monthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }
}
