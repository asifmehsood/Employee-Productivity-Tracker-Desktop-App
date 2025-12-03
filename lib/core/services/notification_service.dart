/// Notification Service
/// Handles native OS notifications for desktop platforms
/// Shows Windows toast notifications outside the app window
library;

import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  
  NotificationService._init();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize local notifier
    await localNotifier.setup(
      appName: 'Employee Productivity Tracker',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  /// Show a native OS notification
  /// [title] - Notification title
  /// [body] - Notification message
  /// [silent] - Whether to play sound (default: false)
  Future<void> showNotification({
    required String title,
    required String body,
    bool silent = false,
  }) async {
    try {
      final notification = LocalNotification(
        title: title,
        body: body,
        silent: silent,
      );

      await notification.show();
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Show screenshot captured notification
  Future<void> showScreenshotNotification() async {
    await showNotification(
      title: '📸 Screenshot Captured',
      body: 'Screenshot saved successfully',
      silent: true, // No sound for screenshots
    );
  }

  /// Show idle notification
  Future<void> showIdleNotification() async {
    await showNotification(
      title: '⏸️ Timer Paused',
      body: 'You\'ve been idle for 1 minute. Timer paused automatically.',
      silent: false,
    );
  }

  /// Show active notification
  Future<void> showActiveNotification() async {
    await showNotification(
      title: '▶️ Timer Resumed',
      body: 'Welcome back! Timer resumed.',
      silent: false,
    );
  }

  /// Show work session started notification
  Future<void> showWorkSessionStarted() async {
    await showNotification(
      title: '✅ Work Session Started',
      body: 'Tracking in progress...',
      silent: false,
    );
  }
}
