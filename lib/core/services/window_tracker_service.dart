/// Window Tracker Service
/// Tracks active window and application usage on Windows
library;

import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:uuid/uuid.dart';
import '../services/database_helper.dart';
import '../../models/app_usage_model.dart';

class WindowTrackerService {
  static final WindowTrackerService _instance = WindowTrackerService._internal();
  factory WindowTrackerService() => _instance;
  WindowTrackerService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Timer? _trackingTimer;
  String? _currentTaskId;
  String _lastWindowTitle = '';
  String _lastAppName = '';
  DateTime _lastWindowChangeTime = DateTime.now();
  bool _isTracking = false;

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Get the currently active window title
  String? getActiveWindowTitle() {
    try {
      final hwnd = GetForegroundWindow();
      if (hwnd == 0) return null;

      final length = GetWindowTextLength(hwnd);
      if (length == 0) return null;

      final buffer = wsalloc(length + 1);
      GetWindowText(hwnd, buffer, length + 1);
      final title = buffer.toDartString();
      free(buffer);

      return title.isNotEmpty ? title : null;
    } catch (e) {
      print('Error getting window title: $e');
      return null;
    }
  }

  /// Extract website URL from browser window title
  String _extractWebsiteFromTitle(String title, String appName) {
    final appLower = appName.toLowerCase();
    
    // Check if it's a browser
    if (appLower.contains('chrome') || appLower.contains('edge') || 
        appLower.contains('firefox') || appLower.contains('opera') || 
        appLower.contains('brave')) {
      
      // Common patterns in browser titles
      // Chrome/Edge: "Page Title - Website" or "Website - Page Title"
      // Try to extract domain from title
      
      // Remove common browser indicators
      String cleanTitle = title
          .replaceAll(' - Google Chrome', '')
          .replaceAll(' - Microsoft​ Edge', '')
          .replaceAll(' - Mozilla Firefox', '')
          .replaceAll(' - Opera', '')
          .replaceAll(' - Brave', '')
          .trim();
      
      // Look for common domain patterns
      final domainPatterns = [
        RegExp(r'(github\.com)', caseSensitive: false),
        RegExp(r'(whatsapp\.com|web\.whatsapp\.com)', caseSensitive: false),
        RegExp(r'(facebook\.com)', caseSensitive: false),
        RegExp(r'(twitter\.com|x\.com)', caseSensitive: false),
        RegExp(r'(linkedin\.com)', caseSensitive: false),
        RegExp(r'(youtube\.com)', caseSensitive: false),
        RegExp(r'(instagram\.com)', caseSensitive: false),
        RegExp(r'(stackoverflow\.com)', caseSensitive: false),
        RegExp(r'(reddit\.com)', caseSensitive: false),
        RegExp(r'(gmail\.com|mail\.google\.com)', caseSensitive: false),
      ];
      
      for (final pattern in domainPatterns) {
        final match = pattern.firstMatch(cleanTitle.toLowerCase());
        if (match != null) {
          final domain = match.group(1)!;
          // Format nicely
          if (domain.contains('whatsapp')) return 'WhatsApp Web';
          if (domain.contains('github')) return 'GitHub';
          if (domain.contains('facebook')) return 'Facebook';
          if (domain.contains('twitter') || domain.contains('x.com')) return 'Twitter/X';
          if (domain.contains('linkedin')) return 'LinkedIn';
          if (domain.contains('youtube')) return 'YouTube';
          if (domain.contains('instagram')) return 'Instagram';
          if (domain.contains('stackoverflow')) return 'Stack Overflow';
          if (domain.contains('reddit')) return 'Reddit';
          if (domain.contains('gmail') || domain.contains('mail.google')) return 'Gmail';
        }
      }
      
      // Try to extract domain from URL-like patterns in title
      final urlPattern = RegExp(r'https?://([^/\s]+)', caseSensitive: false);
      final urlMatch = urlPattern.firstMatch(cleanTitle);
      if (urlMatch != null) {
        final domain = urlMatch.group(1)!;
        // Clean up domain (remove www., etc.)
        return domain.replaceFirst('www.', '').split('.').first.toUpperCase();
      }
      
      // If title contains recognizable website name
      if (cleanTitle.toLowerCase().contains('github')) return 'GitHub';
      if (cleanTitle.toLowerCase().contains('whatsapp')) return 'WhatsApp Web';
      if (cleanTitle.toLowerCase().contains('facebook')) return 'Facebook';
      if (cleanTitle.toLowerCase().contains('youtube')) return 'YouTube';
      if (cleanTitle.toLowerCase().contains('twitter') || cleanTitle.toLowerCase().contains(' x ')) return 'Twitter/X';
      if (cleanTitle.toLowerCase().contains('linkedin')) return 'LinkedIn';
      if (cleanTitle.toLowerCase().contains('instagram')) return 'Instagram';
      if (cleanTitle.toLowerCase().contains('stack overflow')) return 'Stack Overflow';
      if (cleanTitle.toLowerCase().contains('reddit')) return 'Reddit';
      if (cleanTitle.toLowerCase().contains('gmail')) return 'Gmail';
      
      // Return generic browser name with title hint
      if (cleanTitle.length > 50) {
        return '$appName (${cleanTitle.substring(0, 47)}...)';
      }
      return '$appName ($cleanTitle)';
    }
    
    return appName;
  }
  
  /// Improve app name display
  String _formatAppName(String rawName) {
    final nameLower = rawName.toLowerCase();
    
    // Map common app names to better display names
    final nameMap = {
      'code': 'VS Code',
      'devenv': 'Visual Studio',
      'chrome': 'Google Chrome',
      'msedge': 'Microsoft Edge',
      'firefox': 'Mozilla Firefox',
      'explorer': 'File Explorer',
      'notepad': 'Notepad',
      'notepad++': 'Notepad++',
      'cmd': 'Command Prompt',
      'powershell': 'PowerShell',
      'slack': 'Slack',
      'teams': 'Microsoft Teams',
      'discord': 'Discord',
      'spotify': 'Spotify',
      'vlc': 'VLC Media Player',
      'winword': 'Microsoft Word',
      'excel': 'Microsoft Excel',
      'powerpnt': 'Microsoft PowerPoint',
      'outlook': 'Microsoft Outlook',
    };
    
    return nameMap[nameLower] ?? rawName;
  }

  /// Get the application name from window handle
  String? getApplicationName() {
    try {
      final hwnd = GetForegroundWindow();
      if (hwnd == 0) return null;

      final processId = calloc<DWORD>();
      GetWindowThreadProcessId(hwnd, processId);

      final hProcess = OpenProcess(
        PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
        FALSE,
        processId.value,
      );

      if (hProcess == 0) {
        free(processId);
        return null;
      }

      final exePathBuffer = wsalloc(MAX_PATH);
      final size = calloc<DWORD>();
      size.value = MAX_PATH;

      QueryFullProcessImageName(hProcess, 0, exePathBuffer, size);
      final fullPath = exePathBuffer.toDartString();

      CloseHandle(hProcess);
      free(processId);
      free(exePathBuffer);
      free(size);

      // Extract just the exe name from full path
      if (fullPath.isNotEmpty) {
        final parts = fullPath.split('\\');
        final exeName = parts.last.replaceAll('.exe', '');
        return _formatAppName(exeName);
      }

      return null;
    } catch (e) {
      print('Error getting application name: $e');
      return null;
    }
  }

  /// Start tracking windows for a task
  Future<void> startTracking(String taskId) async {
    if (_isTracking) {
      print('Window tracking already running');
      return;
    }

    print('\n=== STARTING WINDOW TRACKING ===');
    print('Task ID: $taskId');

    _currentTaskId = taskId;
    _isTracking = true;
    _lastWindowChangeTime = DateTime.now();

    // Get initial window info
    _lastWindowTitle = getActiveWindowTitle() ?? '';
    final rawAppName = getApplicationName() ?? 'Unknown';
    _lastAppName = _extractWebsiteFromTitle(_lastWindowTitle, rawAppName);
    print('Initial window: $_lastAppName - $_lastWindowTitle');

    // Track every 5 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkWindowChange();
    });

    print('Window tracking started');
    print('=== WINDOW TRACKING STARTED ===\n');
  }

  /// Check if window has changed and save data
  void _checkWindowChange() async {
    if (!_isTracking || _currentTaskId == null) return;

    try {
      final currentWindowTitle = getActiveWindowTitle() ?? '';
      final rawAppName = getApplicationName() ?? 'Unknown';
      final currentAppName = _extractWebsiteFromTitle(currentWindowTitle, rawAppName);

      // Check if window/app changed
      if (currentWindowTitle != _lastWindowTitle || currentAppName != _lastAppName) {
        print('\n--- Window Changed ---');
        print('Previous: $_lastAppName - $_lastWindowTitle');
        print('Current: $currentAppName - $currentWindowTitle');

        // Calculate duration for previous window
        final now = DateTime.now();
        final duration = now.difference(_lastWindowChangeTime).inSeconds;

        if (duration > 0 && _lastAppName.isNotEmpty) {
          // Save previous window usage data
          final appUsage = AppUsageModel(
            id: _uuid.v4(),
            taskId: _currentTaskId!,
            appName: _lastAppName,
            windowTitle: _lastWindowTitle,
            durationSeconds: duration,
            timestamp: _lastWindowChangeTime,
            createdAt: DateTime.now(),
          );

          try {
            await _db.insertAppUsage(appUsage);
            print('Saved: $_lastAppName for $duration seconds');
          } catch (e) {
            print('Error saving app usage: $e');
          }
        }

        // Update tracking variables
        _lastWindowTitle = currentWindowTitle;
        _lastAppName = currentAppName;
        _lastWindowChangeTime = now;
        print('--- Window Change Recorded ---\n');
      }
    } catch (e) {
      print('Error checking window change: $e');
    }
  }

  /// Stop tracking windows
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    print('\n=== STOPPING WINDOW TRACKING ===');

    // Save final window usage data
    if (_currentTaskId != null && _lastAppName.isNotEmpty) {
      final now = DateTime.now();
      final duration = now.difference(_lastWindowChangeTime).inSeconds;

      if (duration > 0) {
        final appUsage = AppUsageModel(
          id: _uuid.v4(),
          taskId: _currentTaskId!,
          appName: _lastAppName,
          windowTitle: _lastWindowTitle,
          durationSeconds: duration,
          timestamp: _lastWindowChangeTime,
          createdAt: DateTime.now(),
        );

        try {
          await _db.insertAppUsage(appUsage);
          print('Saved final window: $_lastAppName for $duration seconds');
        } catch (e) {
          print('Error saving final app usage: $e');
        }
      }
    }

    _trackingTimer?.cancel();
    _trackingTimer = null;
    _currentTaskId = null;
    _isTracking = false;
    _lastWindowTitle = '';
    _lastAppName = '';

    print('Window tracking stopped');
    print('=== WINDOW TRACKING STOPPED ===\n');
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
