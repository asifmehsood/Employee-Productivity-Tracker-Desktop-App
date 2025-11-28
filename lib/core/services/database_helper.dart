/// Database Helper
/// Manages SQLite database operations for tasks, screenshots, and settings
/// Uses sqflite_common_ffi for desktop platform support
library;

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/task_model.dart';
import '../../models/screenshot_model.dart';
import '../../models/app_usage_model.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (singleton pattern)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Initialize database with proper desktop support
  Future<Database> _initDB() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Get application documents directory
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, AppConstants.databaseName);

    return await openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        employee_name TEXT NOT NULL,
        task_name TEXT NOT NULL,
        task_description TEXT,
        status TEXT DEFAULT 'active',
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        paused_at INTEGER,
        total_paused_duration INTEGER DEFAULT 0,
        scheduled_start_time INTEGER,
        scheduled_end_time INTEGER,
        created_at INTEGER NOT NULL,
        synced_to_odoo INTEGER DEFAULT 0
      )
    ''');

    // Screenshots table
    await db.execute('''
      CREATE TABLE screenshots (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        local_path TEXT NOT NULL,
        azure_url TEXT,
        captured_at INTEGER NOT NULL,
        uploaded INTEGER DEFAULT 0,
        synced_to_odoo INTEGER DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // App Usage table
    await db.execute('''
      CREATE TABLE app_usage (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        app_name TEXT NOT NULL,
        window_title TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_task_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_task_employee ON tasks(employee_id)');
    await db.execute('CREATE INDEX idx_screenshot_task ON screenshots(task_id)');
    await db.execute('CREATE INDEX idx_screenshot_uploaded ON screenshots(uploaded)');
    await db.execute('CREATE INDEX idx_app_usage_task ON app_usage(task_id)');
    await db.execute('CREATE INDEX idx_app_usage_app ON app_usage(app_name)');
  }

  /// Handle database upgrades
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here when database schema changes
    if (oldVersion < 2) {
      // Add activity_logs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id TEXT PRIMARY KEY,
          task_id TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          activity_type TEXT NOT NULL,
          details TEXT,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        )
      ''');
      
      // Add work_sessions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS work_sessions (
          id TEXT PRIMARY KEY,
          employee_id TEXT NOT NULL,
          date INTEGER NOT NULL,
          total_minutes_worked INTEGER DEFAULT 0,
          total_minutes_idle INTEGER DEFAULT 0,
          tasks_completed INTEGER DEFAULT 0,
          tasks_started INTEGER DEFAULT 0
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Add scheduled time columns to tasks table
      await db.execute('ALTER TABLE tasks ADD COLUMN scheduled_start_time INTEGER');
      await db.execute('ALTER TABLE tasks ADD COLUMN scheduled_end_time INTEGER');
    }
    
    if (oldVersion < 4) {
      // Add pause tracking columns
      await db.execute('ALTER TABLE tasks ADD COLUMN paused_at INTEGER');
      await db.execute('ALTER TABLE tasks ADD COLUMN total_paused_duration INTEGER DEFAULT 0');
    }
    
    if (oldVersion < 5) {
      // Add app_usage table for window tracking
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_usage (
          id TEXT PRIMARY KEY,
          task_id TEXT NOT NULL,
          app_name TEXT NOT NULL,
          window_title TEXT NOT NULL,
          duration_seconds INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_app_usage_task ON app_usage(task_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_app_usage_app ON app_usage(app_name)');
    }
  }

  // ==================== TASK OPERATIONS ====================

  /// Insert a new task
  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  /// Get all tasks
  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;
    final result = await db.query('tasks', orderBy: 'created_at DESC');
    return result.map((map) => TaskModel.fromMap(map)).toList();
  }

  /// Get tasks by status
  Future<List<TaskModel>> getTasksByStatus(String status) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => TaskModel.fromMap(map)).toList();
  }

  /// Get active task (only one should be active at a time)
  Future<TaskModel?> getActiveTask() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'status = ?',
      whereArgs: [AppConstants.taskStatusActive],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return TaskModel.fromMap(result.first);
  }

  /// Get task by ID
  Future<TaskModel?> getTaskById(String id) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return TaskModel.fromMap(result.first);
  }

  /// Update task
  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Delete task
  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unsynced tasks
  Future<List<TaskModel>> getUnsyncedTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'synced_to_odoo = ?',
      whereArgs: [AppConstants.syncStatusPending],
    );
    return result.map((map) => TaskModel.fromMap(map)).toList();
  }

  // ==================== SCREENSHOT OPERATIONS ====================

  /// Insert a new screenshot
  Future<int> insertScreenshot(ScreenshotModel screenshot) async {
    final db = await database;
    return await db.insert('screenshots', screenshot.toMap());
  }

  /// Get all screenshots for a task
  Future<List<ScreenshotModel>> getScreenshotsByTask(String taskId) async {
    final db = await database;
    final result = await db.query(
      'screenshots',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'captured_at DESC',
    );
    return result.map((map) => ScreenshotModel.fromMap(map)).toList();
  }

  /// Get all screenshots
  Future<List<ScreenshotModel>> getAllScreenshots() async {
    final db = await database;
    final result = await db.query('screenshots', orderBy: 'captured_at DESC');
    return result.map((map) => ScreenshotModel.fromMap(map)).toList();
  }

  /// Update screenshot
  Future<int> updateScreenshot(ScreenshotModel screenshot) async {
    final db = await database;
    return await db.update(
      'screenshots',
      screenshot.toMap(),
      where: 'id = ?',
      whereArgs: [screenshot.id],
    );
  }

  /// Delete screenshot
  Future<int> deleteScreenshot(String id) async {
    final db = await database;
    return await db.delete(
      'screenshots',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unsynced screenshots
  Future<List<ScreenshotModel>> getUnsyncedScreenshots() async {
    final db = await database;
    final result = await db.query(
      'screenshots',
      where: 'synced_to_odoo = ?',
      whereArgs: [AppConstants.syncStatusPending],
    );
    return result.map((map) => ScreenshotModel.fromMap(map)).toList();
  }

  /// Get screenshots that need to be uploaded to Azure
  Future<List<ScreenshotModel>> getScreenshotsToUpload() async {
    final db = await database;
    final result = await db.query(
      'screenshots',
      where: 'uploaded = ?',
      whereArgs: [AppConstants.syncStatusPending],
    );
    return result.map((map) => ScreenshotModel.fromMap(map)).toList();
  }

  // ==================== SETTINGS OPERATIONS ====================

  /// Save a setting
  Future<int> saveSetting(String key, String value) async {
    final db = await database;
    return await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  /// Delete a setting
  Future<int> deleteSetting(String key) async {
    final db = await database;
    return await db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Get all settings
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final result = await db.query('settings');
    return Map.fromEntries(
      result.map((row) => MapEntry(row['key'] as String, row['value'] as String)),
    );
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Get statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final totalTasksResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
    final totalTasks = totalTasksResult.first['count'] as int? ?? 0;
    
    final activeTasksResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE status = ?',
      [AppConstants.taskStatusActive],
    );
    final activeTasks = activeTasksResult.first['count'] as int? ?? 0;
    
    final completedTasksResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE status = ?',
      [AppConstants.taskStatusCompleted],
    );
    final completedTasks = completedTasksResult.first['count'] as int? ?? 0;
    
    final totalScreenshotsResult = await db.rawQuery('SELECT COUNT(*) as count FROM screenshots');
    final totalScreenshots = totalScreenshotsResult.first['count'] as int? ?? 0;
    
    final uploadedScreenshotsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM screenshots WHERE uploaded = 1',
    );
    final uploadedScreenshots = uploadedScreenshotsResult.first['count'] as int? ?? 0;

    return {
      'totalTasks': totalTasks,
      'activeTasks': activeTasks,
      'completedTasks': completedTasks,
      'totalScreenshots': totalScreenshots,
      'uploadedScreenshots': uploadedScreenshots,
    };
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('screenshots');
    await db.delete('tasks');
    await db.delete('settings');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
  
  // ==================== ACTIVITY LOG OPERATIONS ====================
  
  /// Insert activity log
  Future<void> insertActivityLog(dynamic activityLog) async {
    final db = await database;
    await db.insert('activity_logs', activityLog.toMap());
  }
  
  /// Get activity logs for a task
  Future<List<Map<String, dynamic>>> getActivityLogsForTask(String taskId) async {
    final db = await database;
    return await db.query(
      'activity_logs',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'timestamp DESC',
    );
  }
  
  // ==================== WORK SESSION OPERATIONS ====================
  
  /// Get or create work session for date
  Future<Map<String, dynamic>> getWorkSessionForDate(String employeeId, DateTime date) async {
    final db = await database;
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final result = await db.query(
      'work_sessions',
      where: 'employee_id = ? AND date = ?',
      whereArgs: [employeeId, dateOnly.millisecondsSinceEpoch],
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    
    // Return empty session
    return {
      'total_minutes_worked': 0,
      'total_minutes_idle': 0,
      'tasks_completed': 0,
      'tasks_started': 0,
    };
  }
  
  /// Update work session
  Future<void> updateWorkSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.insert(
      'work_sessions',
      session,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // ==================== APP USAGE OPERATIONS ====================
  
  /// Insert app usage data
  Future<int> insertAppUsage(AppUsageModel appUsage) async {
    final db = await database;
    return await db.insert('app_usage', appUsage.toMap());
  }
  
  /// Get all app usage data for a task
  Future<List<AppUsageModel>> getAppUsageForTask(String taskId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_usage',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'timestamp ASC',
    );
    
    return List.generate(maps.length, (i) {
      return AppUsageModel.fromMap(maps[i]);
    });
  }
  
  /// Get aggregated app usage statistics
  Future<List<Map<String, dynamic>>> getAggregatedAppUsage({String? taskId, DateTime? date}) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (taskId != null) {
      whereClause = 'task_id = ?';
      whereArgs.add(taskId);
    } else if (date != null) {
      // Get all app usage for tasks on this date
      final dateStart = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
      whereClause = 'timestamp >= ? AND timestamp <= ?';
      whereArgs.addAll([dateStart, dateEnd]);
    }
    
    final query = '''
      SELECT app_name, 
             SUM(duration_seconds) as total_duration,
             COUNT(*) as usage_count
      FROM app_usage
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY app_name
      ORDER BY total_duration DESC
    ''';
    
    return await db.rawQuery(query, whereArgs);
  }
  
  /// Get recent app usage data (for dashboard)
  Future<List<Map<String, dynamic>>> getRecentAppUsage({int limit = 10}) async {
    final db = await database;
    
    // Get app usage from today
    final today = DateTime.now();
    final dateStart = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
    
    final query = '''
      SELECT app_name, 
             SUM(duration_seconds) as duration_seconds,
             COUNT(*) as usage_count
      FROM app_usage
      WHERE timestamp >= ?
      GROUP BY app_name
      ORDER BY duration_seconds DESC
      LIMIT ?
    ''';
    
    return await db.rawQuery(query, [dateStart, limit]);
  }
  
  /// Delete app usage data for a task
  Future<int> deleteAppUsageForTask(String taskId) async {
    final db = await database;
    return await db.delete(
      'app_usage',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }
}
