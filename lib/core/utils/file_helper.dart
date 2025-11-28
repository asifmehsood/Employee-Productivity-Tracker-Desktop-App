/// File Helper
/// Utility functions for file operations, path management, and cleanup
library;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class FileHelper {
  /// Get the screenshots directory path
  static Future<Directory> getScreenshotsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final screenshotsDir = Directory(
      path.join(appDir.path, AppConstants.appName, AppConstants.screenshotsFolder),
    );
    
    if (!await screenshotsDir.exists()) {
      await screenshotsDir.create(recursive: true);
    }
    
    return screenshotsDir;
  }

  /// Get the logs directory path
  static Future<Directory> getLogsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory(
      path.join(appDir.path, AppConstants.appName, AppConstants.logsFolder),
    );
    
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    
    return logsDir;
  }

  /// Get full path for a screenshot file
  static Future<String> getScreenshotPath(String fileName) async {
    final dir = await getScreenshotsDirectory();
    return path.join(dir.path, fileName);
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Get file size in readable format (KB, MB, etc.)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Delete a file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Delete old screenshots (older than specified days)
  static Future<int> deleteOldScreenshots({int olderThanDays = 30}) async {
    try {
      final screenshotsDir = await getScreenshotsDirectory();
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      int deletedCount = 0;

      await for (final entity in screenshotsDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      print('Error deleting old screenshots: $e');
      return 0;
    }
  }

  /// Get total size of screenshots directory
  static Future<int> getScreenshotsDirectorySize() async {
    try {
      final screenshotsDir = await getScreenshotsDirectory();
      int totalSize = 0;

      await for (final entity in screenshotsDir.list()) {
        if (entity is File) {
          final size = await entity.length();
          totalSize += size;
        }
      }

      return totalSize;
    } catch (e) {
      print('Error calculating directory size: $e');
      return 0;
    }
  }

  /// Count files in screenshots directory
  static Future<int> getScreenshotsCount() async {
    try {
      final screenshotsDir = await getScreenshotsDirectory();
      int count = 0;

      await for (final entity in screenshotsDir.list()) {
        if (entity is File) {
          count++;
        }
      }

      return count;
    } catch (e) {
      print('Error counting screenshots: $e');
      return 0;
    }
  }

  /// Clean up empty directories
  static Future<void> cleanupEmptyDirectories() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final appFolder = Directory(path.join(appDir.path, AppConstants.appName));

      if (await appFolder.exists()) {
        await for (final entity in appFolder.list()) {
          if (entity is Directory) {
            final isEmpty = await entity.list().isEmpty;
            if (isEmpty) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up directories: $e');
    }
  }

  /// Copy file to another location
  static Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        return true;
      }
      return false;
    } catch (e) {
      print('Error copying file: $e');
      return false;
    }
  }

  /// Validate file extension
  static bool isValidImageFile(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.bmp'].contains(ext);
  }

  /// Get file name from path
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Get directory from path
  static String getDirectory(String filePath) {
    return path.dirname(filePath);
  }
}
