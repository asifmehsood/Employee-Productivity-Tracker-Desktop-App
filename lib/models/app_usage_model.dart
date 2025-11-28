/// App Usage Model
/// Represents application/window usage data during task execution
library;

class AppUsageModel {
  final String id;
  final String taskId;
  final String appName;
  final String windowTitle;
  final int durationSeconds;
  final DateTime timestamp;
  final DateTime createdAt;

  AppUsageModel({
    required this.id,
    required this.taskId,
    required this.appName,
    required this.windowTitle,
    required this.durationSeconds,
    required this.timestamp,
    required this.createdAt,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'app_name': appName,
      'window_title': windowTitle,
      'duration_seconds': durationSeconds,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create from Map (database retrieval)
  factory AppUsageModel.fromMap(Map<String, dynamic> map) {
    return AppUsageModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      appName: map['app_name'] as String,
      windowTitle: map['window_title'] as String,
      durationSeconds: map['duration_seconds'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  // Create a copy with optional field updates
  AppUsageModel copyWith({
    String? id,
    String? taskId,
    String? appName,
    String? windowTitle,
    int? durationSeconds,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return AppUsageModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      appName: appName ?? this.appName,
      windowTitle: windowTitle ?? this.windowTitle,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppUsageModel(id: $id, taskId: $taskId, appName: $appName, windowTitle: $windowTitle, durationSeconds: $durationSeconds, timestamp: $timestamp)';
  }
}
