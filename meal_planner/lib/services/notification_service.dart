import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/meal_reminder.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  SettingsService? _settingsService;
    // Initialize notification plugin
  Future<void> init({SettingsService? settingsService}) async {
    if (_isInitialized) return;
    
    _settingsService = settingsService;
    
    // Skip initialization on web platform where the plugin is not supported
    if (kIsWeb) {
      print('Skipping notification initialization on web platform');
      _isInitialized = true;
      return;
    }
    
    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
          
      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
          
      // Initialize settings
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Initialize the plugin
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTapped,
      );
  
      // Create notification channel for Android
      await _createNotificationChannel();
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
      // Mark as initialized to prevent further initialization attempts
      _isInitialized = true;
    }
  }
  
  // Create the notification channel for Android
  Future<void> _createNotificationChannel() async {
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
  
  // Handle notification tap
  void onNotificationTapped(NotificationResponse response) {
    // This will be used to navigate to the reminder detail screen when a notification is tapped
    // Implementation will depend on navigation setup
    print('Notification tapped: ${response.payload}');
    
    // TODO: Add navigation logic based on payload (reminder ID)
  }  // Schedule a notification for a reminder
  Future<void> scheduleReminderNotification(MealReminder reminder) async {
    if (!_isInitialized) await init();
    
    // Skip on web platform
    if (kIsWeb) {
      print('Skipping notification scheduling on web platform');
      return;
    }
    
    // For infinite snooze reminders, don't schedule notifications
    if (reminder.status == ReminderStatus.snoozed && reminder.nextTrigger == null) {
      print('Cannot schedule notification: reminder is infinitely snoozed');
      return;
    }
    
    if (reminder.nextTrigger == null) {
      print('Cannot schedule notification: nextTrigger is null');
      return;
    }
    
    // Check if global snooze is active
    if (_settingsService != null && _settingsService!.isGlobalSnoozed()) {
      print('Skipping notification schedule due to global snooze being active');
      return;
    }
    
    // Check if this notification would trigger during sleep hours
    if (_settingsService != null && 
        _settingsService!.isInSleepPeriod(reminder.nextTrigger!)) {
      print('Skipping notification schedule as it falls during sleep hours');
      return;
    }
    
    try {
      // Check if the reminder's next trigger time is in the past
      if (reminder.nextTrigger!.isBefore(DateTime.now())) {
        // For past reminders, trigger the notification immediately
        await showReminderNotification(reminder);
      } else {
        // For future reminders, schedule the notification
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
          // Convert DateTime to TZDateTime
        final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
          reminder.nextTrigger!, 
          tz.local,
        );
          await _notificationsPlugin.zonedSchedule(
          notificationId,
          reminder.title,
          reminder.description,
          scheduledDate,
          notificationDetails,
          matchDateTimeComponents: DateTimeComponents.time,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: reminder.id, // Use reminder ID as payload for identification when tapped
        );
        
        print('Scheduled notification for reminder: ${reminder.title} at ${reminder.nextTrigger}');
      }
    } catch (e) {
      print('Error scheduling notification for reminder ${reminder.title}: $e');
    }
  }
  // Show notification immediately
  Future<void> showReminderNotification(MealReminder reminder) async {
    if (!_isInitialized) await init();
    
    // Skip on web platform
    if (kIsWeb) {
      print('Skipping showing notification on web platform');
      return;
    }
    
    // Check if global snooze is active
    if (_settingsService != null && _settingsService!.isGlobalSnoozed()) {
      print('Skipping notification due to global snooze being active');
      return;
    }
    
    // Check if this notification would trigger during sleep hours
    if (_settingsService != null && 
        _settingsService!.isInSleepPeriod(DateTime.now())) {
      print('Skipping notification as current time is during sleep hours');
      return;
    }
    
    try {
      // Vibrate with the specified pattern
      await _vibrate(reminder.vibrationPattern);
      
      // Create notification details
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
        payload: reminder.id, // Use reminder ID as payload for identification when tapped
      );
      
      print('Showed notification for reminder: ${reminder.title}');
    } catch (e) {
      print('Error showing notification for reminder ${reminder.title}: $e');
    }
  }
    // Vibrate the device with the specified pattern
  Future<void> _vibrate(List<int> pattern) async {
    try {
      // Skip vibration on web
      if (kIsWeb) {
        print('Skipping vibration on web platform');
        return;
      }
      
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (e) {
      print('Error during vibration: $e');
    }
  }
    // Cancel a scheduled notification
  Future<void> cancelNotification(MealReminder reminder) async {
    if (!_isInitialized) await init();
    
    // Skip on web platform
    if (kIsWeb) {
      print('Skipping notification cancellation on web platform');
      return;
    }
    
    try {
      final int notificationId = NotificationIds.reminderBase + reminder.id.hashCode.abs();
      await _notificationsPlugin.cancel(notificationId);
      
      print('Cancelled notification for reminder: ${reminder.title}');
    } catch (e) {
      print('Error cancelling notification for reminder ${reminder.title}: $e');
    }
  }
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await init();
    
    // Skip on web platform
    if (kIsWeb) {
      print('Skipping notification cancellation on web platform');
      return;
    }
    
    try {
      await _notificationsPlugin.cancelAll();
      print('Cancelled all notifications');
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }
    // Reschedule all active reminders
  Future<void> rescheduleAllReminders(List<MealReminder> reminders) async {
    if (!_isInitialized) await init();
    
    // Skip on web platform
    if (kIsWeb) {
      print('Skipping notification rescheduling on web platform');
      return;
    }
    
    try {
      // First cancel all existing notifications
      await cancelAllNotifications();
      
      // Then reschedule all active reminders
      for (final reminder in reminders) {
        if (reminder.status == ReminderStatus.active ||
            reminder.status == ReminderStatus.snoozed) {
          try {
            await scheduleReminderNotification(reminder);
          } catch (e) {
            print('Error scheduling notification for reminder ${reminder.id}: $e');
            // Continue with next reminder
          }
        }
      }
      
      print('Rescheduled all reminders');
    } catch (e) {
      print('Error rescheduling reminders: $e');
    }
  }
}
