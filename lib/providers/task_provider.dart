/// Task Provider
/// Manages task state and operations using Provider pattern
/// Handles CRUD operations, status updates, and synchronization

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
  }) async {
    try {
      // Stop any currently active task
      if (_activeTask != null) {
        await stopTask(_activeTask!.id);
      }

      // Create new task
      final task = TaskModel(
        id: _uuid.v4(),
        employeeId: employeeId,
        employeeName: employeeName,
        taskName: taskName,
        taskDescription: taskDescription,
        status: AppConstants.taskStatusActive,
        startTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Save to database
      await _db.insertTask(task);

      // Update state
      _activeTask = task;
      _tasks.insert(0, task);

      // Start timer for screenshot capture
      await _timerService.start(task.id);

      notifyListeners();
      print('Task started: ${task.taskName}');
      return task;
    } catch (e) {
      print('Error starting task: $e');
      return null;
    }
  }

  /// Stop/Complete a task
  Future<bool> stopTask(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        status: AppConstants.taskStatusCompleted,
        endTime: DateTime.now(),
      );

      await _db.updateTask(updatedTask);

      // Update state
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      if (_activeTask?.id == taskId) {
        _activeTask = null;
        await _timerService.stop();
      }

      notifyListeners();
      print('Task stopped: ${updatedTask.taskName}');
      return true;
    } catch (e) {
      print('Error stopping task: $e');
      return false;
    }
  }

  /// Pause a task
  Future<bool> pauseTask(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        status: AppConstants.taskStatusPaused,
      );

      await _db.updateTask(updatedTask);

      // Update state
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      if (_activeTask?.id == taskId) {
        _activeTask = updatedTask;
        await _timerService.pause();
      }

      notifyListeners();
      print('Task paused: ${updatedTask.taskName}');
      return true;
    } catch (e) {
      print('Error pausing task: $e');
      return false;
    }
  }

  /// Resume a paused task
  Future<bool> resumeTask(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        status: AppConstants.taskStatusActive,
      );

      await _db.updateTask(updatedTask);

      // Update state
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      _activeTask = updatedTask;
      await _timerService.resume(taskId);

      notifyListeners();
      print('Task resumed: ${updatedTask.taskName}');
      return true;
    } catch (e) {
      print('Error resuming task: $e');
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
