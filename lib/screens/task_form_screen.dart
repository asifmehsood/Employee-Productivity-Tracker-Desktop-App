/// Task Form Screen
/// Form to create a new task with scheduling
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import 'task_list_screen.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task Name Field
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter task name',
                  prefixIcon: Icon(Icons.task),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              
              // Task Description Field
              TextFormField(
                controller: _taskDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Task Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter task description (optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              
              // Task Start Date & Time Picker
              InkWell(
                onTap: _pickStartDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Task Start Time *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDateTime == null
                        ? 'Select start date and time'
                        : _formatDateTime(_startDateTime!),
                    style: TextStyle(
                      color: _startDateTime == null
                          ? Colors.grey[600]
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Task End Date & Time Picker
              InkWell(
                onTap: _startDateTime == null ? null : _pickEndDateTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Task Stop Time *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.event),
                    enabled: _startDateTime != null,
                  ),
                  child: Text(
                    _endDateTime == null
                        ? 'Select end date and time'
                        : _formatDateTime(_endDateTime!),
                    style: TextStyle(
                      color: _endDateTime == null
                          ? Colors.grey[600]
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              if (_startDateTime == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Please select start time first',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              
              // Submit Button
              Consumer2<TaskProvider, AuthProvider>(
                builder: (context, taskProvider, authProvider, child) {
                  return ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitForm(taskProvider, authProvider),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Start Task',
                            style: TextStyle(fontSize: 18),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickStartDateTime() async {
    // Pick Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    // Pick Time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _startDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      // Reset end time if it's before the new start time
      if (_endDateTime != null && _endDateTime!.isBefore(_startDateTime!)) {
        _endDateTime = null;
      }
    });
  }

  Future<void> _pickEndDateTime() async {
    if (_startDateTime == null) return;

    // Pick Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime!,
      firstDate: _startDateTime!,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    // Determine initial time and valid time range
    TimeOfDay initialTime;
    if (pickedDate.year == _startDateTime!.year &&
        pickedDate.month == _startDateTime!.month &&
        pickedDate.day == _startDateTime!.day) {
      // Same day: time must be after start time
      initialTime = TimeOfDay(
        hour: _startDateTime!.hour,
        minute: _startDateTime!.minute + 1,
      );
    } else {
      // Different day: any time is valid
      initialTime = TimeOfDay.now();
    }

    // Pick Time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null || !mounted) return;

    final tentativeEndDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validate that end time is after start time
    if (tentativeEndDateTime.isBefore(_startDateTime!) ||
        tentativeEndDateTime.isAtSameMomentAs(_startDateTime!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _endDateTime = tentativeEndDateTime;
    });
  }

  Future<void> _submitForm(
    TaskProvider taskProvider,
    AuthProvider authProvider,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date/time selection
    if (_startDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select task start time')),
      );
      return;
    }

    if (_endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select task stop time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final task = await taskProvider.startNewTask(
      employeeId: authProvider.employeeId,
      employeeName: authProvider.employeeName,
      taskName: _taskNameController.text.trim(),
      taskDescription: _taskDescriptionController.text.trim(),
      scheduledStartTime: _startDateTime,
      scheduledEndTime: _endDateTime,
    );

    setState(() => _isSubmitting = false);

    if (task != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully!')),
      );
      // Navigate to task list screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TaskListScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create task')),
      );
    }
  }
}
