import 'package:intl/intl.dart';

class DateUtils {
  // Format dates for display
  static String formatTime(DateTime time) {
    return DateFormat.jm().format(time); // Format as 3:30 PM
  }
  
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date); // Format as Apr 27, 2025
  }
  
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}'; // Format as Apr 27, 2025 at 3:30 PM
  }

  static String formatTimeRemaining(DateTime target) {
    final now = DateTime.now();
    final difference = target.difference(now);
    
    // If the target time is in the past
    if (difference.isNegative) {
      return 'Overdue';
    }
    
    // For times less than an hour away
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes != 1 ? 's' : ''} remaining';
    }
    
    // For times less than a day away
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours != 1 ? 's' : ''} remaining';
    }
    
    // For more than a day away
    final days = difference.inDays;
    return '$days day${days != 1 ? 's' : ''} remaining';
  }

  // Check if two DateTimes are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Get beginning of the current day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
