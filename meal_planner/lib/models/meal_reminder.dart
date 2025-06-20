import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// The part statement is commented out until we set up build_runner
// part 'meal_reminder.g.dart';

enum ReminderStatus { active, snoozed, dismissed }

@HiveType(typeId: 0)
class MealReminder {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime time;

  @HiveField(4)
  bool isRecurring;

  @HiveField(5)
  Duration? period;

  @HiveField(6)
  List<int> vibrationPattern;

  @HiveField(7)
  ReminderStatus status;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  DateTime? lastTriggered;

  @HiveField(11)
  DateTime? nextTrigger;

  @HiveField(12)
  int? snoozeMinutes;

  MealReminder({
    String? id,
    required this.title,
    required this.description,
    required this.time,
    this.isRecurring = false,
    this.period,
    this.vibrationPattern = const [500, 1000, 500],
    this.status = ReminderStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastTriggered,
    this.nextTrigger,
    this.snoozeMinutes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calculate the next trigger time based on current time and recurrence pattern
  void updateNextTrigger() {
    if (isRecurring && period != null) {
      // If it's a recurring reminder, calculate when it should next occur
      final DateTime now = DateTime.now();
      
      // If the current time is already past the scheduled time
      if (now.isAfter(time)) {
        // Calculate how many periods have passed
        final difference = now.difference(time);
        final periods = (difference.inMicroseconds / period!.inMicroseconds).ceil();
        
        // Set next trigger to the next occurrence after now
        nextTrigger = time.add(period! * periods);
      } else {
        // If time is still in the future, that's the next trigger
        nextTrigger = time;
      }
    } else {
      // If it's a one-time reminder, the next trigger is just the specified time
      nextTrigger = time;
    }
  }

  // Mark the reminder as triggered
  void markTriggered() {
    lastTriggered = DateTime.now();
    if (isRecurring && period != null) {
      // For recurring reminders, update the next trigger time
      nextTrigger = lastTriggered!.add(period!);
    } else {
      // For one-time reminders, mark as dismissed after being triggered
      status = ReminderStatus.dismissed;
    }
    updatedAt = DateTime.now();
  }
  // Snooze the reminder for specified minutes
  void snooze(int minutes) {
    status = ReminderStatus.snoozed;
    snoozeMinutes = minutes;
    
    // If minutes is 0 or negative, it means infinite snooze (no end time)
    if (minutes <= 0) {
      // For infinite snooze, set nextTrigger to null
      nextTrigger = null;
    } else {
      nextTrigger = DateTime.now().add(Duration(minutes: minutes));
    }
    updatedAt = DateTime.now();
  }

  // Reset from snooze to active
  void resetFromSnooze() {
    status = ReminderStatus.active;
    snoozeMinutes = null;
    updatedAt = DateTime.now();
    updateNextTrigger();
  }

  // Create a copy of this reminder with updated fields
  MealReminder copyWith({
    String? title,
    String? description,
    DateTime? time,
    bool? isRecurring,
    Duration? period,
    List<int>? vibrationPattern,
    ReminderStatus? status,
    DateTime? updatedAt,
    DateTime? lastTriggered,
    DateTime? nextTrigger,
    int? snoozeMinutes,
  }) {
    return MealReminder(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      isRecurring: isRecurring ?? this.isRecurring,
      period: period ?? this.period,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastTriggered: lastTriggered ?? this.lastTriggered,
      nextTrigger: nextTrigger ?? this.nextTrigger,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }
}
