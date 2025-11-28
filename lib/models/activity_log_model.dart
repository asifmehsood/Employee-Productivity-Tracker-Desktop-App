/// Activity Log Model
/// Tracks user activity for idle detection
library;

class ActivityLogModel {
  final String id;
  final String taskId;
  final DateTime timestamp;
  final String activityType; // 'active', 'idle', 'away'
  final String? details; // Mouse movement, keyboard input, app name, etc.
  
  ActivityLogModel({
    required this.id,
    required this.taskId,
    required this.timestamp,
    required this.activityType,
    this.details,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'timestamp': timestamp.toIso8601String(),
      'activity_type': activityType,
      'details': details,
    };
  }
  
  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      activityType: map['activity_type'] as String,
      details: map['details'] as String?,
    );
  }
}
