/// Timer Service
/// Manages periodic screenshot capture based on configured interval
/// Runs in background and only captures when a task is active
library;

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'screenshot_service.dart';
import 'database_helper.dart';
import 'window_tracker_service.dart';
import 'idle_detector_service.dart';

class TimerService {
  Timer? _timer;
  final ScreenshotService _screenshotService = ScreenshotService();
  final WindowTrackerService _windowTracker = WindowTrackerService();
  final IdleDetectorService _idleDetector = IdleDetectorService();
  bool _isRunning = false;
  bool _isPausedDueToIdle = false;
  DateTime? _idleStartTime;
  int _intervalMinutes = AppConstants.defaultScreenshotIntervalMinutes;
  String? _activeTaskId;
  
  // Track elapsed time for screenshot alignment
  int _elapsedSeconds = 0;
  int _lastScreenshotAtSecond = 0;
  bool _isCapturingScreenshot = false;

  // Callback for idle state changes
  Function(bool isIdle)? onIdleStateChanged;
  // Callback for idle duration update
  Function(int idleDurationMs)? onIdleDurationCalculated;

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
      _intervalMinutes =
          prefs.getInt(AppConstants.settingsScreenshotInterval) ??
          AppConstants.defaultScreenshotIntervalMinutes;
      print(
        'Timer service initialized with interval: $_intervalMinutes minutes',
      );
    } catch (e) {
      print('Error loading timer settings: $e');
      _intervalMinutes = AppConstants.defaultScreenshotIntervalMinutes;
    }
  }

  /// Update screenshot interval
  Future<void> updateInterval(int minutes) async {
    if (minutes < AppConstants.minScreenshotIntervalMinutes ||
        minutes > AppConstants.maxScreenshotIntervalMinutes) {
      print(
        'Invalid interval: $minutes. Must be between ${AppConstants.minScreenshotIntervalMinutes} and ${AppConstants.maxScreenshotIntervalMinutes}',
      );
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
  /// [isResuming] - Set to true when resuming from pause to skip immediate screenshot
  Future<void> start(String taskId, {bool isResuming = false}) async {
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
    _isPausedDueToIdle = false;
    _idleStartTime = null;

    // Start window tracking
    await _windowTracker.startTracking(taskId);

    // Start idle detection
    _idleDetector.startMonitoring(
      onIdleCallback: () => _handleIdle(),
      onActiveCallback: () => _handleActive(),
    );

    print('Timer starting for task: $taskId');
    print('Current elapsed seconds: $_elapsedSeconds');
    print('Last screenshot was at: $_lastScreenshotAtSecond seconds');

    // Take IMMEDIATE screenshot on start (first screenshot)
    print('\n=== TAKING IMMEDIATE SCREENSHOT ON START ===');
    await _captureScreenshot();
    _lastScreenshotAtSecond = _elapsedSeconds;
    print('Screenshot #1 captured immediately at start');
    print('Next screenshot at: 60 seconds active time');
    print('=== IMMEDIATE SCREENSHOT COMPLETE ===\n');

    // Start tick timer (1 second intervals)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Get current task to check active duration (excludes paused time)
      final currentTask = await DatabaseHelper.instance.getTaskById(taskId);
      if (currentTask == null || !currentTask.isActive) {
        return;
      }
      
      // Calculate active seconds (excludes paused time)
      final activeSeconds = currentTask.activeDuration.inSeconds;
      
      // Check if we've passed the interval since last screenshot (based on ACTIVE time)
      final intervalSeconds = _intervalMinutes * 60;
      final secondsSinceLastScreenshot = activeSeconds - _lastScreenshotAtSecond;
      
      if (secondsSinceLastScreenshot >= intervalSeconds) {
        print('\n=== TIME FOR SCREENSHOT (60 ACTIVE SECONDS PASSED) ===');
        print('Active time now: $activeSeconds seconds (${(activeSeconds / 60).toInt()}:${(activeSeconds % 60).toString().padLeft(2, '0')})');
        print('Last screenshot at: $_lastScreenshotAtSecond seconds');
        print('Active seconds since last screenshot: $secondsSinceLastScreenshot');
        await _captureScreenshot();
        _lastScreenshotAtSecond = activeSeconds;
        print('Next screenshot when active time reaches: ${_lastScreenshotAtSecond + intervalSeconds} seconds');
        print('=== SCREENSHOT COMPLETE ===\n');
      }
    });

    print('Timer started for task: $taskId');
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
    _isPausedDueToIdle = false;
    _idleStartTime = null;
    
    // Reset elapsed time counters
    _elapsedSeconds = 0;
    _lastScreenshotAtSecond = 0;

    // Stop window tracking
    await _windowTracker.stopTracking();

    // Stop idle detection
    _idleDetector.stopMonitoring();

    _activeTaskId = null;

    print('Timer stopped and counters reset');
  }

  /// Pause the timer (stops capturing but keeps elapsed time)
  Future<void> pause() async {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    _isRunning = false;
    print('Timer paused at $_elapsedSeconds seconds');
    print('Elapsed time preserved for proper screenshot timing on resume');
  }

  /// Resume the timer (restarts capturing with immediate screenshot)
  Future<void> resume(String taskId) async {
    if (_isRunning) {
      print('Timer already running');
      return;
    }

    // Verify task exists and is active
    final task = await DatabaseHelper.instance.getTaskById(taskId);
    if (task == null || !task.isActive) {
      print('Cannot resume timer: Task not found or not active');
      return;
    }

    _activeTaskId = taskId;
    _isRunning = true;
    _isPausedDueToIdle = false;
    _idleStartTime = null;

    // Start window tracking
    await _windowTracker.startTracking(taskId);

    // Start idle detection
    _idleDetector.startMonitoring(
      onIdleCallback: () => _handleIdle(),
      onActiveCallback: () => _handleActive(),
    );

    print('\n=== RESUMING TIMER ===');
    print('Resuming at $_elapsedSeconds seconds');
    print('Last screenshot was at: $_lastScreenshotAtSecond seconds');

    // Don't take screenshot on resume - only when 60 active seconds pass
    print('Timer resumed - next screenshot when 60 active seconds pass since last screenshot');

    // Start tick timer (1 second intervals)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Get current task to check active duration (excludes paused time)
      final currentTask = await DatabaseHelper.instance.getTaskById(taskId);
      if (currentTask == null || !currentTask.isActive) {
        return;
      }
      
      // Calculate active seconds (excludes paused time)
      final activeSeconds = currentTask.activeDuration.inSeconds;
      
      // Check if we've passed the interval since last screenshot (based on ACTIVE time)
      final intervalSeconds = _intervalMinutes * 60;
      final secondsSinceLastScreenshot = activeSeconds - _lastScreenshotAtSecond;
      
      if (secondsSinceLastScreenshot >= intervalSeconds) {
        print('\n=== TIME FOR SCREENSHOT (60 ACTIVE SECONDS PASSED) ===');
        print('Active time now: $activeSeconds seconds (${(activeSeconds / 60).toInt()}:${(activeSeconds % 60).toString().padLeft(2, '0')})');
        print('Last screenshot at: $_lastScreenshotAtSecond seconds');
        print('Active seconds since last screenshot: $secondsSinceLastScreenshot');
        await _captureScreenshot();
        _lastScreenshotAtSecond = activeSeconds;
        print('Next screenshot when active time reaches: ${_lastScreenshotAtSecond + intervalSeconds} seconds');
        print('=== SCREENSHOT COMPLETE ===\n');
      }
    });

    print('Timer resumed successfully');
    print('=== RESUME COMPLETE ===\n');
  }

  /// Capture a screenshot for the active task
  Future<void> _captureScreenshot() async {
    // Prevent duplicate captures
    if (_isCapturingScreenshot) {
      print('Screenshot capture already in progress, skipping duplicate');
      return;
    }

    if (_activeTaskId == null) {
      print('No active task for screenshot');
      return;
    }

    _isCapturingScreenshot = true;
    try {
      // Verify task is still active
      final task = await DatabaseHelper.instance.getTaskById(_activeTaskId!);
      if (task == null || !task.isActive) {
        print('Task no longer active, stopping timer');
        await stop();
        return;
      }

      print('Capturing screenshot for task: $_activeTaskId');
      final screenshot = await _screenshotService.captureScreenshot(
        _activeTaskId!,
      );

      if (screenshot != null) {
        print('Screenshot captured successfully: ${screenshot.id}');
      } else {
        print('Failed to capture screenshot');
      }
    } finally {
      _isCapturingScreenshot = false;
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

  /// Handle idle state - pause timer but keep elapsed time
  void _handleIdle() {
    if (_isRunning && !_isPausedDueToIdle) {
      print('User went idle - pausing timer and window tracking');
      _isPausedDueToIdle = true;
      _idleStartTime = DateTime.now();
      print('Idle start time recorded: $_idleStartTime');
      print('Elapsed time at idle: $_elapsedSeconds seconds (preserved)');

      // Cancel the tick timer to prevent screenshots during idle
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
        print('Timer paused (no screenshots during idle)');
      }

      // Pause window tracking
      _windowTracker.stopTracking();

      // Notify listeners about idle state
      onIdleStateChanged?.call(true);
    }
  }

  /// Handle active state - resume timer with immediate screenshot
  void _handleActive() {
    if (_isRunning && _isPausedDueToIdle && _activeTaskId != null) {
      print('\n=== USER ACTIVE AGAIN ===');
      print('Resuming timer and window tracking');
      print('Elapsed time before idle: $_elapsedSeconds seconds');

      // Calculate idle duration
      if (_idleStartTime != null) {
        final idleDuration = DateTime.now().difference(_idleStartTime!);
        final idleDurationMs = idleDuration.inMilliseconds;
        print(
          'Idle duration: ${idleDuration.inSeconds} seconds ($idleDurationMs ms)',
        );

        // Notify about idle duration to update task
        onIdleDurationCalculated?.call(idleDurationMs);
      }

      _isPausedDueToIdle = false;
      _idleStartTime = null;

      print('Resuming at $_elapsedSeconds seconds');
      print('Last screenshot was at: $_lastScreenshotAtSecond seconds');
      print('Next screenshot will be at next minute mark');

      // Don't take screenshot on idle resume - only at minute marks

      // Resume tick timer
      if (_timer == null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          // Get current task to check active duration (excludes paused time)
          final currentTask = await DatabaseHelper.instance.getTaskById(_activeTaskId!);
          if (currentTask == null || !currentTask.isActive) {
            return;
          }
          
          // Calculate active seconds (excludes paused time)
          final activeSeconds = currentTask.activeDuration.inSeconds;
          
          // Check if we've passed the interval since last screenshot (based on ACTIVE time)
          final intervalSeconds = _intervalMinutes * 60;
          final secondsSinceLastScreenshot = activeSeconds - _lastScreenshotAtSecond;
          
          if (secondsSinceLastScreenshot >= intervalSeconds) {
            print('\n=== TIME FOR SCREENSHOT (60 ACTIVE SECONDS PASSED) ===');
            print('Active time now: $activeSeconds seconds (${(activeSeconds / 60).toInt()}:${(activeSeconds % 60).toString().padLeft(2, '0')})');
            print('Last screenshot at: $_lastScreenshotAtSecond seconds');
            print('Active seconds since last screenshot: $secondsSinceLastScreenshot');
            await _captureScreenshot();
            _lastScreenshotAtSecond = activeSeconds;
            print('Next screenshot when active time reaches: ${_lastScreenshotAtSecond + intervalSeconds} seconds');
            print('=== SCREENSHOT COMPLETE ===\n');
          }
        });
        print('Timer resumed (Interval: $_intervalMinutes minutes)');
      }

      // Resume window tracking
      _windowTracker.startTracking(_activeTaskId!);

      // Notify listeners about active state
      onIdleStateChanged?.call(false);
      
      print('=== IDLE RESUME COMPLETE ===\n');
    }
  }

  /// Check if timer is paused due to idle
  bool get isPausedDueToIdle => _isPausedDueToIdle;

  /// Get current idle duration in milliseconds (if currently idle)
  int? getCurrentIdleDuration() {
    if (_isPausedDueToIdle && _idleStartTime != null) {
      return DateTime.now().difference(_idleStartTime!).inMilliseconds;
    }
    return null;
  }

  /// Dispose the timer service
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isPausedDueToIdle = false;
    _idleStartTime = null;
    _activeTaskId = null;
    _elapsedSeconds = 0;
    _lastScreenshotAtSecond = 0;
    _isCapturingScreenshot = false;
    _idleDetector.stopMonitoring();
  }
}
