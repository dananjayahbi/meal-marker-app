import 'package:flutter/material.dart';
import '../services/background_service.dart';

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleObserver({Key? key, required this.child}) : super(key: key);

  @override
  AppLifecycleObserverState createState() => AppLifecycleObserverState();
}

class AppLifecycleObserverState extends State<AppLifecycleObserver> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final backgroundService = BackgroundService.instance;
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in the foreground and visible to the user
        // We can stop the background service's frequent checks since the app will handle them
        backgroundService.stopPeriodicCheck();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (for example, the user switched to another app)
        break;
      case AppLifecycleState.paused:
        // App is in the background but still loaded
        // Start the background service's periodic checks
        backgroundService.startPeriodicCheck();
        break;
      case AppLifecycleState.detached:
        // App is suspended completely (not loaded in memory)
        // The background service should continue running
        backgroundService.startPeriodicCheck();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
