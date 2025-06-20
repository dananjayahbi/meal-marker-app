import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_reminder.dart';
import '../services/app_state_provider.dart';
import '../utils/date_utils.dart' as meal_date_utils;
import 'add_edit_reminder_screen.dart';

class ReminderDetailsScreen extends StatelessWidget {
  final String reminderId;

  const ReminderDetailsScreen({super.key, required this.reminderId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final reminder = provider.getReminderById(reminderId);
        
        if (reminder == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reminder Details')),
            body: const Center(child: Text('Reminder not found')),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reminder Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _navigateToEditScreen(context, reminder),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context, provider, reminder),
                tooltip: 'Delete',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(reminder),
                  const SizedBox(height: 24),
                  _buildDetailsCard(context, reminder),
                  const SizedBox(height: 16),
                  _buildScheduleCard(reminder),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, provider, reminder),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(MealReminder reminder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reminder.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reminder.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            reminder.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildDetailsCard(BuildContext context, MealReminder reminder) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Status',
              _getStatusText(reminder.status),
              _getStatusIcon(reminder.status),
              _getStatusColor(reminder.status),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              'Created',
              meal_date_utils.DateUtils.formatDateTime(reminder.createdAt),
              Icons.create,
              Colors.grey,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              'Last Updated',
              meal_date_utils.DateUtils.formatDateTime(reminder.updatedAt),
              Icons.update,
              Colors.grey,
            ),
            if (reminder.lastTriggered != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                context,
                'Last Triggered',
                meal_date_utils.DateUtils.formatDateTime(reminder.lastTriggered!),
                Icons.notifications_active,
                Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildScheduleCard(MealReminder reminder) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildScheduleRow(
              'Time',
              meal_date_utils.DateUtils.formatDateTime(reminder.time),
              Icons.access_time,
            ),
            
            const Divider(height: 24),
            _buildScheduleRow(
              'Type',
              reminder.isRecurring ? 'Recurring' : 'One-time',
              reminder.isRecurring ? Icons.repeat : Icons.event,
            ),
            
            if (reminder.isRecurring && reminder.period != null) ...[
              const Divider(height: 24),
              _buildScheduleRow(
                'Repeat Every',
                _formatPeriod(reminder.period!),
                Icons.refresh,
              ),
            ],
            
            const Divider(height: 24),
            _buildScheduleRow(
              'Next Trigger',
              reminder.nextTrigger != null
                  ? meal_date_utils.DateUtils.formatDateTime(reminder.nextTrigger!)
                  : 'Not scheduled',
              Icons.event_available,
            ),
            
            if (reminder.nextTrigger != null) ...[
              const Divider(height: 24),
              _buildScheduleRow(
                'Time Remaining',
                meal_date_utils.DateUtils.formatTimeRemaining(reminder.nextTrigger!),
                Icons.hourglass_bottom,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, AppStateProvider provider, MealReminder reminder) {
    if (reminder.status == ReminderStatus.dismissed) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reminder.status != ReminderStatus.snoozed) ...[
          ElevatedButton.icon(
            onPressed: () => _showSnoozeDialog(context, provider, reminder),
            icon: const Icon(Icons.snooze),
            label: const Text('Snooze'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),        ] else ...[
          ElevatedButton.icon(
            onPressed: () {
              provider.resetSnooze(reminder.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.restore),
            label: const Text('Reset Snooze'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        ElevatedButton.icon(
          onPressed: () {
            provider.markReminderTriggered(reminder.id);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.done_all),
          label: Text(reminder.isRecurring ? 'Mark as Done for Now' : 'Mark as Done'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildScheduleRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getStatusText(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.active:
        return 'Active';
      case ReminderStatus.snoozed:
        return 'Snoozed';
      case ReminderStatus.dismissed:
        return 'Completed';
    }
  }
  
  IconData _getStatusIcon(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.active:
        return Icons.notifications_active;
      case ReminderStatus.snoozed:
        return Icons.snooze;
      case ReminderStatus.dismissed:
        return Icons.done_all;
    }
  }
  
  Color _getStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.active:
        return Colors.blue;
      case ReminderStatus.snoozed:
        return Colors.orange;
      case ReminderStatus.dismissed:
        return Colors.green;
    }
  }
  
  String _formatPeriod(Duration period) {
    if (period.inHours < 24) {
      return '${period.inHours} hour${period.inHours > 1 ? 's' : ''}';
    } else {
      final days = period.inDays;
      return '$days day${days > 1 ? 's' : ''}';
    }
  }
  
  void _navigateToEditScreen(BuildContext context, MealReminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditReminderScreen(reminderId: reminder.id),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, AppStateProvider provider, MealReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteReminder(reminder.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
    void _showSnoozeDialog(BuildContext context, AppStateProvider provider, MealReminder reminder) {
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
              children: [
                // Regular timed snooze options
                ...snoozeOptions.map((minutes) => ActionChip(
                  label: Text('$minutes min'),
                  onPressed: () {
                    provider.snoozeReminder(reminder.id, minutes);
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to previous screen
                  },
                )),
                
                // Infinite snooze option
                ActionChip(
                  label: const Text('Infinite'),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  onPressed: () {
                    // Use 0 minutes to indicate infinite snooze
                    provider.snoozeReminder(reminder.id, 0);
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to previous screen
                  },
                ),
              ],
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
