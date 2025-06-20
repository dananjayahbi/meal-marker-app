import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_reminder.dart';
import '../services/app_state_provider.dart';
import '../utils/date_utils.dart' as meal_date_utils;
import '../utils/constants.dart';

class ReminderListItem extends StatelessWidget {
  final MealReminder reminder;
  final bool showHistory;
  final VoidCallback onTap;

  const ReminderListItem({
    super.key,
    required this.reminder,
    this.showHistory = false,
    required this.onTap,
  });

  @override  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLeadingIcon(context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reminder.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            reminder.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),                  if (!showHistory && reminder.status == ReminderStatus.active &&
                      !Provider.of<AppStateProvider>(context, listen: false).isGlobalSnoozed()) 
                    _buildPopupMenu(context),
                ],
              ),
              const SizedBox(height: 8),
              _buildTimeInfo(context),
              if (reminder.isRecurring) ...[
                const SizedBox(height: 4),
                _buildRecurrenceInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }  Widget _buildLeadingIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    if (showHistory) {
      iconData = Icons.done;
      iconColor = Colors.green;
    } else if (reminder.status == ReminderStatus.snoozed) {
      iconData = Icons.snooze;
      iconColor = Colors.orange;
    } else {
      // Check for global snooze
      bool isGlobalSnoozed = false;
      try {
        isGlobalSnoozed = Provider.of<AppStateProvider>(
          context,
          listen: false
        ).isGlobalSnoozed();
      } catch (_) {
        // If provider is not available, default to false
      }
      
      if (isGlobalSnoozed) {
        iconData = Icons.snooze;
        iconColor = Colors.orange;
      } else {
        iconData = Icons.notifications_active;
        iconColor = Colors.blue;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
    Widget _buildTimeInfo(BuildContext context) {
    if (showHistory && reminder.lastTriggered != null) {
      return Row(
        children: [
          const Icon(Icons.event_available, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            'Triggered ${meal_date_utils.DateUtils.formatDateTime(reminder.lastTriggered!)}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      );
    }
      
    // Check for global snooze - do this here to avoid having to pass context down further
    bool isGlobalSnoozed = false;
    try {
      isGlobalSnoozed = Provider.of<AppStateProvider>(context, listen: false).isGlobalSnoozed();
    } catch (_) {
      // If provider is not available, default to false
    }
      
    if (reminder.status == ReminderStatus.snoozed || 
        (isGlobalSnoozed && reminder.status == ReminderStatus.active)) {
      if (reminder.nextTrigger == null) {
        // Infinite snooze
        return Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Snoozed indefinitely',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      } else {
        // Timed snooze
        return Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Snoozed until ${meal_date_utils.DateUtils.formatDateTime(reminder.nextTrigger!)}',
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        );
      }
    }    // Check if we need to display this reminder as snoozed due to global snooze
    if (isGlobalSnoozed && reminder.status == ReminderStatus.active) {
      // Show as snoozed due to global snooze
      final globalSnoozeEndTime = Provider.of<AppStateProvider>(context, listen: false).getGlobalSnoozeEndTime();
      
      if (globalSnoozeEndTime == null) {
        // Infinite global snooze
        return Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            const Text(
              'Snoozed indefinitely (global)',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      } else {
        // Timed global snooze
        return Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Snoozed until ${meal_date_utils.DateUtils.formatDateTime(globalSnoozeEndTime)} (global)',
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        );
      }
    }
    
    // Regular active reminder display
    return Row(
      children: [
        const Icon(Icons.access_time, size: 16, color: Colors.blue),
        const SizedBox(width: 4),
        Text(
          reminder.nextTrigger != null
              ? meal_date_utils.DateUtils.formatDateTime(reminder.nextTrigger!)
              : meal_date_utils.DateUtils.formatDateTime(reminder.time),
          style: const TextStyle(color: Colors.blue),
        ),
      ],
    );
  }
  
  Widget _buildRecurrenceInfo() {
    String recurrenceText = 'Recurring';
    
    if (reminder.period != null) {
      if (reminder.period!.inHours < 24) {
        recurrenceText = 'Every ${reminder.period!.inHours} hour${reminder.period!.inHours > 1 ? 's' : ''}';
      } else {
        final days = reminder.period!.inDays;
        recurrenceText = 'Every $days day${days > 1 ? 's' : ''}';
      }
    }
    
    return Row(
      children: [
        const Icon(Icons.repeat, size: 16, color: Colors.purple),
        const SizedBox(width: 4),
        Text(
          recurrenceText,
          style: const TextStyle(color: Colors.purple),
        ),
      ],
    );
  }
  
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuItemSelected(value, context),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'snooze',
          child: Row(
            children: [
              Icon(Icons.snooze),
              SizedBox(width: 8),
              Text('Snooze'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'mark-done',
          child: Row(
            children: [
              Icon(Icons.done),
              SizedBox(width: 8),
              Text('Mark as Done'),
            ],
          ),
        ),
      ],
    );
  }
  
  void _handleMenuItemSelected(String value, BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    
    switch (value) {
      case 'snooze':
        _showSnoozeDialog(context, provider);
        break;
      case 'mark-done':
        provider.markReminderTriggered(reminder.id);
        break;
    }
  }
  
  void _showSnoozeDialog(BuildContext context, AppStateProvider provider) {
    final snoozeOptions = [5, 10, 15, 30, 60];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Snooze for how long?'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: snoozeOptions.map((minutes) => ActionChip(
                label: Text('$minutes min'),
                onPressed: () {
                  Navigator.pop(context);
                  provider.snoozeReminder(reminder.id, minutes);
                },
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
}
