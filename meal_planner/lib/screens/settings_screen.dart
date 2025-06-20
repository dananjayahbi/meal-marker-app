import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../services/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsScreen({
    super.key,
    required this.settingsService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    _settings = widget.settingsService.getSettings();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sleep Mode Section
                  _buildSectionTitle('Sleep Mode'),
                  _buildSleepModeSwitch(),
                  if (_settings.sleepModeEnabled)
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildSleepTimeSettings(),
                      ],
                    ),
                  const Divider(height: 32),

                  // Global Snooze Section
                  _buildSectionTitle('Global Snooze'),
                  _buildGlobalSnoozeStatus(),
                  const SizedBox(height: 16),
                  _buildGlobalSnoozeActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildSleepModeSwitch() {
    return SwitchListTile(
      title: const Text('Enable Sleep Mode'),
      subtitle: const Text(
          'No notifications will be sent during your sleep hours'),
      value: _settings.sleepModeEnabled,
      onChanged: (value) async {
        await widget.settingsService.toggleSleepMode(value);
        await _loadSettings();
      },
    );
  }

  Widget _buildSleepTimeSettings() {
    final startTime = TimeOfDay.fromDateTime(_settings.sleepStartTime!);
    final endTime = TimeOfDay.fromDateTime(_settings.sleepEndTime!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          ListTile(
            title: const Text('Sleep Start Time'),
            subtitle: Text(startTime.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: startTime,
              );

              if (newTime != null) {
                final now = DateTime.now();
                final newDateTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  newTime.hour,
                  newTime.minute,
                );

                await widget.settingsService.updateSleepTimes(
                  newDateTime,
                  _settings.sleepEndTime!,
                );
                await _loadSettings();
              }
            },
          ),
          ListTile(
            title: const Text('Sleep End Time'),
            subtitle: Text(endTime.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: endTime,
              );

              if (newTime != null) {
                final now = DateTime.now();
                final newDateTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  newTime.hour,
                  newTime.minute,
                );

                await widget.settingsService.updateSleepTimes(
                  _settings.sleepStartTime!,
                  newDateTime,
                );
                await _loadSettings();
              }
            },
          ),
        ],
      ),
    );
  }
  Widget _buildGlobalSnoozeStatus() {
    if (!_settings.globalSnoozeEnabled) {
      return const Text('Global snooze is currently disabled.');
    }

    final snoozeEnd = _settings.globalSnoozeUntil;
    if (snoozeEnd == null) {
      // This is an infinite snooze
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'All reminders are currently snoozed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Infinite snooze until manually reset',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    if (now.isAfter(snoozeEnd)) {
      return const Text('Global snooze has expired.');
    }

    final minutes = snoozeEnd.difference(now).inMinutes;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'All reminders are currently snoozed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Snooze will end in: $minutes minutes',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSnoozeActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [        if (_settings.globalSnoozeEnabled)
          ElevatedButton(
            onPressed: () async {
              // Use app state provider to properly handle UI updates
              final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
              await appStateProvider.disableGlobalSnooze();
              await _loadSettings();
            },
            child: const Text('Disable Global Snooze'),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Snooze all reminders for:'),
              const SizedBox(height: 8),              Wrap(
                spacing: 8.0,
                children: [
                  _buildSnoozeButton(15),
                  _buildSnoozeButton(30),
                  _buildSnoozeButton(60),
                  _buildSnoozeButton(120),
                  _buildSnoozeButton(0, isInfinite: true),
                ],
              ),
            ],
          ),
      ],
    );
  }  Widget _buildSnoozeButton(int minutes, {bool isInfinite = false}) {
    return ElevatedButton(
      onPressed: () async {
        // Update app state provider to properly handle UI updates
        final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
        await appStateProvider.applyGlobalSnooze(minutes);
        await _loadSettings();
      },
      child: Text(isInfinite ? 'Infinite' : '$minutes min'),
    );
  }
}
