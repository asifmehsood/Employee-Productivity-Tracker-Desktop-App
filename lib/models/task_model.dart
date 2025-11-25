/// Task Model
/// Represents a work task that an employee is tracking
/// Includes timing information, status, and sync state
library;

class TaskModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String taskName;
  final String taskDescription;
  final String status; // active, paused, completed
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? pausedAt; // When the task was paused
  final int totalPausedDuration; // Total paused duration in milliseconds
  final DateTime? scheduledStartTime; // Scheduled start time from user
  final DateTime? scheduledEndTime;   // Scheduled end time from user
  final DateTime createdAt;
  final bool syncedToOdoo;
  
  TaskModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.taskName,
    required this.taskDescription,
    required this.status,
    required this.startTime,
    this.endTime,
    this.pausedAt,
    this.totalPausedDuration = 0,
    this.scheduledStartTime,
    this.scheduledEndTime,
    required this.createdAt,
    this.syncedToOdoo = false,
  });
  
  // Calculate duration
  Duration get duration {
    final now = DateTime.now();
    final end = endTime ?? now;
    
    // If task hasn't started yet (scheduled for future), return zero duration
    if (startTime.isAfter(now)) {
      return Duration.zero;
    }
    
    var calculatedDuration = end.difference(startTime);
    
    // Subtract total paused duration
    calculatedDuration = calculatedDuration - Duration(milliseconds: totalPausedDuration);
    
    // If currently paused, don't include current pause time
    if (isPaused && pausedAt != null) {
      final currentPauseDuration = now.difference(pausedAt!);
      calculatedDuration = calculatedDuration - currentPauseDuration;
    }
    
    // Ensure non-negative duration
    if (calculatedDuration.isNegative) {
      return Duration.zero;
    }
    
    return calculatedDuration;
  }
  
  // Format duration as HH:MM:SS
  String get formattedDuration {
    final d = duration;
    final totalHours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final formatted = '${totalHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return formatted;
  }
  
  // Check if task is currently active
  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';
  
  // Convert to Map for database storage
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
      'paused_at': pausedAt?.millisecondsSinceEpoch,
      'total_paused_duration': totalPausedDuration,
      'scheduled_start_time': scheduledStartTime?.millisecondsSinceEpoch,
      'scheduled_end_time': scheduledEndTime?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'synced_to_odoo': syncedToOdoo ? 1 : 0,
    };
  }
  
  // Create from Map (database retrieval)
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      employeeName: map['employee_name'] as String,
      taskName: map['task_name'] as String,
      taskDescription: map['task_description'] as String? ?? '',
      status: map['status'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      pausedAt: map['paused_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['paused_at'] as int)
          : null,
      totalPausedDuration: map['total_paused_duration'] as int? ?? 0,
      scheduledStartTime: map['scheduled_start_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_start_time'] as int)
          : null,
      scheduledEndTime: map['scheduled_end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_end_time'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      syncedToOdoo: (map['synced_to_odoo'] as int) == 1,
    );
  }
  
  // Convert to JSON for Odoo API
  Map<String, dynamic> toOdooJson() {
    return {
      'name': taskName,
      'description': taskDescription,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_hours': duration.inMinutes / 60.0,
      'status': status,
      'external_id': id, // Reference to local database
    };
  }
  
  // Create a copy with updated fields
  TaskModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? taskName,
    String? taskDescription,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pausedAt,
    int? totalPausedDuration,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    DateTime? createdAt,
    bool? syncedToOdoo,
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
      pausedAt: pausedAt,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      createdAt: createdAt ?? this.createdAt,
      syncedToOdoo: syncedToOdoo ?? this.syncedToOdoo,
    );
  }
}
