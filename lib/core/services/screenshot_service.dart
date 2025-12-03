/// Screenshot Service
/// Handles screenshot capture with platform-specific implementations
/// - Windows: Silent capture using GDI+ (no sound/flash)
/// - macOS/Linux: Uses screen_capturer plugin
library;

import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import '../utils/file_helper.dart';
import '../constants/app_constants.dart';
import '../../models/screenshot_model.dart';
import 'database_helper.dart';

class ScreenshotService {
  final ScreenCapturer _screenCapturer = ScreenCapturer.instance;
  final _uuid = const Uuid();

  /// Capture a screenshot and save it locally
  /// Returns ScreenshotModel if successful, null otherwise
  /// Uses platform-specific implementation:
  /// - Windows: Silent GDI+ capture (no sound/flash)
  /// - macOS/Linux: screen_capturer plugin
  Future<ScreenshotModel?> captureScreenshot(String taskId) async {
    try {
      // Generate unique filename
      final screenshotId = _uuid.v4();
      final fileName = '$screenshotId.${AppConstants.screenshotFormat}';
      final filePath = await FileHelper.getScreenshotPath(fileName);

      // Use platform-specific capture method
      bool success = false;
      if (Platform.isWindows) {
        // Windows: Use silent GDI+ capture
        print('Using Windows GDI+ capture (silent)');
        success = await _captureWindowsSilent(filePath);
      } else {
        // macOS/Linux: Use screen_capturer plugin
        print('Using screen_capturer plugin (${Platform.operatingSystem})');
        success = await _captureUsingPlugin(filePath);
      }

      if (success) {
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

      print('Screenshot capture failed - no data returned');
      return null;
    } catch (e) {
      print('Error capturing screenshot: $e');
      return null;
    }
  }

  /// Capture screenshot using screen_capturer plugin (macOS/Linux)
  Future<bool> _captureUsingPlugin(String filePath) async {
    try {
      final capturedData = await _screenCapturer.capture(
        mode: CaptureMode.screen,
        imagePath: filePath,
        silent: true, // Works well on macOS/Linux
      );
      return capturedData != null && capturedData.imagePath != null;
    } catch (e) {
      print('Plugin capture error: $e');
      return false;
    }
  }

  /// Capture screenshot using Windows GDI+ (100% silent, no effects)
  Future<bool> _captureWindowsSilent(String filePath) async {
    try {
      // Get screen device context
      final screenDC = GetDC(NULL);
      if (screenDC == 0) {
        print('Failed to get screen DC');
        return false;
      }

      // Create compatible DC for bitmap
      final memoryDC = CreateCompatibleDC(screenDC);
      if (memoryDC == 0) {
        ReleaseDC(NULL, screenDC);
        print('Failed to create memory DC');
        return false;
      }

      try {
        // Get screen dimensions
        final screenWidth = GetSystemMetrics(SM_CXSCREEN);
        final screenHeight = GetSystemMetrics(SM_CYSCREEN);

        // Create bitmap to store screenshot
        final bitmap = CreateCompatibleBitmap(screenDC, screenWidth, screenHeight);
        if (bitmap == 0) {
          print('Failed to create bitmap');
          return false;
        }

        // Select bitmap into memory DC
        final oldBitmap = SelectObject(memoryDC, bitmap);

        // Copy screen to bitmap (THIS IS COMPLETELY SILENT!)
        final bitBltResult = BitBlt(
          memoryDC,
          0,
          0,
          screenWidth,
          screenHeight,
          screenDC,
          0,
          0,
          SRCCOPY,
        );

        if (bitBltResult == 0) {
          SelectObject(memoryDC, oldBitmap);
          DeleteObject(bitmap);
          print('Failed to copy screen to bitmap');
          return false;
        }

        // Get bitmap data
        final bitmapInfo = calloc<BITMAPINFO>();
        bitmapInfo.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
        bitmapInfo.ref.bmiHeader.biWidth = screenWidth;
        bitmapInfo.ref.bmiHeader.biHeight = -screenHeight; // Top-down bitmap
        bitmapInfo.ref.bmiHeader.biPlanes = 1;
        bitmapInfo.ref.bmiHeader.biBitCount = 32; // BGRA format
        bitmapInfo.ref.bmiHeader.biCompression = BI_RGB;

        // Calculate buffer size
        final bufferSize = screenWidth * screenHeight * 4; // 4 bytes per pixel (BGRA)
        final buffer = calloc<Uint8>(bufferSize);

        // Get bitmap bits
        final linesRead = GetDIBits(
          memoryDC,
          bitmap,
          0,
          screenHeight,
          buffer,
          bitmapInfo,
          DIB_RGB_COLORS,
        );

        if (linesRead == 0) {
          calloc.free(buffer);
          calloc.free(bitmapInfo);
          SelectObject(memoryDC, oldBitmap);
          DeleteObject(bitmap);
          print('Failed to get bitmap bits');
          return false;
        }

        // Convert BGRA to RGBA for image package
        final pixels = buffer.asTypedList(bufferSize);
        final rgbaPixels = Uint8List(bufferSize);
        for (int i = 0; i < bufferSize; i += 4) {
          rgbaPixels[i] = pixels[i + 2];     // R = B
          rgbaPixels[i + 1] = pixels[i + 1]; // G = G
          rgbaPixels[i + 2] = pixels[i];     // B = R
          rgbaPixels[i + 3] = pixels[i + 3]; // A = A
        }

        // Create image and encode to PNG
        final image = img.Image.fromBytes(
          width: screenWidth,
          height: screenHeight,
          bytes: rgbaPixels.buffer,
          numChannels: 4,
        );
        final pngBytes = img.encodePng(image);

        // Write to file
        await File(filePath).writeAsBytes(pngBytes);

        // Cleanup
        calloc.free(buffer);
        calloc.free(bitmapInfo);
        SelectObject(memoryDC, oldBitmap);
        DeleteObject(bitmap);

        return true;
      } finally {
        // Always cleanup DCs
        DeleteDC(memoryDC);
        ReleaseDC(NULL, screenDC);
      }
    } catch (e) {
      print('Windows GDI+ capture error: $e');
      return false;
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
