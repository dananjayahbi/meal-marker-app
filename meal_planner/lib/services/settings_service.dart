import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';

class SettingsService {
  late Box<AppSettings> _settingsBox;
  late AppSettings _settings;

  // Initialize the service
  Future<void> init() async {
    // The AppSettings adapter is already registered in HiveConfig.init()
    
    // Open the settings box
    _settingsBox = await Hive.openBox<AppSettings>(HiveBoxes.settings);
    
    // Load settings or create default if none exists
    if (_settingsBox.isEmpty) {
      _settings = AppSettings.defaultSettings();
      await _settingsBox.put('app_settings', _settings);
    } else {
      _settings = _settingsBox.get('app_settings')!;
    }
  }
  
  // Get current settings
  AppSettings getSettings() {
    return _settings;
  }
  
  // Save settings
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    await _settingsBox.put('app_settings', settings);
  }
  
  // Check if a specific time is within sleep hours
  bool isInSleepPeriod(DateTime dateTime) {
    return _settings.isInSleepPeriod(dateTime);
  }
  
  // Toggle sleep mode
  Future<void> toggleSleepMode(bool enabled) async {
    _settings.sleepModeEnabled = enabled;
    await saveSettings(_settings);
  }
  
  // Update sleep times
  Future<void> updateSleepTimes(DateTime startTime, DateTime endTime) async {
    _settings.sleepStartTime = startTime;
    _settings.sleepEndTime = endTime;
    await saveSettings(_settings);
  }
  // Enable global snooze for all reminders
  Future<void> enableGlobalSnooze(int minutes) async {
    // If minutes is 0 or negative, it means infinite snooze
    DateTime? snoozeUntil;
    if (minutes > 0) {
      snoozeUntil = DateTime.now().add(Duration(minutes: minutes));
    }
    
    _settings.globalSnoozeEnabled = true;
    _settings.globalSnoozeUntil = snoozeUntil;
    _settings.globalSnoozeMinutes = minutes;
    await saveSettings(_settings);
  }
  
  // Add a reminder ID to the list of reminders snoozed by global snooze
  Future<void> addGlobalSnoozedReminderId(String id) async {
    if (!_settings.globalSnoozedReminderIds.contains(id)) {
      _settings.globalSnoozedReminderIds.add(id);
      await saveSettings(_settings);
    }
  }
    // Add multiple reminder IDs to the list of reminders snoozed by global snooze
  Future<void> addGlobalSnoozedReminderIds(List<String> ids) async {
    _settings.globalSnoozedReminderIds.addAll(ids);
    await saveSettings(_settings);
  }
  
  // Get list of reminder IDs that were snoozed by global snooze
  List<String> getGlobalSnoozedReminderIds() {
    return _settings.globalSnoozedReminderIds;
  }
  
  // Clear the list of reminder IDs that were snoozed by global snooze
  Future<void> clearGlobalSnoozedReminderIds() async {
    _settings.globalSnoozedReminderIds = [];
    await saveSettings(_settings);
  }
  
  // Disable global snooze
  Future<void> disableGlobalSnooze() async {
    _settings.globalSnoozeEnabled = false;
    _settings.globalSnoozeUntil = null;
    _settings.globalSnoozeMinutes = null;
    
    // Keep the list of snoozed reminders until we reset them
    // We'll clear this list after the reminders are reset
    
    await saveSettings(_settings);
  }
    // Check if reminders are globally snoozed
  bool isGlobalSnoozed() {
    if (!_settings.globalSnoozeEnabled) {
      return false;
    }
    
    // If snoozeUntil is null and snooze is enabled, it's an infinite snooze
    if (_settings.globalSnoozeUntil == null) {
      return true; // Infinite snooze
    }
    
    // Check if the snooze period has already expired
    if (DateTime.now().isAfter(_settings.globalSnoozeUntil!)) {
      // Auto-disable global snooze if it's expired
      _settings.globalSnoozeEnabled = false;
      _settingsBox.put('app_settings', _settings);
      return false;
    }
    
    return true;
  }
  
  // Get global snooze end time
  DateTime? getGlobalSnoozeEndTime() {
    return isGlobalSnoozed() ? _settings.globalSnoozeUntil : null;
  }
    // Check if the global snooze is infinite
  bool isGlobalSnoozeInfinite() {
    return _settings.globalSnoozeEnabled && _settings.globalSnoozeUntil == null;
  }
  
  // Get global snooze minutes (can be zero or negative for infinite)
  int? getGlobalSnoozeMinutes() {
    return _settings.globalSnoozeMinutes;
  }
}
