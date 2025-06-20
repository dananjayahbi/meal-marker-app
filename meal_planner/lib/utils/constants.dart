// Constants for the Meal Planner app

// Vibration patterns
class VibrationPatterns {
  static const List<int> gentle = [300, 100, 300];
  static const List<int> normal = [500, 200, 500];
  static const List<int> intense = [800, 300, 800, 300, 800];

  static List<int> getPattern(String type) {
    switch (type.toLowerCase()) {
      case 'gentle':
        return gentle;
      case 'intense':
        return intense;
      case 'normal':
      default:
        return normal;
    }
  }
}

// Recurrence options
class RecurrenceOptions {
  static const String oneTime = 'one_time';
  static const String hourly = 'hourly';
  static const String daily = 'daily';
  static const String custom = 'custom';

  static Duration? getDuration(String type, {int? customHours}) {
    switch (type) {
      case hourly:
        return const Duration(hours: 1);
      case daily:
        return const Duration(days: 1);
      case custom:
        return Duration(hours: customHours ?? 3); // Default to 3 hours if not specified
      default:
        return null; // One-time reminder has no duration
    }
  }

  static String getRecurrenceLabel(String? type, Duration? duration) {
    if (type == null || type == oneTime) {
      return 'One-time';
    }
    
    switch (type) {
      case hourly:
        return 'Every hour';
      case daily:
        return 'Daily';
      case custom:
        if (duration == null) return 'Custom';
        
        if (duration.inHours < 24) {
          return 'Every ${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
        } else {
          final days = duration.inHours ~/ 24;
          return 'Every $days day${days > 1 ? 's' : ''}';
        }
      default:
        return 'Unknown';
    }
  }
}

// Notification channels
class NotificationChannels {
  static const String mealRemindersChannel = 'meal_reminders';
  static const String mealRemindersChannelName = 'Meal Reminders';
  static const String mealRemindersChannelDescription = 'Notifications for meal reminders';
}

// Hive box names
class HiveBoxes {
  static const String reminders = 'reminders_box';
  static const String settings = 'settings_box';
}

// Notification IDs
class NotificationIds {
  static const int reminderBase = 1000;
}
