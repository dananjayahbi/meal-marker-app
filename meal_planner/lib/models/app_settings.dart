import 'package:flutter/material.dart';

// Since we're using manual adapters, we don't need HiveType and HiveField annotations
class AppSettings {
  // Fields - indexes used in the manual adapter:
  // 0: sleepModeEnabled
  // 1: sleepStartTime
  // 2: sleepEndTime
  // 3: globalSnoozeEnabled
  // 4: globalSnoozeUntil
  // 5: globalSnoozeMinutes
  // 6: globalSnoozedReminderIds
  bool sleepModeEnabled;
  DateTime? sleepStartTime;
  DateTime? sleepEndTime;
  bool globalSnoozeEnabled;
  DateTime? globalSnoozeUntil;
  int? globalSnoozeMinutes;
  List<String> globalSnoozedReminderIds;

  AppSettings({
    this.sleepModeEnabled = false,
    this.sleepStartTime,
    this.sleepEndTime,
    this.globalSnoozeEnabled = false,
    this.globalSnoozeUntil,
    this.globalSnoozeMinutes,
    this.globalSnoozedReminderIds = const [],
  });

  factory AppSettings.defaultSettings() {
    // Default sleep time from 10:00 PM to 6:00 AM
    final now = DateTime.now();
    final sleepStart = DateTime(now.year, now.month, now.day, 22, 0); // 10:00 PM
    final sleepEnd = DateTime(now.year, now.month, now.day, 6, 0);    // 6:00 AM

    return AppSettings(
      sleepModeEnabled: false,
      sleepStartTime: sleepStart,
      sleepEndTime: sleepEnd,
      globalSnoozeEnabled: false,
    );
  }

  // Check if current time is within sleep hours
  bool isInSleepPeriod(DateTime dateTime) {
    if (!sleepModeEnabled || sleepStartTime == null || sleepEndTime == null) {
      return false;
    }

    // Extract hours and minutes for comparison
    final checkTime = TimeOfDay.fromDateTime(dateTime);
    final startTime = TimeOfDay.fromDateTime(sleepStartTime!);
    final endTime = TimeOfDay.fromDateTime(sleepEndTime!);

    // Convert times to minutes for easier comparison
    final checkMinutes = checkTime.hour * 60 + checkTime.minute;
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int endMinutes = endTime.hour * 60 + endTime.minute;

    // Handle case where sleep period crosses midnight
    if (endMinutes < startMinutes) {
      // If end time is less than start time, it means the period crosses midnight
      // Example: 10:00 PM to 6:00 AM
      return checkMinutes >= startMinutes || checkMinutes <= endMinutes;
    } else {
      // Normal case where sleep period is within the same day
      return checkMinutes >= startMinutes && checkMinutes <= endMinutes;
    }
  }
}
