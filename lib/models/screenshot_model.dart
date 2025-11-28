/// Screenshot Model
/// Represents a captured screenshot with metadata
/// Tracks local storage, Azure URL, and sync status
library;

class ScreenshotModel {
  final String id;
  final String taskId;
  final String localPath;
  final String? azureUrl;
  final DateTime capturedAt;
  final bool uploaded;
  final bool syncedToOdoo;
  
  ScreenshotModel({
    required this.id,
    required this.taskId,
    required this.localPath,
    this.azureUrl,
    required this.capturedAt,
    this.uploaded = false,
    this.syncedToOdoo = false,
  });
  
  // Check if file exists locally
  bool get hasLocalFile => localPath.isNotEmpty;
  
  // Check if uploaded to Azure
  bool get hasAzureUrl => azureUrl != null && azureUrl!.isNotEmpty;
  
  // Get status string
  String get statusText {
    if (syncedToOdoo) return 'Synced';
    if (uploaded) return 'Uploaded';
    return 'Pending';
  }
  
  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'local_path': localPath,
      'azure_url': azureUrl,
      'captured_at': capturedAt.millisecondsSinceEpoch,
      'uploaded': uploaded ? 1 : 0,
      'synced_to_odoo': syncedToOdoo ? 1 : 0,
    };
  }
  
  // Create from Map
  factory ScreenshotModel.fromMap(Map<String, dynamic> map) {
    return ScreenshotModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      localPath: map['local_path'] as String,
      azureUrl: map['azure_url'] as String?,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(map['captured_at'] as int),
      uploaded: (map['uploaded'] as int) == 1,
      syncedToOdoo: (map['synced_to_odoo'] as int) == 1,
    );
  }
  
  // Convert to JSON for Odoo
  Map<String, dynamic> toOdooJson() {
    return {
      'task_id': taskId,
      'screenshot_url': azureUrl,
      'captured_at': capturedAt.toIso8601String(),
      'external_id': id,
    };
  }
  
  // Copy with updated fields
  ScreenshotModel copyWith({
    String? id,
    String? taskId,
    String? localPath,
    String? azureUrl,
    DateTime? capturedAt,
    bool? uploaded,
    bool? syncedToOdoo,
  }) {
    return ScreenshotModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      localPath: localPath ?? this.localPath,
      azureUrl: azureUrl ?? this.azureUrl,
      capturedAt: capturedAt ?? this.capturedAt,
      uploaded: uploaded ?? this.uploaded,
      syncedToOdoo: syncedToOdoo ?? this.syncedToOdoo,
    );
  }
}
