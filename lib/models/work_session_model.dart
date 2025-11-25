/// Work Session Model
/// Represents a daily work session summary for calendar view

class WorkSessionModel {
  final String id;
  final String employeeId;
  final DateTime date;
  final int totalMinutesWorked;
  final int totalMinutesIdle;
  final int tasksCompleted;
  final int tasksStarted;
  
  WorkSessionModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.totalMinutesWorked,
    required this.totalMinutesIdle,
    required this.tasksCompleted,
    required this.tasksStarted,
  });
  
  String get formattedDuration {
    final hours = totalMinutesWorked ~/ 60;
    final minutes = totalMinutesWorked % 60;
    return '${hours}h ${minutes}m';
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date.toIso8601String(),
      'total_minutes_worked': totalMinutesWorked,
      'total_minutes_idle': totalMinutesIdle,
      'tasks_completed': tasksCompleted,
      'tasks_started': tasksStarted,
    };
  }
  
  factory WorkSessionModel.fromMap(Map<String, dynamic> map) {
    return WorkSessionModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      date: DateTime.parse(map['date'] as String),
      totalMinutesWorked: map['total_minutes_worked'] as int,
      totalMinutesIdle: map['total_minutes_idle'] as int,
      tasksCompleted: map['tasks_completed'] as int,
      tasksStarted: map['tasks_started'] as int,
    );
  }
}
