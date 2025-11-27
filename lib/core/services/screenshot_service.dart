/// Screenshot Service
/// Handles screenshot capture using screen_capturer plugin
/// Supports Windows, macOS, and Linux desktop platforms
library;

import 'dart:io';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:uuid/uuid.dart';
import '../utils/file_helper.dart';
import '../constants/app_constants.dart';
import '../../models/screenshot_model.dart';
import 'database_helper.dart';

class ScreenshotService {
  final ScreenCapturer _screenCapturer = ScreenCapturer.instance;
  final _uuid = const Uuid();

  /// Capture a screenshot and save it locally
  /// Returns ScreenshotModel if successful, null otherwise
  Future<ScreenshotModel?> captureScreenshot(String taskId) async {
    try {
      // Generate unique filename
      final screenshotId = _uuid.v4();
      final fileName = '$screenshotId.${AppConstants.screenshotFormat}';
      final filePath = await FileHelper.getScreenshotPath(fileName);

      // Capture the screenshot with retry mechanism
      CapturedData? capturedData;
      int retries = 2;
      
      for (int i = 0; i < retries; i++) {
        capturedData = await _screenCapturer.capture(
          mode: CaptureMode.screen,
          imagePath: filePath,
          silent: true, // Capture silently without notification
        );
        
        if (capturedData != null && capturedData.imagePath != null) {
          break;
        }
        
        // Wait a bit before retry
        if (i < retries - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (capturedData != null && capturedData.imagePath != null) {
        // Create screenshot model
        final screenshot = ScreenshotModel(
          id: screenshotId,
          taskId: taskId,
          localPath: filePath,
          capturedAt: DateTime.now(),
        );

        // Save to database
        await DatabaseHelper.instance.insertScreenshot(screenshot);

        print('Screenshot captured: $filePath');
        return screenshot;
      }

      print('Screenshot capture failed - no data returned after retries');
      return null;
    } catch (e) {
      print('Error capturing screenshot: $e');
      return null;
    }
  }

  /// Capture screenshot with specific region (optional feature)
  Future<ScreenshotModel?> captureRegion(
    String taskId, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      final screenshotId = _uuid.v4();
      final fileName = '$screenshotId.${AppConstants.screenshotFormat}';
      final filePath = await FileHelper.getScreenshotPath(fileName);

      final capturedData = await _screenCapturer.capture(
        mode: CaptureMode.region,
        imagePath: filePath,
        silent: true,
      );

      if (capturedData != null && capturedData.imagePath != null) {
        final screenshot = ScreenshotModel(
          id: screenshotId,
          taskId: taskId,
          localPath: filePath,
          capturedAt: DateTime.now(),
        );

        await DatabaseHelper.instance.insertScreenshot(screenshot);
        return screenshot;
      }

      return null;
    } catch (e) {
      print('Error capturing region screenshot: $e');
      return null;
    }
  }

  /// Check if screenshot capture is supported on current platform
  Future<bool> isSupported() async {
    try {
      return await _screenCapturer.isAccessAllowed();
    } catch (e) {
      print('Error checking screenshot support: $e');
      return false;
    }
  }

  /// Request screen capture permission (mainly for macOS)
  Future<bool> requestPermission() async {
    try {
      if (Platform.isMacOS) {
        final isAllowed = await _screenCapturer.isAccessAllowed();
        if (!isAllowed) {
          await _screenCapturer.requestAccess(
            onlyOpenPrefPane: false,
          );
        }
        return await _screenCapturer.isAccessAllowed();
      }
      return true; // Other platforms don't need explicit permission
    } catch (e) {
      print('Error requesting screenshot permission: $e');
      return false;
    }
  }

  /// Get all screenshots for a specific task
  Future<List<ScreenshotModel>> getTaskScreenshots(String taskId) async {
    return await DatabaseHelper.instance.getScreenshotsByTask(taskId);
  }

  /// Delete a screenshot (both file and database record)
  Future<bool> deleteScreenshot(ScreenshotModel screenshot) async {
    try {
      // Delete file
      await FileHelper.deleteFile(screenshot.localPath);
      
      // Delete database record
      await DatabaseHelper.instance.deleteScreenshot(screenshot.id);
      
      return true;
    } catch (e) {
      print('Error deleting screenshot: $e');
      return false;
    }
  }

  /// Clean up old screenshots
  Future<int> cleanupOldScreenshots({int olderThanDays = 30}) async {
    try {
      return await FileHelper.deleteOldScreenshots(
        olderThanDays: olderThanDays,
      );
    } catch (e) {
      print('Error cleaning up old screenshots: $e');
      return 0;
    }
  }
}
