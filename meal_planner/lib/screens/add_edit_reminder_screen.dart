import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_reminder.dart';
import '../services/app_state_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as meal_date_utils;

class AddEditReminderScreen extends StatefulWidget {
  final String? reminderId;

  const AddEditReminderScreen({super.key, this.reminderId});

  @override
  AddEditReminderScreenState createState() => AddEditReminderScreenState();
}

class AddEditReminderScreenState extends State<AddEditReminderScreen> {  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;
  MealReminder? _originalReminder;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _title = '';
  String _description = '';
  DateTime _selectedTime = DateTime.now().add(const Duration(minutes: 30));
  bool _isRecurring = false;
  String _recurrenceType = RecurrenceOptions.oneTime;
  int _customHours = 3;
  String _vibrationPattern = 'normal';
  @override
  void initState() {
    super.initState();
    _isEditing = widget.reminderId != null;
    
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReminderDetails();
      });
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
    void _loadReminderDetails() {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    _originalReminder = provider.getReminderById(widget.reminderId!);
    
    if (_originalReminder != null) {
      setState(() {
        _title = _originalReminder!.title;
        _description = _originalReminder!.description;
        _titleController.text = _originalReminder!.title;
        _descriptionController.text = _originalReminder!.description;
        _selectedTime = _originalReminder!.time;
        _isRecurring = _originalReminder!.isRecurring;
        
        // Determine recurrence type based on period
        if (!_isRecurring || _originalReminder!.period == null) {
          _recurrenceType = RecurrenceOptions.oneTime;
        } else if (_originalReminder!.period!.inHours == 1) {
          _recurrenceType = RecurrenceOptions.hourly;
        } else if (_originalReminder!.period!.inHours == 24) {
          _recurrenceType = RecurrenceOptions.daily;
        } else {
          _recurrenceType = RecurrenceOptions.custom;
          _customHours = _originalReminder!.period!.inHours;
        }
        
        // Determine vibration pattern based on the stored pattern
        final pattern = _originalReminder!.vibrationPattern;
        if (_listEquals(pattern, VibrationPatterns.gentle)) {
          _vibrationPattern = 'gentle';
        } else if (_listEquals(pattern, VibrationPatterns.intense)) {
          _vibrationPattern = 'intense';
        } else {
          _vibrationPattern = 'normal';
        }
      });
    }
  }
  
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Reminder' : 'Add Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) {
                  _description = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              _buildTimePicker(),
              const SizedBox(height: 16),
              _buildRecurrenceSection(),
              const SizedBox(height: 24),
              _buildVibrationSection(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isEditing ? 'Update Reminder' : 'Create Reminder',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimePicker() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text(
                  meal_date_utils.DateUtils.formatDateTime(_selectedTime),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showDateTimePicker,
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecurrenceSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recurring Reminder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                      if (!value) {
                        _recurrenceType = RecurrenceOptions.oneTime;
                      } else if (_recurrenceType == RecurrenceOptions.oneTime) {
                        _recurrenceType = RecurrenceOptions.daily;
                      }
                    });
                  },
                ),
              ],
            ),
            
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              const Text('Repeat every:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildRecurrenceChip(RecurrenceOptions.hourly, 'Hour'),
                  _buildRecurrenceChip(RecurrenceOptions.daily, 'Day'),
                  _buildRecurrenceChip(RecurrenceOptions.custom, 'Custom'),
                ],
              ),
              
              if (_recurrenceType == RecurrenceOptions.custom) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Every'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: _customHours.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final hours = int.tryParse(value);
                          if (hours == null || hours <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final hours = int.tryParse(value);
                          if (hours != null && hours > 0) {
                            setState(() {
                              _customHours = hours;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('hours'),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecurrenceChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _recurrenceType == type,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _recurrenceType = type;
          });
        }
      },
    );
  }
  
  Widget _buildVibrationSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vibration Pattern',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildVibrationChip('gentle', 'Gentle'),
                _buildVibrationChip('normal', 'Normal'),
                _buildVibrationChip('intense', 'Intense'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVibrationChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _vibrationPattern == type,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _vibrationPattern = type;
          });
        }
      },
    );
  }
  
  void _showDateTimePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      // ignore: use_build_context_synchronously
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTime),
      );
      
      if (time != null) {
        setState(() {
          _selectedTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  void _saveReminder() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    // Get the recurrence period
    Duration? period;
    if (_isRecurring) {
      switch (_recurrenceType) {
        case RecurrenceOptions.hourly:
          period = const Duration(hours: 1);
          break;
        case RecurrenceOptions.daily:
          period = const Duration(days: 1);
          break;
        case RecurrenceOptions.custom:
          period = Duration(hours: _customHours);
          break;
      }
    }
    
    // Get the vibration pattern
    final vibrationPattern = VibrationPatterns.getPattern(_vibrationPattern);
    
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    
    if (_isEditing && _originalReminder != null) {
      // Update existing reminder
      final updatedReminder = _originalReminder!.copyWith(
        title: _title,
        description: _description,
        time: _selectedTime,
        isRecurring: _isRecurring,
        period: period,
        vibrationPattern: vibrationPattern,
      );
      
      provider.updateReminder(updatedReminder);
    } else {
      // Create new reminder
      final newReminder = MealReminder(
        title: _title,
        description: _description,
        time: _selectedTime,
        isRecurring: _isRecurring,
        period: period,
        vibrationPattern: vibrationPattern,
      );
      
      provider.addReminder(newReminder);
    }
    
    Navigator.pop(context);
  }
}
