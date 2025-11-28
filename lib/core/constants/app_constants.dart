/// App Constants
/// Contains all constant values used throughout the application
/// including screenshot intervals, API endpoints, and app settings
library;

class AppConstants {
  // App Information
  static const String appName = 'Employee Productivity Tracker';
  static const String appVersion = '1.0.0';
  
  // Screenshot Settings
  static const int defaultScreenshotIntervalMinutes = 5;
  static const int minScreenshotIntervalMinutes = 1;
  static const int maxScreenshotIntervalMinutes = 60;
  static const String screenshotFormat = 'png';
  static const int screenshotQuality = 90; // 0-100
  
  // Local Storage Paths
  static const String screenshotsFolder = 'screenshots';
  static const String logsFolder = 'logs';
  
  // Database
  static const String databaseName = 'productivity_tracker.db';
  static const int databaseVersion = 5;
  
  // Task Status
  static const String taskStatusActive = 'active';
  static const String taskStatusPaused = 'paused';
  static const String taskStatusCompleted = 'completed';
  
  // Sync Status
  static const int syncStatusPending = 0;
  static const int syncStatusSynced = 1;
  static const int syncStatusFailed = 2;
  
  // Settings Keys (SharedPreferences)
  static const String settingsScreenshotInterval = 'screenshot_interval';
  static const String settingsAzureStorageAccount = 'azure_storage_account';
  static const String settingsAzureAccessKey = 'azure_access_key';
  static const String settingsAzureContainerName = 'azure_container_name';
  static const String settingsOdooUrl = 'odoo_url';
  static const String settingsOdooDatabase = 'odoo_database';
  static const String settingsOdooUsername = 'odoo_username';
  static const String settingsOdooPassword = 'odoo_password';
  static const String settingsEmployeeId = 'employee_id';
  static const String settingsEmployeeName = 'employee_name';
  static const String settingsAutoStartOnBoot = 'auto_start_on_boot';
  static const String settingsMinimizeToTray = 'minimize_to_tray';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 2.0;
  
  // Window Settings (Desktop)
  // Optimized for 13-inch laptop screens (1280x720)
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;
  static const double defaultWindowWidth = 1000.0;
  static const double defaultWindowHeight = 650.0;
  
  // API Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int uploadTimeoutSeconds = 120;
  
  // Retry Settings
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 5;
  
  // File Naming Pattern
  static String getScreenshotFileName(String employeeId, String taskId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${employeeId}_${taskId}_$timestamp.$screenshotFormat';
  }
}
