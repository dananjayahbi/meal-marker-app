import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/background_service.dart';
import 'widgets/app_lifecycle_observer.dart';
import 'services/reminder_service.dart';
import 'services/notification_service.dart';
import 'services/app_state_provider.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';
import 'utils/hive_config.dart';

// Create a global NavigatorKey for notifications to use for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize Hive adapters - MUST happen before any Hive box is opened
  await HiveConfig.init();
  
  // Initialize services
  final reminderService = ReminderService();
  await reminderService.init();
  
  final settingsService = SettingsService();
  await settingsService.init();
  
  final notificationService = NotificationService();
  await notificationService.init(settingsService: settingsService);
    // Initialize and start background service
  final backgroundService = BackgroundService.instance;
  await backgroundService.initialize(settingsService: settingsService);
  backgroundService.startPeriodicCheck();
  
  // Run the app
  runApp(MyApp(
    reminderService: reminderService,
    notificationService: notificationService,
    settingsService: settingsService,
  ));
}

class MyApp extends StatelessWidget {
  final ReminderService reminderService;
  final NotificationService notificationService;
  final SettingsService settingsService;
  
  const MyApp({
    super.key,
    required this.reminderService,
    required this.notificationService,
    required this.settingsService,
  });  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateProvider(
        reminderService, 
        notificationService,
        settingsService: settingsService
      ),
      child: AppLifecycleObserver(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Meal Reminder',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: HomeScreen(settingsService: settingsService),
        ),
      ),
    );
  }

}
