import 'package:flutter/foundation.dart';
import '../models/meal_reminder.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class AppStateProvider with ChangeNotifier {
  final ReminderService _reminderService;
  final NotificationService _notificationService;
  SettingsService? _settingsService;
  
  List<MealReminder> _reminders = [];
  bool _isLoading = false;
  
  AppStateProvider(this._reminderService, this._notificationService, {SettingsService? settingsService}) {
    _settingsService = settingsService;
  }
  
  // Getters
  List<MealReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  
  // Load all reminders from storage
  Future<void> loadReminders() async {
    _isLoading = true;
    notifyListeners();
    
    _reminders = _reminderService.getAllReminders();
    _reminders.sort((a, b) => (a.nextTrigger ?? DateTime.now()).compareTo(b.nextTrigger ?? DateTime.now()));
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Add a new reminder
  Future<void> addReminder(MealReminder reminder) async {
    _isLoading = true;
    notifyListeners();
    
    await _reminderService.addReminder(reminder);
    await _notificationService.scheduleReminderNotification(reminder);
    
    await loadReminders();
  }
  
  // Update an existing reminder
  Future<void> updateReminder(MealReminder reminder) async {
    _isLoading = true;
    notifyListeners();
    
    await _reminderService.updateReminder(reminder);
    await _notificationService.cancelNotification(reminder);
    await _notificationService.scheduleReminderNotification(reminder);
    
    await loadReminders();
  }
  
  // Delete a reminder
  Future<void> deleteReminder(String id) async {
    _isLoading = true;
    notifyListeners();
    
    final reminder = _reminderService.getReminderById(id);
    if (reminder != null) {
      await _notificationService.cancelNotification(reminder);
      await _reminderService.deleteReminder(id);
    }
    
    await loadReminders();
  }
  
  // Mark a reminder as triggered
  Future<void> markReminderTriggered(String id) async {
    final reminder = _reminderService.getReminderById(id);
    if (reminder != null) {
      await _reminderService.markReminderTriggered(id);
      
      // If it's a recurring reminder, schedule the next occurrence
      if (reminder.isRecurring) {
        reminder.markTriggered();
        await _notificationService.scheduleReminderNotification(reminder);
      } else {
        // For one-time reminders, cancel the notification
        await _notificationService.cancelNotification(reminder);
      }
      
      await loadReminders();
    }
  }
    // Snooze a reminder
  Future<void> snoozeReminder(String id, int minutes) async {
    final reminder = _reminderService.getReminderById(id);
    if (reminder != null) {
      // If minutes is 0, it means we're resetting the snooze
      if (minutes == 0) {
        await resetSnooze(id);
        return;
      }
      
      await _reminderService.snoozeReminder(id, minutes);
      
      // Cancel the old notification and schedule a new one for the snoozed time
      await _notificationService.cancelNotification(reminder);
      reminder.snooze(minutes);
      await _notificationService.scheduleReminderNotification(reminder);
      
      await loadReminders();
    }
  }
  
  // Reset a reminder from snoozed state
  Future<void> resetSnooze(String id) async {
    final reminder = _reminderService.getReminderById(id);
    if (reminder != null && reminder.status == ReminderStatus.snoozed) {
      await _reminderService.resetFromSnooze(id);
      
      // Cancel the old notification and schedule a new one
      await _notificationService.cancelNotification(reminder);
      final updatedReminder = _reminderService.getReminderById(id);
      if (updatedReminder != null) {
        await _notificationService.scheduleReminderNotification(updatedReminder);
      }
      
      await loadReminders();
    }
  }
  
  // Check for reminders that need to be triggered
  Future<void> checkAndTriggerReminders() async {
    final remindersToTrigger = _reminderService.getRemindersToTriggerNow();
    
    for (final reminder in remindersToTrigger) {
      // Show notification
      await _notificationService.showReminderNotification(reminder);
      
      // Update reminder status
      await _reminderService.markReminderTriggered(reminder.id);
      
      // If it's a recurring reminder, schedule the next occurrence
      if (reminder.isRecurring) {
        final updatedReminder = _reminderService.getReminderById(reminder.id);
        if (updatedReminder != null) {
          await _notificationService.scheduleReminderNotification(updatedReminder);
        }
      }
    }
    
    if (remindersToTrigger.isNotEmpty) {
      await loadReminders();
    }
  }
  
  // Get reminder by ID
  MealReminder? getReminderById(String id) {
    return _reminderService.getReminderById(id);
  }
    // Get active reminders
  List<MealReminder> getActiveReminders() {
    // If global snooze is enabled, don't show any reminders in the active list
    if (isGlobalSnoozed()) {
      return [];
    }
    return _reminders.where((r) => r.status == ReminderStatus.active).toList();
  }
  
  // Get snoozed reminders
  List<MealReminder> getSnoozedReminders() {
    // If global snooze is enabled, show all active reminders as snoozed as well
    if (isGlobalSnoozed()) {
      return _reminders.where((r) => 
        r.status == ReminderStatus.snoozed || r.status == ReminderStatus.active
      ).toList();
    }
    return _reminders.where((r) => r.status == ReminderStatus.snoozed).toList();
  }
  
  // Get history of reminders
  List<MealReminder> getReminderHistory() {
    return _reminderService.getReminderHistory();
  }
  
  // Get statistics
  Map<String, dynamic> getStats() {
    return _reminderService.getStats();
  }  // Apply global snooze to all reminders  
  Future<void> applyGlobalSnooze(int minutes) async {
    if (_settingsService == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Enable global snooze in settings
      await _settingsService!.enableGlobalSnooze(minutes);
      
      // Mark all active reminders as snoozed
      final activeReminders = _reminders.where((r) => 
        r.status == ReminderStatus.active
      ).toList();
      
      // Collect IDs of reminders being snoozed by global snooze
      List<String> reminderIds = activeReminders.map((r) => r.id).toList();
      await _settingsService!.addGlobalSnoozedReminderIds(reminderIds);
      
      // Mark reminders as snoozed immediately in memory for UI update
      for (final reminder in activeReminders) {
        reminder.status = ReminderStatus.snoozed;
        reminder.snoozeMinutes = minutes;
        
        if (minutes <= 0) {
          reminder.nextTrigger = null; // Infinite snooze
        } else {
          reminder.nextTrigger = DateTime.now().add(Duration(minutes: minutes));
        }
      }
      
      // Notify UI immediately
      notifyListeners();
      
      // Then update in storage
      for (final reminder in activeReminders) {
        await _reminderService.snoozeReminder(reminder.id, minutes);
      }
      
      // Cancel all notifications while snoozed
      try {
        await _notificationService.cancelAllNotifications();
      } catch (e) {
        print('Error cancelling notifications during global snooze: $e');
        // Continue execution even if notification cancellation fails
      }
      
      // Reload reminders to update UI with the latest data
      await loadReminders();
    } catch (e) {
      print('Error applying global snooze: $e');
      // Make sure to refresh UI state in case of error
      await loadReminders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }  // Disable global snooze
  Future<void> disableGlobalSnooze() async {
    if (_settingsService == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Disable global snooze in settings
      await _settingsService!.disableGlobalSnooze();
      
      // Get the list of reminders that were snoozed by global snooze
      List<String> globalSnoozedReminderIds = _settingsService!.getGlobalSnoozedReminderIds();
      
      // Reset only the reminders that were snoozed by global snooze
      for (final id in globalSnoozedReminderIds) {
        final reminder = _reminderService.getReminderById(id);
        if (reminder != null && reminder.status == ReminderStatus.snoozed) {
          await _reminderService.resetFromSnooze(id);
        }
      }
      
      // Clear the list now that we've reset those reminders
      await _settingsService!.clearGlobalSnoozedReminderIds();
      
      // Update UI state immediately for better responsiveness
      for (final reminder in _reminders) {
        if (globalSnoozedReminderIds.contains(reminder.id) && 
            reminder.status == ReminderStatus.snoozed) {
          reminder.status = ReminderStatus.active;
          reminder.snoozeMinutes = null;
          reminder.updateNextTrigger();
        }
      }
      
      // Notify UI immediately
      notifyListeners();
      
      // Reload reminders to update UI with the reset reminders
      await loadReminders();
      
      // Reschedule active reminders that were just reset
      final remindersToReschedule = _reminders.where((r) => 
        globalSnoozedReminderIds.contains(r.id) || r.status == ReminderStatus.active
      ).toList();
      
      try {
        await _notificationService.rescheduleAllReminders(remindersToReschedule);
      } catch (e) {
        print('Error rescheduling reminders after disabling global snooze: $e');
        // Continue execution even if notification rescheduling fails
      }
      
      // Final reload to ensure UI is fully updated
      await loadReminders();
    } catch (e) {
      print('Error disabling global snooze: $e');
      // Make sure to refresh UI state in case of error
      await loadReminders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Check if global snooze is enabled
  bool isGlobalSnoozed() {
    return _settingsService?.isGlobalSnoozed() ?? false;
  }
  
  // Get global snooze end time
  DateTime? getGlobalSnoozeEndTime() {
    return _settingsService?.getGlobalSnoozeEndTime();
  }
}
