import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String currencyDecimal(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 2,
    ).format(amount);
  }

  static String distance(double km) {
    if (km < 1) return '${(km * 1000).toInt()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  static String date(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  static String time(DateTime dateTime) => DateFormat('hh:mm a').format(dateTime);

  static String dateTime(DateTime dateTime) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);

  static String relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day ago';
    return date(dateTime);
  }

  static String rating(double value) => value.toStringAsFixed(1);

  static String compactNumber(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
