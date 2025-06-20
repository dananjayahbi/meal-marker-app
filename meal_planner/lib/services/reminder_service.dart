import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal_reminder.dart';
import '../utils/constants.dart';

class ReminderService {
  late Box<MealReminder> _remindersBox;
  
  // Initialize the service
  Future<void> init() async {
    _remindersBox = await Hive.openBox<MealReminder>(HiveBoxes.reminders);
  }
  
  // Get all reminders
  List<MealReminder> getAllReminders() {
    return _remindersBox.values.toList();
  }
  
  // Get active reminders (not dismissed)
  List<MealReminder> getActiveReminders() {
    return _remindersBox.values
        .where((reminder) => reminder.status != ReminderStatus.dismissed)
        .toList();
  }
  
  // Get reminder by ID
  MealReminder? getReminderById(String id) {
    try {
      return _remindersBox.values.firstWhere((reminder) => reminder.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Add a new reminder
  Future<void> addReminder(MealReminder reminder) async {
    reminder.updateNextTrigger();
    await _remindersBox.put(reminder.id, reminder);
  }
  
  // Update an existing reminder
  Future<void> updateReminder(MealReminder reminder) async {
    reminder.updatedAt = DateTime.now();
    reminder.updateNextTrigger();
    await _remindersBox.put(reminder.id, reminder);
  }
  
  // Delete a reminder
  Future<void> deleteReminder(String id) async {
    await _remindersBox.delete(id);
  }
  
  // Get reminders that need to be triggered now
  List<MealReminder> getRemindersToTriggerNow() {
    final now = DateTime.now();
    return _remindersBox.values
        .where((reminder) => 
            reminder.status == ReminderStatus.active && 
            reminder.nextTrigger != null &&
            reminder.nextTrigger!.isBefore(now))
        .toList();
  }
  
  // Mark a reminder as triggered
  Future<void> markReminderTriggered(String id) async {
    final reminder = getReminderById(id);
    if (reminder != null) {
      reminder.markTriggered();
      await updateReminder(reminder);
    }
  }
  
  // Snooze a reminder
  Future<void> snoozeReminder(String id, int minutes) async {
    final reminder = getReminderById(id);
    if (reminder != null) {
      reminder.snooze(minutes);
      await updateReminder(reminder);
    }
  }
  
  // Reset a reminder from snoozed state
  Future<void> resetFromSnooze(String id) async {
    final reminder = getReminderById(id);
    if (reminder != null && reminder.status == ReminderStatus.snoozed) {
      reminder.resetFromSnooze();
      await updateReminder(reminder);
    }
  }
  
  // Get history of reminders
  List<MealReminder> getReminderHistory() {
    return _remindersBox.values
        .where((reminder) => reminder.lastTriggered != null)
        .toList()
      ..sort((a, b) => 
          (b.lastTriggered ?? DateTime.now())
              .compareTo(a.lastTriggered ?? DateTime.now()));
  }
  
  // Get stats
  Map<String, dynamic> getStats() {
    final reminders = getAllReminders();
    final active = reminders.where((r) => r.status == ReminderStatus.active).length;
    final snoozed = reminders.where((r) => r.status == ReminderStatus.snoozed).length;
    final dismissed = reminders.where((r) => r.status == ReminderStatus.dismissed).length;
    
    // Calculate average meals per day
    double avgMealsPerDay = 0;
    final triggers = reminders
        .where((reminder) => reminder.lastTriggered != null)
        .map((reminder) => reminder.lastTriggered!)
        .toList();
        
    if (triggers.isNotEmpty) {
      final earliestTrigger = triggers.reduce((a, b) => a.isBefore(b) ? a : b);
      final daysSinceFirst = DateTime.now().difference(earliestTrigger).inDays;
      if (daysSinceFirst > 0) {
        avgMealsPerDay = triggers.length / daysSinceFirst;
      }
    }
    
    return {
      'total': reminders.length,
      'active': active,
      'snoozed': snoozed,
      'dismissed': dismissed,
      'recurring': reminders.where((r) => r.isRecurring).length,
      'one_time': reminders.where((r) => !r.isRecurring).length,
      'avg_meals_per_day': avgMealsPerDay,
    };
  }
}
