/// Idle Detection Service
/// Monitors user activity to detect idle state

import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../models/activity_log_model.dart';
import 'database_helper.dart';

class IdleDetectionService {
  Timer? _activityCheckTimer;
  DateTime _lastActivityTime = DateTime.now();
  bool _isIdle = false;
  String? _currentTaskId;
  final _uuid = const Uuid();
  
  // Idle threshold in seconds (default 5 minutes)
  static const int idleThresholdSeconds = 300;
  
  // Callback when idle state changes
  Function(bool isIdle)? onIdleStateChanged;
  
  /// Start monitoring for idle activity
  void startMonitoring(String taskId) {
    _currentTaskId = taskId;
    _lastActivityTime = DateTime.now();
    _isIdle = false;
    
    // Check activity every 30 seconds
    _activityCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkIdleState(),
    );
    
    _logActivity('active', 'Monitoring started');
  }
  
  /// Stop monitoring
  void stopMonitoring() {
    _activityCheckTimer?.cancel();
    _activityCheckTimer = null;
    _currentTaskId = null;
  }
  
  /// Register user activity (call this when mouse/keyboard events detected)
  void registerActivity() {
    _lastActivityTime = DateTime.now();
    
    if (_isIdle) {
      _isIdle = false;
      onIdleStateChanged?.call(false);
      _logActivity('active', 'User resumed activity');
    }
  }
  
  /// Check if user is idle
  void _checkIdleState() {
    final now = DateTime.now();
    final secondsSinceActivity = now.difference(_lastActivityTime).inSeconds;
    
    if (!_isIdle && secondsSinceActivity >= idleThresholdSeconds) {
      // User became idle
      _isIdle = true;
      onIdleStateChanged?.call(true);
      _logActivity('idle', 'No activity detected for $secondsSinceActivity seconds');
    }
  }
  
  /// Log activity to database
  Future<void> _logActivity(String activityType, String? details) async {
    if (_currentTaskId == null) return;
    
    final log = ActivityLogModel(
      id: _uuid.v4(),
      taskId: _currentTaskId!,
      timestamp: DateTime.now(),
      activityType: activityType,
      details: details,
    );
    
    await DatabaseHelper.instance.insertActivityLog(log);
  }
  
  /// Check if currently idle
  bool get isIdle => _isIdle;
  
  /// Get seconds since last activity
  int get secondsSinceLastActivity {
    return DateTime.now().difference(_lastActivityTime).inSeconds;
  }
}
