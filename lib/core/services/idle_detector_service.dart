/// Idle Detector Service
/// Monitors keyboard and mouse activity to detect user idleness
library;

import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class IdleDetectorService {
  static final IdleDetectorService _instance = IdleDetectorService._internal();
  factory IdleDetectorService() => _instance;
  IdleDetectorService._internal();

  Timer? _checkTimer;
  DateTime _lastActivityTime = DateTime.now();
  DateTime _monitoringStartTime = DateTime.now();
  bool _isIdle = false;
  bool _isMonitoring = false;

  // Callbacks
  Function()? onIdle;
  Function()? onActive;

  // Configuration
  final Duration idleThreshold = const Duration(minutes: 1);
  final Duration checkInterval = const Duration(seconds: 5);

  /// Check if user is currently idle
  bool get isIdle => _isIdle;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Get time since last activity
  Duration get timeSinceLastActivity =>
      DateTime.now().difference(_lastActivityTime);

  /// Start monitoring for idle activity
  void startMonitoring({
    Function()? onIdleCallback,
    Function()? onActiveCallback,
  }) {
    if (_isMonitoring) {
      print('Idle monitoring already running');
      return;
    }

    print('\n=== STARTING IDLE MONITORING ===');
    onIdle = onIdleCallback;
    onActive = onActiveCallback;

    _isMonitoring = true;
    _isIdle = false;
    _lastActivityTime = DateTime.now();
    _monitoringStartTime = DateTime.now(); // Record when monitoring started

    // Check for activity every 5 seconds
    _checkTimer = Timer.periodic(checkInterval, (timer) {
      _checkActivity();
    });

    print('Idle monitoring started (threshold: ${idleThreshold.inSeconds}s)');
    print('Monitoring start time: $_monitoringStartTime');
    print('=== IDLE MONITORING STARTED ===\n');
  }

  /// Stop monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    print('\n=== STOPPING IDLE MONITORING ===');
    _checkTimer?.cancel();
    _checkTimer = null;
    _isMonitoring = false;
    _isIdle = false;

    print('Idle monitoring stopped');
    print('=== IDLE MONITORING STOPPED ===\n');
  }

  /// Check for user activity using Windows API
  void _checkActivity() {
    try {
      final lastInputInfo = calloc<LASTINPUTINFO>();
      lastInputInfo.ref.cbSize = sizeOf<LASTINPUTINFO>();

      // Get last input info from Windows
      final result = GetLastInputInfo(lastInputInfo);

      if (result != 0) {
        final lastInputTime = lastInputInfo.ref.dwTime;
        final currentTickCount = GetTickCount();
        final systemIdleMilliseconds = currentTickCount - lastInputTime;
        final systemIdleDuration = Duration(milliseconds: systemIdleMilliseconds);

        print('--- Activity Check ---');
        print('System idle time: ${systemIdleDuration.inSeconds}s');

        // If system idle is less than 2 seconds, user is currently active
        if (systemIdleDuration < const Duration(seconds: 2)) {
          // User is active - update last activity time
          _lastActivityTime = DateTime.now();
          print('User is ACTIVE - last activity updated to: $_lastActivityTime');

          // If we were idle, trigger active callback
          if (_isIdle) {
            final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
            print('\n>>> USER BECAME ACTIVE <<<');
            print('Was idle for: ${timeSinceLastActivity.inSeconds}s');
            _isIdle = false;
            onActive?.call();
          }
        } else {
          // System is idle - check if idle for long enough SINCE last activity
          final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
          print('Time since last activity: ${timeSinceLastActivity.inSeconds}s (threshold: ${idleThreshold.inSeconds}s)');

          // Only trigger idle if user has been inactive for the full threshold duration
          if (timeSinceLastActivity >= idleThreshold && !_isIdle) {
            print('\n>>> USER BECAME IDLE <<<');
            print(
              'Idle for: ${timeSinceLastActivity.inSeconds}s (threshold: ${idleThreshold.inSeconds}s)',
            );
            _isIdle = true;
            onIdle?.call();
          }
        }

        print('Current idle state: ${_isIdle ? "IDLE" : "ACTIVE"}');
        print('--- End Check ---\n');
      }

      free(lastInputInfo);
    } catch (e) {
      print('Error checking activity: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
