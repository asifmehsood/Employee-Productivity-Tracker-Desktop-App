/// Task Model
/// Represents a work task that an employee is tracking
/// Includes timing information, status, and sync state

class TaskModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String taskName;
  final String taskDescription;
  final String status; // active, paused, completed
  final DateTime startTime;
  final DateTime? endTime;
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
    required this.createdAt,
    this.syncedToOdoo = false,
  });
  
  // Calculate duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  // Format duration as HH:MM:SS
  String get formattedDuration {
    final d = duration;
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
      createdAt: createdAt ?? this.createdAt,
      syncedToOdoo: syncedToOdoo ?? this.syncedToOdoo,
    );
  }
}
