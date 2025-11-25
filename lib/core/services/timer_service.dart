/// Timer Service
/// Manages periodic screenshot capture based on configured interval
/// Runs in background and only captures when a task is active

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'screenshot_service.dart';
import 'database_helper.dart';

class TimerService {
  Timer? _timer;
  final ScreenshotService _screenshotService = ScreenshotService();
  bool _isRunning = false;
  int _intervalMinutes = AppConstants.defaultScreenshotIntervalMinutes;
  String? _activeTaskId;

  /// Get current running status
  bool get isRunning => _isRunning;

  /// Get current interval
  int get intervalMinutes => _intervalMinutes;

  /// Get active task ID
  String? get activeTaskId => _activeTaskId;

  /// Initialize timer service and load settings
  Future<void> initialize() async {
    await _loadSettings();
  }

  /// Load screenshot interval from settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _intervalMinutes = prefs.getInt(AppConstants.settingsScreenshotInterval) ??
          AppConstants.defaultScreenshotIntervalMinutes;
      print('Timer service initialized with interval: $_intervalMinutes minutes');
    } catch (e) {
      print('Error loading timer settings: $e');
      _intervalMinutes = AppConstants.defaultScreenshotIntervalMinutes;
    }
  }

  /// Update screenshot interval
  Future<void> updateInterval(int minutes) async {
    if (minutes < AppConstants.minScreenshotIntervalMinutes ||
        minutes > AppConstants.maxScreenshotIntervalMinutes) {
      print('Invalid interval: $minutes. Must be between ${AppConstants.minScreenshotIntervalMinutes} and ${AppConstants.maxScreenshotIntervalMinutes}');
      return;
    }

    _intervalMinutes = minutes;

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.settingsScreenshotInterval, minutes);

    // Restart timer if running
    if (_isRunning && _activeTaskId != null) {
      await stop();
      await start(_activeTaskId!);
    }

    print('Screenshot interval updated to $_intervalMinutes minutes');
  }

  /// Start the timer for a specific task
  Future<void> start(String taskId) async {
    if (_isRunning) {
      print('Timer already running');
      return;
    }

    // Verify task exists and is active
    final task = await DatabaseHelper.instance.getTaskById(taskId);
    if (task == null || !task.isActive) {
      print('Cannot start timer: Task not found or not active');
      return;
    }

    _activeTaskId = taskId;
    _isRunning = true;

    // Take first screenshot immediately
    await _captureScreenshot();

    // Start periodic timer
    _timer = Timer.periodic(
      Duration(minutes: _intervalMinutes),
      (timer) async {
        await _captureScreenshot();
      },
    );

    print('Timer started for task: $taskId (Interval: $_intervalMinutes minutes)');
  }

  /// Stop the timer
  Future<void> stop() async {
    if (!_isRunning) {
      print('Timer is not running');
      return;
    }

    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _activeTaskId = null;

    print('Timer stopped');
  }

  /// Pause the timer (stops capturing but keeps timer active)
  Future<void> pause() async {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    _isRunning = false;
    print('Timer paused');
  }

  /// Resume the timer (restarts capturing)
  Future<void> resume(String taskId) async {
    await start(taskId);
    print('Timer resumed');
  }

  /// Capture a screenshot for the active task
  Future<void> _captureScreenshot() async {
    if (_activeTaskId == null) {
      print('No active task for screenshot');
      return;
    }

    // Verify task is still active
    final task = await DatabaseHelper.instance.getTaskById(_activeTaskId!);
    if (task == null || !task.isActive) {
      print('Task no longer active, stopping timer');
      await stop();
      return;
    }

    print('Capturing screenshot for task: $_activeTaskId');
    final screenshot = await _screenshotService.captureScreenshot(_activeTaskId!);

    if (screenshot != null) {
      print('Screenshot captured successfully: ${screenshot.id}');
    } else {
      print('Failed to capture screenshot');
    }
  }

  /// Manually trigger a screenshot (outside of timer)
  Future<bool> captureManual(String taskId) async {
    final screenshot = await _screenshotService.captureScreenshot(taskId);
    return screenshot != null;
  }

  /// Get next screenshot time
  DateTime? getNextScreenshotTime() {
    if (!_isRunning || _activeTaskId == null) {
      return null;
    }

    // Calculate next screenshot time based on interval
    return DateTime.now().add(Duration(minutes: _intervalMinutes));
  }

  /// Get time remaining until next screenshot
  Duration? getTimeRemaining() {
    final nextTime = getNextScreenshotTime();
    if (nextTime == null) return null;

    final now = DateTime.now();
    if (nextTime.isBefore(now)) return Duration.zero;

    return nextTime.difference(now);
  }

  /// Get formatted time remaining (MM:SS)
  String? getFormattedTimeRemaining() {
    final remaining = getTimeRemaining();
    if (remaining == null) return null;

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Dispose the timer service
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _activeTaskId = null;
  }
}
