import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_reminder.dart';
import '../services/app_state_provider.dart';
import '../services/settings_service.dart';
import '../utils/date_utils.dart' as meal_date_utils;
import 'add_edit_reminder_screen.dart';
import 'reminder_details_screen.dart';
import 'settings_screen.dart';
import '../widgets/reminder_list_item.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settingsService;
  
  const HomeScreen({
    super.key,
    required this.settingsService,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load reminders when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppStateProvider>(context, listen: false).loadReminders();
      
      // Check for any reminders that need to be triggered
      Provider.of<AppStateProvider>(context, listen: false).checkAndTriggerReminders();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Reminders'),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    settingsService: widget.settingsService,
                  ),
                ),
              );
            },
          ),
          // Stats button
          IconButton(
            icon: const Icon(Icons.insert_chart),
            onPressed: () => _showStats(context),
            tooltip: 'Statistics',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Active reminders tab
              _buildActiveRemindersTab(provider),
              
              // History tab
              _buildHistoryTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Add Reminder',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildActiveRemindersTab(AppStateProvider provider) {
    final activeReminders = provider.getActiveReminders();
    final snoozedReminders = provider.getSnoozedReminders();
    
    if (activeReminders.isEmpty && snoozedReminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No active reminders',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToAddEditScreen(context),
              child: const Text('Create a reminder'),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      children: [
        // Snoozed reminders section
        if (snoozedReminders.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Snoozed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...snoozedReminders.map((reminder) => ReminderListItem(
            reminder: reminder,
            onTap: () => _navigateToDetailsScreen(context, reminder),
          )),
          const Divider(height: 32, thickness: 1),
        ],
        
        // Active reminders section
        if (activeReminders.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...activeReminders.map((reminder) => ReminderListItem(
            reminder: reminder,
            onTap: () => _navigateToDetailsScreen(context, reminder),
          )),
        ],
      ],
    );
  }
  
  Widget _buildHistoryTab(AppStateProvider provider) {
    final history = provider.getReminderHistory();
    
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reminder history yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    // Group history by date
    final Map<String, List<MealReminder>> groupedHistory = {};
    
    for (final reminder in history) {
      final dateKey = meal_date_utils.DateUtils.formatDate(
          reminder.lastTriggered ?? reminder.createdAt);
      
      if (!groupedHistory.containsKey(dateKey)) {
        groupedHistory[dateKey] = [];
      }
      
      groupedHistory[dateKey]!.add(reminder);
    }
    
    return ListView(
      children: [
        for (final entry in groupedHistory.entries) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...entry.value.map((reminder) => ReminderListItem(
            reminder: reminder,
            showHistory: true,
            onTap: () => _navigateToDetailsScreen(context, reminder),
          )),
          if (entry.key != groupedHistory.keys.last)
            const Divider(height: 32, thickness: 1),
        ],
      ],
    );
  }
  
  void _navigateToAddEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditReminderScreen(),
      ),
    );
  }
  
  void _navigateToDetailsScreen(BuildContext context, MealReminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailsScreen(reminderId: reminder.id),
      ),
    );
  }
  
  void _showStats(BuildContext context) {
    final stats = Provider.of<AppStateProvider>(context, listen: false).getStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow('Total reminders:', '${stats['total']}'),
            _statRow('Active:', '${stats['active']}'),
            _statRow('Snoozed:', '${stats['snoozed']}'),
            _statRow('Completed:', '${stats['dismissed']}'),
            _statRow('One-time:', '${stats['one_time']}'),
            _statRow('Recurring:', '${stats['recurring']}'),
            _statRow(
              'Avg meals/day:',
              (stats['avg_meals_per_day'] as double).toStringAsFixed(1),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
  
  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
