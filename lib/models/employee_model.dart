/// Employee Model
/// Represents an employee/user of the productivity tracker

class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final DateTime createdAt;
  
  EmployeeModel({
    required this.id,
    required this.name,
    this.email = '',
    this.department = '',
    required this.createdAt,
  });
  
  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
  
  // Create from Map
  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String? ?? '',
      department: map['department'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
  
  // Convert to JSON for Odoo
  Map<String, dynamic> toOdooJson() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'external_id': id,
    };
  }
  
  // Copy with updated fields
  EmployeeModel copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
