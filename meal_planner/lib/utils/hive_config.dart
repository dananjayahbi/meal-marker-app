import 'package:hive/hive.dart';
import '../models/meal_reminder.dart';
import '../models/app_settings.dart';

class HiveConfig {
  static Future<void> init() async {
    // Register adapter for ReminderStatus enum
    Hive.registerAdapter(_ReminderStatusAdapter());
    
    // Register adapter for Duration class
    Hive.registerAdapter(_DurationAdapter());
    
    // Register adapter for MealReminder model
    Hive.registerAdapter(MealReminderAdapter());
    
    // Register adapter for AppSettings model
    Hive.registerAdapter(AppSettingsAdapter());
  }
}

// Custom adapter for ReminderStatus enum since Hive can't auto-generate it
class _ReminderStatusAdapter extends TypeAdapter<ReminderStatus> {
  @override
  final typeId = 1;

  @override
  ReminderStatus read(BinaryReader reader) {
    return ReminderStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ReminderStatus obj) {
    writer.writeByte(obj.index);
  }
}

// Custom adapter for Duration class
class _DurationAdapter extends TypeAdapter<Duration> {
  @override
  final typeId = 2;

  @override
  Duration read(BinaryReader reader) {
    return Duration(microseconds: reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}

// Manual adapter for MealReminder until we can generate it with build_runner
class MealReminderAdapter extends TypeAdapter<MealReminder> {
  @override
  final int typeId = 0;

  @override
  MealReminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return MealReminder(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      time: fields[3] as DateTime,
      isRecurring: fields[4] as bool,
      period: fields[5] as Duration?,
      vibrationPattern: (fields[6] as List).cast<int>(),
      status: fields[7] as ReminderStatus,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      lastTriggered: fields[10] as DateTime?,
      nextTrigger: fields[11] as DateTime?,
      snoozeMinutes: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MealReminder obj) {
    writer.writeByte(13);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.title);
    writer.writeByte(2);
    writer.write(obj.description);
    writer.writeByte(3);
    writer.write(obj.time);
    writer.writeByte(4);
    writer.write(obj.isRecurring);
    writer.writeByte(5);
    writer.write(obj.period);
    writer.writeByte(6);
    writer.write(obj.vibrationPattern);
    writer.writeByte(7);
    writer.write(obj.status);
    writer.writeByte(8);
    writer.write(obj.createdAt);
    writer.writeByte(9);
    writer.write(obj.updatedAt);
    writer.writeByte(10);
    writer.write(obj.lastTriggered);
    writer.writeByte(11);
    writer.write(obj.nextTrigger);
    writer.writeByte(12);
    writer.write(obj.snoozeMinutes);
  }
}

// Manual adapter for AppSettings
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;
  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return AppSettings(
      sleepModeEnabled: fields[0] as bool,
      sleepStartTime: fields[1] as DateTime?,
      sleepEndTime: fields[2] as DateTime?,
      globalSnoozeEnabled: fields[3] as bool,
      globalSnoozeUntil: fields[4] as DateTime?,
      globalSnoozeMinutes: fields[5] as int?,
      globalSnoozedReminderIds: fields[6] != null ? (fields[6] as List).cast<String>() : [],
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.sleepModeEnabled);
    writer.writeByte(1);
    writer.write(obj.sleepStartTime);
    writer.writeByte(2);
    writer.write(obj.sleepEndTime);
    writer.writeByte(3);
    writer.write(obj.globalSnoozeEnabled);
    writer.writeByte(4);
    writer.write(obj.globalSnoozeUntil);
    writer.writeByte(5);
    writer.write(obj.globalSnoozeMinutes);
    writer.writeByte(6);
    writer.write(obj.globalSnoozedReminderIds);
  }
}
