/// Task Provider
/// Manages task state and operations using Provider pattern
/// Handles CRUD operations, status updates, and synchronization
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../core/services/database_helper.dart';
import '../core/services/timer_service.dart';
import '../core/constants/app_constants.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TimerService _timerService = TimerService();
  final _uuid = const Uuid();

  List<TaskModel> _tasks = [];
  TaskModel? _activeTask;
  bool _isLoading = false;
  bool _isIdlePaused = false;
  DateTime? _idlePausedAt;
  Timer? _autoStopTimer;
  DateTime? _scheduledEndTime;

  // Callback for showing notifications
  Function(String message, {bool isWarning})? onShowNotification;

  // Getters
  List<TaskModel> get tasks => _tasks;
  TaskModel? get activeTask => _activeTask;
  bool get isLoading => _isLoading;
  bool get hasActiveTask => _activeTask != null;
  bool get isIdlePaused => _isIdlePaused;
  DateTime? get idlePausedAt => _idlePausedAt;

  List<TaskModel> get activeTasks => _tasks.where((t) => t.isActive).toList();
  List<TaskModel> get runningTasks => _tasks.where((t) => t.isRunning).toList();
  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();
  List<TaskModel> get pausedTasks => _tasks.where((t) => t.isPaused).toList();

  /// Initialize provider and load tasks
  Future<void> initialize() async {
    await _timerService.initialize();

    // Setup idle state change listener
    _timerService.onIdleStateChanged = (isIdle) {
      _isIdlePaused = isIdle;
      if (isIdle) {
        // Record when idle pause started (like manual pause)
        _idlePausedAt = DateTime.now();
        print('User went idle at: $_idlePausedAt');
        print('Timer paused (UI will stop), but auto-stop will continue');

        onShowNotification?.call(
          'You\'ve been idle for 1 minute. Timer paused automatically.',
          isWarning: true,
        );
      } else {
        // Clear idle pause time when resuming
        _idlePausedAt = null;
        print('User active again - timer resumed');

        onShowNotification?.call(
          'Welcome back! Timer resumed.',
          isWarning: false,
        );
      }
      notifyListeners();
    };

    // Setup idle duration calculator
    _timerService.onIdleDurationCalculated = (idleDurationMs) async {
      if (_activeTask != null) {
        await _addIdleDurationToTask(_activeTask!.id, idleDurationMs);
        // Don't extend end time - idle time is subtracted from duration
        // Task will complete at original scheduled time
      }
    };

    await loadTasks();
    await _loadActiveTask();
  }

  /// Load all tasks from database
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _db.getAllTasks();
    } catch (e) {
      print('Error loading tasks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load the active task
  Future<void> _loadActiveTask() async {
    try {
      _activeTask = await _db.getActiveTask();

      // If there's an active task, ensure timer is running
      if (_activeTask != null) {
        if (!_timerService.isRunning) {
          await _timerService.start(_activeTask!.id);
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading active task: $e');
    }
  }

  /// Create and start a new task
  Future<TaskModel?> startNewTask({
    required String employeeId,
    required String employeeName,
    required String taskName,
    required String taskDescription,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
  }) async {
    try {
      print('\n=== CREATING NEW TASK ===');
      print('Task Name: $taskName');
      print('Scheduled Start Time: $scheduledStartTime');
      print('Scheduled End Time: $scheduledEndTime');
      print('Current Time: ${DateTime.now()}');

      // Use scheduled start time or current time
      final actualStartTime = scheduledStartTime ?? DateTime.now();
      print('Actual Start Time (used for task): $actualStartTime');

      // Create new task
      final task = TaskModel(
        id: _uuid.v4(),
        employeeId: employeeId,
        employeeName: employeeName,
        taskName: taskName,
        taskDescription: taskDescription,
        status: AppConstants.taskStatusActive,
        startTime: actualStartTime,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
        createdAt: DateTime.now(),
      );

      print('Task created with ID: ${task.id}');
      print('Task startTime stored: ${task.startTime}');

      // Save to database
      await _db.insertTask(task);
      print('Task saved to database');

      // Update state
      _activeTask = task;
      _tasks.insert(0, task);
      print('Active task updated in provider');

      // Check if we need to delay the start
      final now = DateTime.now();
      if (actualStartTime.isAfter(now)) {
        final delayDuration = actualStartTime.difference(now);
        print(
          'Task scheduled for future. Delaying actual start by: ${delayDuration.inMinutes} minutes ${delayDuration.inSeconds % 60} seconds',
        );

        // Schedule the actual task start (timer and screenshots)
        Future.delayed(delayDuration, () async {
          print('\n=== STARTING DELAYED TASK ===');
          print('Time now: ${DateTime.now()}');
          print('Starting timer and screenshots for task: ${task.id}');

          // Check if task still exists and is active
          final currentTask = await _db.getTaskById(task.id);
          if (currentTask == null || !currentTask.isActive) {
            print(
              'Task was deleted or is no longer active. Skipping delayed start.',
            );
            print('=== DELAYED TASK START CANCELLED ===\n');
            return;
          }

          // Update task status to active (was created but not truly active until now)
          final activeTask = task.copyWith(
            status: AppConstants.taskStatusActive,
          );
          await _db.updateTask(activeTask);

          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = activeTask;
          }
          if (_activeTask?.id == task.id) {
            _activeTask = activeTask;
          }

          notifyListeners();
          print('Task status updated to ACTIVE');

          await _timerService.start(task.id);
          print('=== DELAYED TASK START COMPLETE ===\n');
        });
      } else {
        // Start immediately if start time is now or in the past
        print('Starting timer and screenshots immediately');
        await _timerService.start(task.id);
        print('Timer service started');
      }

      // Schedule auto-stop if end time is provided
      if (scheduledEndTime != null) {
        print('Scheduling auto-stop at: $scheduledEndTime');
        _scheduleTaskStop(task.id, scheduledEndTime);
      }

      notifyListeners();
      print('Listeners notified');
      print('Task started: ${task.taskName}');
      print('=== TASK CREATION COMPLETE ===\n');
      return task;
    } catch (e) {
      print('ERROR creating task: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Schedule automatic task stop at scheduled end time
  void _scheduleTaskStop(String taskId, DateTime scheduledEndTime) {
    // Cancel existing timer if any
    _autoStopTimer?.cancel();

    final now = DateTime.now();
    final duration = scheduledEndTime.difference(now);

    print('\n=== SCHEDULING AUTO-STOP ===');
    print('Current time: $now');
    print('Scheduled end time: $scheduledEndTime');
    print(
      'Duration until stop: ${duration.inMinutes} minutes ${duration.inSeconds % 60} seconds',
    );

    if (duration.isNegative) {
      print('WARNING: End time is in the past! Stopping immediately.');
      stopTask(taskId);
      return;
    }

    // Store scheduled end time
    _scheduledEndTime = scheduledEndTime;

    // Schedule the stop
    print('Auto-stop scheduled successfully');
    print('=== SCHEDULING COMPLETE ===\n');
    _autoStopTimer = Timer(duration, () async {
      print('\n=== AUTO-STOP TRIGGERED ===');
      print('Checking task status at: ${DateTime.now()}');

      // Find the task to check if it's paused
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) {
        print('Task not found, may have been deleted');
        return;
      }

      final task = _tasks[taskIndex];
      print('Task status: ${task.status}');
      print('Is idle paused: $_isIdlePaused');

      if (task.status == AppConstants.taskStatusPaused) {
        print('Task is manually paused. Completing without timer stop.');

        // If task is manually paused, add the final pause duration to totalPausedDuration
        int finalTotalPausedDuration = task.totalPausedDuration;
        if (task.pausedAt != null) {
          final pauseDuration = scheduledEndTime
              .difference(task.pausedAt!)
              .inMilliseconds;
          finalTotalPausedDuration = task.totalPausedDuration + pauseDuration;
          print('Adding final pause duration: ${pauseDuration}ms');
          print('Total paused duration: ${finalTotalPausedDuration}ms');
        }

        // Complete the task directly without stopping timer (already stopped)
        final completedTask = task.copyWith(
          status: AppConstants.taskStatusCompleted,
          endTime: scheduledEndTime, // Use scheduled end time, not now
          totalPausedDuration: finalTotalPausedDuration,
        );

        await _db.updateTask(completedTask);
        _tasks[taskIndex] = completedTask;

        if (_activeTask?.id == taskId) {
          _activeTask = null;
          _autoStopTimer?.cancel();
          _autoStopTimer = null;
          _scheduledEndTime = null;
        }

        notifyListeners();
        print('Paused task auto-completed at scheduled end time');
      } else if (_isIdlePaused &&
          task.status == AppConstants.taskStatusActive &&
          _timerService.getCurrentIdleDuration() != null) {
        // Task is CURRENTLY idle paused (not just was idle at some point)
        print('Task is currently idle. Completing with idle duration.');

        // Get current idle duration from timer service
        final currentIdleDuration = _timerService.getCurrentIdleDuration()!;
        final finalTotalPausedDuration =
            task.totalPausedDuration + currentIdleDuration;

        print('Current idle duration: ${currentIdleDuration}ms');
        print('Total paused duration: ${finalTotalPausedDuration}ms');

        // Complete the task with idle time tracked
        final completedTask = task.copyWith(
          status: AppConstants.taskStatusCompleted,
          endTime: scheduledEndTime,
          totalPausedDuration: finalTotalPausedDuration,
        );

        await _db.updateTask(completedTask);
        _tasks[taskIndex] = completedTask;

        if (_activeTask?.id == taskId) {
          _activeTask = null;
          _autoStopTimer?.cancel();
          _autoStopTimer = null;
          _scheduledEndTime = null;
          // Clear idle state
          _isIdlePaused = false;
          _idlePausedAt = null;
          await _timerService.stop();
        }

        notifyListeners();
        print('Idle paused task auto-completed at scheduled end time');
      } else {
        print('Task is active. Stopping normally.');
        await stopTask(taskId);
      }

      print('=== AUTO-STOP COMPLETE ===\n');
    });
  }

  /// Stop/Complete a task
  Future<bool> stopTask(String taskId) async {
    try {
      print('\n=== STOPPING TASK ===');
      print('Task ID to stop: $taskId');
      print('Current active task: ${_activeTask?.id}');
      print('Current time: ${DateTime.now()}');

      final task = _tasks.firstWhere((t) => t.id == taskId);
      print('Found task to stop: ${task.taskName}');

      // If task is currently paused, add the final pause duration to totalPausedDuration
      int finalTotalPausedDuration = task.totalPausedDuration;
      if (task.isPaused && task.pausedAt != null) {
        final now = DateTime.now();
        final currentPauseDuration = now
            .difference(task.pausedAt!)
            .inMilliseconds;
        finalTotalPausedDuration =
            task.totalPausedDuration + currentPauseDuration;
        print(
          'Task is paused. Adding final pause duration: ${currentPauseDuration}ms',
        );
        print('Total paused duration: ${finalTotalPausedDuration}ms');
      }

      final updatedTask = task.copyWith(
        status: AppConstants.taskStatusCompleted,
        endTime: DateTime.now(),
        totalPausedDuration: finalTotalPausedDuration,
      );

      await _db.updateTask(updatedTask);
      print('Task updated in database');

      // Update state
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        print('Task updated in list at index: $index');
      }

      if (_activeTask?.id == taskId) {
        print('Clearing active task');
        _activeTask = null;
        _isIdlePaused = false;
        _idlePausedAt = null;
        _autoStopTimer?.cancel();
        _autoStopTimer = null;
        _scheduledEndTime = null;
        await _timerService.stop();
        print('Timer service stopped');
      }

      notifyListeners();
      print('Listeners notified');
      print('Task stopped: ${updatedTask.taskName}');
      print('=== TASK STOP COMPLETE ===\n');
      return true;
    } catch (e) {
      print('ERROR stopping task: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Pause a task
  Future<bool> pauseTask(String taskId) async {
    try {
      print('\n=== PAUSING TASK ===');
      print('Task ID: $taskId');

      final task = _tasks.firstWhere((t) => t.id == taskId);
      print('Current task status: ${task.status}');
      print('Time now: ${DateTime.now()}');

      // Record pause time
      final pausedAt = DateTime.now();
      final updatedTask = task.copyWith(
        status: AppConstants.taskStatusPaused,
        pausedAt: pausedAt,
      );
      print('Pause time recorded: $pausedAt');

      await _db.updateTask(updatedTask);
      print('Task updated in database');

      // Update state
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      if (_activeTask?.id == taskId) {
        _activeTask = updatedTask;
        _autoStopTimer?.cancel();
        _autoStopTimer = null;
        // Clear idle state when manually pausing
        _isIdlePaused = false;
        _idlePausedAt = null;
        // Stop the timer service completely
        await _timerService.stop();
        print('Timer service stopped');
      }

      notifyListeners();
      print('Task paused: ${updatedTask.taskName}');
      print('=== PAUSE COMPLETE ===\n');
      return true;
    } catch (e) {
      print('ERROR pausing task: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Add idle duration to task's total paused duration
  Future<void> _addIdleDurationToTask(String taskId, int idleDurationMs) async {
    try {
      print('\n=== ADDING IDLE DURATION TO TASK ===');
      print('Task ID: $taskId');
      print(
        'Idle Duration: ${idleDurationMs}ms (${(idleDurationMs / 1000).toStringAsFixed(1)}s)',
      );

      final task = _tasks.firstWhere((t) => t.id == taskId);
      final newTotalPausedDuration = task.totalPausedDuration + idleDurationMs;

      print('Previous total paused duration: ${task.totalPausedDuration}ms');
      print('New total paused duration: ${newTotalPausedDuration}ms');

      final updatedTask = task.copyWith(
        totalPausedDuration: newTotalPausedDuration,
      );

      await _db.updateTask(updatedTask);
      print('Task updated in database with new paused duration');

      // Update state
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      if (_activeTask?.id == taskId) {
        _activeTask = updatedTask;
      }

      notifyListeners();
      print('=== IDLE DURATION ADDED ===\n');
    } catch (e) {
      print('ERROR adding idle duration to task: $e');
    }
  }

  /// Resume a paused task
  Future<bool> resumeTask(String taskId) async {
    try {
      print('\n=== RESUMING TASK ===');
      print('Task ID: $taskId');

      final task = _tasks.firstWhere((t) => t.id == taskId);
      print('Current task status: ${task.status}');
      print('Paused at: ${task.pausedAt}');
      print('Previous total paused duration: ${task.totalPausedDuration}ms');

      // Check if stop time has passed while paused
      final now = DateTime.now();
      if (task.scheduledEndTime != null &&
          now.isAfter(task.scheduledEndTime!)) {
        print(
          'Stop time has passed while task was paused. Completing task instead of resuming.',
        );
        print('Stop time was: ${task.scheduledEndTime}');
        print('Current time: $now');

        // Calculate final pause duration (from pausedAt to scheduled end time)
        int finalTotalPausedDuration = task.totalPausedDuration;
        if (task.pausedAt != null) {
          final pauseDuration = task.scheduledEndTime!
              .difference(task.pausedAt!)
              .inMilliseconds;
          finalTotalPausedDuration = task.totalPausedDuration + pauseDuration;
          print('Adding final pause duration: ${pauseDuration}ms');
          print('Total paused duration: ${finalTotalPausedDuration}ms');
        }

        // Complete the task without allowing resume
        final completedTask = task.copyWith(
          status: AppConstants.taskStatusCompleted,
          endTime: task.scheduledEndTime, // Use the scheduled end time
          totalPausedDuration: finalTotalPausedDuration,
        );

        await _db.updateTask(completedTask);

        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = completedTask;
        }

        if (_activeTask?.id == taskId) {
          _activeTask = null;
        }

        notifyListeners();
        print(
          'Task auto-completed due to stop time being reached while paused',
        );
        print('=== AUTO-COMPLETE ON RESUME COMPLETE ===\n');
        return false; // Return false to indicate resume was not allowed
      }

      // Calculate pause duration and accumulate it
      int additionalPausedDuration = 0;
      if (task.pausedAt != null) {
        additionalPausedDuration = now
            .difference(task.pausedAt!)
            .inMilliseconds;
        print('This pause lasted: ${additionalPausedDuration}ms');
      }

      final newTotalPausedDuration =
          task.totalPausedDuration + additionalPausedDuration;
      print('New total paused duration: ${newTotalPausedDuration}ms');

      final updatedTask = task.copyWith(
        status: AppConstants.taskStatusActive,
        pausedAt: null, // Clear pause timestamp
        totalPausedDuration: newTotalPausedDuration,
      );
      print('Resume time: $now');

      await _db.updateTask(updatedTask);
      print('Task updated in database');

      // Update state
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      _activeTask = updatedTask;

      // Restart the timer service (pass isResuming to skip immediate screenshot)
      await _timerService.start(taskId, isResuming: true);
      print('Timer service restarted');

      // Reschedule auto-stop if there's a scheduled end time
      if (task.scheduledEndTime != null) {
        print('Rescheduling auto-stop at: ${task.scheduledEndTime}');
        _scheduleTaskStop(taskId, task.scheduledEndTime!);
      }

      notifyListeners();
      print('Task resumed: ${updatedTask.taskName}');
      print('=== RESUME COMPLETE ===\n');
      return true;
    } catch (e) {
      print('ERROR resuming task: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _db.deleteTask(taskId);

      _tasks.removeWhere((t) => t.id == taskId);

      if (_activeTask?.id == taskId) {
        _activeTask = null;
        await _timerService.stop();
      }

      notifyListeners();
      print('Task deleted: $taskId');
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  /// Update task details
  Future<bool> updateTask(TaskModel task) async {
    try {
      await _db.updateTask(task);

      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      }

      if (_activeTask?.id == task.id) {
        _activeTask = task;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  /// Get task by ID
  TaskModel? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get timer service for access to timer info
  TimerService get timerService => _timerService;

  /// Check if a time slot conflicts with existing tasks
  /// Returns the conflicting task if there's a conflict, null otherwise
  TaskModel? checkTimeConflict(DateTime startTime, DateTime endTime) {
    for (var task in _tasks) {
      // Skip completed tasks
      if (task.isCompleted) continue;

      // Get the task's time range
      final taskStart = task.startTime;
      final taskEnd = task.scheduledEndTime ?? task.endTime;

      // Skip if task doesn't have an end time
      if (taskEnd == null) continue;

      // Check for overlap:
      // New task starts before existing task ends AND new task ends after existing task starts
      final hasOverlap =
          startTime.isBefore(taskEnd) && endTime.isAfter(taskStart);

      if (hasOverlap) {
        return task; // Return the conflicting task
      }
    }
    return null; // No conflict
  }

  /// Get work session data for a specific date
  Future<Map<String, dynamic>> getWorkSessionForDate(DateTime date) async {
    try {
      // Get all tasks for this date
      final allTasks = await _db.getAllTasks();
      final tasksForDate = allTasks.where((task) {
        final taskDate = task.startTime;
        return taskDate.year == date.year &&
            taskDate.month == date.month &&
            taskDate.day == date.day;
      }).toList();

      int totalMinutes = 0;
      int completed = 0;
      int active = 0;

      for (var task in tasksForDate) {
        final durationMinutes = task.duration.inMinutes;
        totalMinutes += durationMinutes;

        if (task.isCompleted) {
          completed++;
        } else if (task.isActive) {
          active++;
        }
      }

      return {
        'totalMinutes': totalMinutes,
        'completed': completed,
        'active': active,
        'tasksCount': tasksForDate.length,
      };
    } catch (e) {
      print('Error getting work session: $e');
      return {'totalMinutes': 0, 'completed': 0, 'active': 0, 'tasksCount': 0};
    }
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }
}
