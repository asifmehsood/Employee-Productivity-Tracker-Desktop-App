/// Screenshot Provider
/// Manages screenshot state, upload operations, and synchronization
library;

import 'package:flutter/foundation.dart';
import '../models/screenshot_model.dart';
import '../core/services/database_helper.dart';
import '../core/services/screenshot_service.dart';
import '../core/services/azure_service.dart';
import '../core/constants/azure_config.dart';

class ScreenshotProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ScreenshotService _screenshotService = ScreenshotService();
  late AzureService _azureService;

  List<ScreenshotModel> _screenshots = [];
  bool _isUploading = false;
  final bool _isSyncing = false;
  int _uploadProgress = 0;

  // Getters
  List<ScreenshotModel> get screenshots => _screenshots;
  bool get isUploading => _isUploading;
  bool get isSyncing => _isSyncing;
  int get uploadProgress => _uploadProgress;

  List<ScreenshotModel> get pendingUploads =>
      _screenshots.where((s) => !s.uploaded).toList();
  List<ScreenshotModel> get uploadedScreenshots =>
      _screenshots.where((s) => s.uploaded).toList();
  List<ScreenshotModel> get pendingSync =>
      _screenshots.where((s) => s.uploaded && !s.syncedToOdoo).toList();

  /// Initialize provider and services
  Future<void> initialize({
    required AzureConfig azureConfig,
  }) async {
    _azureService = AzureService(azureConfig);
    await loadScreenshots();
  }

  /// Update Azure configuration
  void updateAzureConfig(AzureConfig config) {
    _azureService.updateConfig(config);
  }

  /// Load all screenshots from database
  Future<void> loadScreenshots() async {
    try {
      _screenshots = await _db.getAllScreenshots();
      notifyListeners();
    } catch (e) {
      print('Error loading screenshots: $e');
    }
  }

  /// Load screenshots for a specific task
  Future<List<ScreenshotModel>> loadTaskScreenshots(String taskId) async {
    try {
      return await _db.getScreenshotsByTask(taskId);
    } catch (e) {
      print('Error loading task screenshots: $e');
      return [];
    }
  }

  /// Capture a manual screenshot
  Future<ScreenshotModel?> captureManual(String taskId) async {
    try {
      final screenshot = await _screenshotService.captureScreenshot(taskId);
      if (screenshot != null) {
        _screenshots.insert(0, screenshot);
        notifyListeners();
      }
      return screenshot;
    } catch (e) {
      print('Error capturing manual screenshot: $e');
      return null;
    }
  }

  /// Upload a single screenshot to Azure
  Future<bool> uploadScreenshot(ScreenshotModel screenshot) async {
    try {
      _isUploading = true;
      notifyListeners();

      final success = await _azureService.uploadScreenshot(screenshot);

      if (success) {
        // Reload screenshots to get updated data
        await loadScreenshots();
      }

      _isUploading = false;
      notifyListeners();

      return success;
    } catch (e) {
      print('Error uploading screenshot: $e');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload all pending screenshots to Azure
  Future<Map<String, int>> uploadAllPending() async {
    _isUploading = true;
    _uploadProgress = 0;
    notifyListeners();

    final results = await _azureService.uploadPendingScreenshots();

    _isUploading = false;
    _uploadProgress = 100;
    notifyListeners();

    await loadScreenshots();

    return results;
  }

  /// Delete a screenshot
  Future<bool> deleteScreenshot(ScreenshotModel screenshot) async {
    try {
      final success = await _screenshotService.deleteScreenshot(screenshot);
      if (success) {
        _screenshots.removeWhere((s) => s.id == screenshot.id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error deleting screenshot: $e');
      return false;
    }
  }

  /// Clean up old screenshots
  Future<int> cleanupOld({int olderThanDays = 30}) async {
    try {
      final deletedCount = await _screenshotService.cleanupOldScreenshots(
        olderThanDays: olderThanDays,
      );
      
      if (deletedCount > 0) {
        await loadScreenshots();
      }
      
      return deletedCount;
    } catch (e) {
      print('Error cleaning up old screenshots: $e');
      return 0;
    }
  }

  /// Test Azure connection
  Future<bool> testAzureConnection() async {
    return await _azureService.testConnection();
  }
}
