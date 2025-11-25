/// Task Provider
/// Manages task state and operations using Provider pattern
/// Handles CRUD operations, status updates, and synchronization
library;

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

  // Getters
  List<TaskModel> get tasks => _tasks;
  TaskModel? get activeTask => _activeTask;
  bool get isLoading => _isLoading;
  bool get hasActiveTask => _activeTask != null;

  List<TaskModel> get activeTasks =>
      _tasks.where((t) => t.isActive).toList();
  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();
  List<TaskModel> get pausedTasks =>
      _tasks.where((t) => t.isPaused).toList();

  /// Initialize provider and load tasks
  Future<void> initialize() async {
    await _timerService.initialize();
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
      
      // Stop any currently active task
      if (_activeTask != null) {
        print('Stopping previous active task: ${_activeTask!.taskName}');
        await stopTask(_activeTask!.id);
      }

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
        print('Task scheduled for future. Delaying actual start by: ${delayDuration.inMinutes} minutes ${delayDuration.inSeconds % 60} seconds');
        
        // Schedule the actual task start (timer and screenshots)
        Future.delayed(delayDuration, () async {
          print('\n=== STARTING DELAYED TASK ===');
          print('Time now: ${DateTime.now()}');
          print('Starting timer and screenshots for task: ${task.id}');
          
          // Update task status to active (was created but not truly active until now)
          final activeTask = task.copyWith(status: AppConstants.taskStatusActive);
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
    final now = DateTime.now();
    final duration = scheduledEndTime.difference(now);
    
    print('\n=== SCHEDULING AUTO-STOP ===');
    print('Current time: $now');
    print('Scheduled end time: $scheduledEndTime');
    print('Duration until stop: ${duration.inMinutes} minutes ${duration.inSeconds % 60} seconds');
    
    if (duration.isNegative) {
      print('WARNING: End time is in the past! Stopping immediately.');
      stopTask(taskId);
      return;
    }
    
    // Schedule the stop
    print('Auto-stop scheduled successfully');
    print('=== SCHEDULING COMPLETE ===\n');
    Future.delayed(duration, () async {
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
      
      if (task.status == AppConstants.taskStatusPaused) {
        print('Task is paused. Completing without timer stop.');
        
        // Complete the task directly without stopping timer (already stopped)
        final completedTask = task.copyWith(
          status: AppConstants.taskStatusCompleted,
          endTime: scheduledEndTime, // Use scheduled end time, not now
        );
        
        await _db.updateTask(completedTask);
        _tasks[taskIndex] = completedTask;
        
        if (_activeTask?.id == taskId) {
          _activeTask = null;
        }
        
        notifyListeners();
        print('Paused task auto-completed at scheduled end time');
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
      
      final updatedTask = task.copyWith(
        status: AppConstants.taskStatusCompleted,
        endTime: DateTime.now(),
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
      if (task.scheduledEndTime != null && now.isAfter(task.scheduledEndTime!)) {
        print('Stop time has passed while task was paused. Completing task instead of resuming.');
        print('Stop time was: ${task.scheduledEndTime}');
        print('Current time: $now');
        
        // Complete the task without allowing resume
        final completedTask = task.copyWith(
          status: AppConstants.taskStatusCompleted,
          endTime: task.scheduledEndTime, // Use the scheduled end time
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
        print('Task auto-completed due to stop time being reached while paused');
        print('=== AUTO-COMPLETE ON RESUME COMPLETE ===\n');
        return false; // Return false to indicate resume was not allowed
      }
      
      // Calculate pause duration and accumulate it
      int additionalPausedDuration = 0;
      if (task.pausedAt != null) {
        additionalPausedDuration = now.difference(task.pausedAt!).inMilliseconds;
        print('This pause lasted: ${additionalPausedDuration}ms');
      }
      
      final newTotalPausedDuration = task.totalPausedDuration + additionalPausedDuration;
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
      
      // Restart the timer service
      await _timerService.start(taskId);
      print('Timer service restarted');

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
      return {
        'totalMinutes': 0,
        'completed': 0,
        'active': 0,
        'tasksCount': 0,
      };
    }
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }
}
