import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal_reminder.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/hive_config.dart';

// This service will run in the background to check for reminders that need to be triggered
class BackgroundService {
  static BackgroundService? _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _isInitialized = false;
  SettingsService? _settingsService;

  // Singleton pattern
  BackgroundService._();
  
  static BackgroundService get instance {
    _instance ??= BackgroundService._();
    return _instance!;
  }
    Future<void> initialize({SettingsService? settingsService}) async {
    if (_isInitialized) return;

    _settingsService = settingsService;
    
    // Initialize notifications
    await _initializeNotifications();
    // Initialize Hive if needed
    if (!Hive.isAdapterRegistered(0)) {
      await Hive.initFlutter();
      await HiveConfig.init();
    }
    
    // Open the reminders box if it's not already open
    if (!Hive.isBoxOpen(HiveBoxes.reminders)) {
      await Hive.openBox<MealReminder>(HiveBoxes.reminders);
    }
    
    _isInitialized = true;
  }
  
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      NotificationChannels.mealRemindersChannel,
      NotificationChannels.mealRemindersChannelName,
      description: NotificationChannels.mealRemindersChannelDescription,
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Start a periodic timer to check for reminders
  void startPeriodicCheck() {
    // Check every minute
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkAndTriggerReminders();
    });
    
    // Also check immediately
    checkAndTriggerReminders();
  }
  
  // Stop the periodic timer
  void stopPeriodicCheck() {
    _timer?.cancel();
    _timer = null;
  }
    // Check for reminders that need to be triggered
  Future<void> checkAndTriggerReminders() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final box = Hive.box<MealReminder>(HiveBoxes.reminders);
      final now = DateTime.now();
      
      // Check if global snooze is active
      if (_settingsService != null && _settingsService!.isGlobalSnoozed()) {
        print('Skipping reminder check due to global snooze being active');
        return;
      }
      
      // Check if current time is during sleep hours
      if (_settingsService != null && _settingsService!.isInSleepPeriod(now)) {
        print('Skipping reminder check as current time is during sleep hours');
        return;
      }
      
      // Find reminders that need to be triggered
      final remindersToTrigger = box.values
          .where((reminder) => 
              reminder.status == ReminderStatus.active && 
              reminder.nextTrigger != null &&
              reminder.nextTrigger!.isBefore(now))
          .toList();
      
      // Show notifications for each reminder
      for (final reminder in remindersToTrigger) {
        await _showNotification(reminder);
        
        // Update the reminder status
        if (reminder.isRecurring && reminder.period != null) {
          // For recurring reminders, update the next trigger time
          reminder.markTriggered();
          await box.put(reminder.id, reminder);
        } else {
          // For one-time reminders, mark as dismissed
          reminder.status = ReminderStatus.dismissed;
          reminder.updatedAt = DateTime.now();
          await box.put(reminder.id, reminder);
        }
      }
    } catch (e) {
      print('Error checking reminders: $e');
    }
  }
  
  // Show a notification for a reminder
  Future<void> _showNotification(MealReminder reminder) async {
    try {
      // Vibrate with the specified pattern
      // Note: We can't use the Vibration plugin in the background service,
      // so we'll rely on the notification's default vibration
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        NotificationChannels.mealRemindersChannel,
        NotificationChannels.mealRemindersChannelName,
        channelDescription: NotificationChannels.mealRemindersChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Meal Reminder',
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Create unique notification ID based on reminder ID
      final int notificationId = NotificationIds.reminderBase + reminder.id.hashCode.abs();
      
      await _notificationsPlugin.show(
        notificationId,
        reminder.title,
        reminder.description,
        notificationDetails,
        payload: reminder.id,
      );
      
      print('Showed notification for reminder: ${reminder.title}');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
}
