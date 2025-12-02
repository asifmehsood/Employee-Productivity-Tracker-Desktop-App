/// Task Model
/// Represents a work session/task with timing and status information
library;

import '../core/constants/app_constants.dart';

class TaskModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String taskName;
  final String taskDescription;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? scheduledStartTime;
  final DateTime? scheduledEndTime;
  final DateTime? pausedAt;
  final int totalPausedDuration; // in milliseconds
  final DateTime createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.taskName,
    required this.taskDescription,
    required this.status,
    required this.startTime,
    this.endTime,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.pausedAt,
    this.totalPausedDuration = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Status checks
  bool get isActive => status == AppConstants.taskStatusActive;
  bool get isPaused => status == AppConstants.taskStatusPaused;
  bool get isCompleted => status == AppConstants.taskStatusCompleted;
  bool get isRunning => isActive && pausedAt == null;

  // Duration calculations
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Duration get activeDuration {
    final totalDuration = duration;
    var pausedDuration = Duration(milliseconds: totalPausedDuration);
    
    // If currently paused (idle or manual), add the current pause duration
    if (pausedAt != null) {
      final currentPauseDuration = DateTime.now().difference(pausedAt!);
      pausedDuration = pausedDuration + currentPauseDuration;
    }
    
    final result = totalDuration - pausedDuration;
    // Ensure duration doesn't go negative
    return result.isNegative ? Duration.zero : result;
  }

  // Get duration considering current time if not ended
  Duration getDuration(DateTime currentTime) {
    final end = endTime ?? currentTime;
    return end.difference(startTime);
  }

  // Formatted duration string (HH:MM:SS)
  String get formattedDuration {
    final d = activeDuration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'task_name': taskName,
      'task_description': taskDescription,
      'status': status,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'scheduled_start_time': scheduledStartTime?.millisecondsSinceEpoch,
      'scheduled_end_time': scheduledEndTime?.millisecondsSinceEpoch,
      'paused_at': pausedAt?.millisecondsSinceEpoch,
      'total_paused_duration': totalPausedDuration,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create from Map (from database)
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      employeeName: map['employee_name'] as String,
      taskName: map['task_name'] as String,
      taskDescription: map['task_description'] as String,
      status: map['status'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      scheduledStartTime: map['scheduled_start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_start_time'] as int)
          : null,
      scheduledEndTime: map['scheduled_end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_end_time'] as int)
          : null,
      pausedAt: map['paused_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paused_at'] as int)
          : null,
      totalPausedDuration: map['total_paused_duration'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  // Copy with method for creating modified copies
  TaskModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? taskName,
    String? taskDescription,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    DateTime? pausedAt,
    int? totalPausedDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      taskName: taskName ?? this.taskName,
      taskDescription: taskDescription ?? this.taskDescription,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      pausedAt: pausedAt ?? this.pausedAt,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, taskName: $taskName, status: $status, startTime: $startTime)';
  }
}
