/// Task Form Screen
/// Form to create a new task

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
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
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter task name',
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
              TextFormField(
                controller: _taskDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Task Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter task description (optional)',
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
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

  Future<void> _submitForm(
    TaskProvider taskProvider,
    AuthProvider authProvider,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final task = await taskProvider.startNewTask(
      employeeId: authProvider.employeeId,
      employeeName: authProvider.employeeName,
      taskName: _taskNameController.text.trim(),
      taskDescription: _taskDescriptionController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (task != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task started successfully!')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start task')),
      );
    }
  }
}
