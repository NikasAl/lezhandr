import 'package:flutter/material.dart';

/// Global notification service for showing snackbars from anywhere
/// Works even when user navigates away from the originating screen
class NotificationService {
  NotificationService._();
  
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Show a success notification
  static void showSuccess(String message, {Duration duration = const Duration(seconds: 4)}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.check_circle_outline,
    );
  }

  /// Show an info notification
  static void showInfo(String message, {Duration duration = const Duration(seconds: 4)}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info_outline,
    );
  }

  /// Show a warning notification
  static void showWarning(String message, {Duration duration = const Duration(seconds: 5)}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning_amber_outlined,
    );
  }

  /// Show an error notification
  static void showError(String message, {Duration duration = const Duration(seconds: 5)}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error_outline,
    );
  }

  /// Show AI result notification (special style for AI operations)
  static void showAiResult({
    required String title,
    required String details,
    required bool success,
    Duration duration = const Duration(seconds: 5),
  }) {
    final context = scaffoldMessengerKey.currentContext;
    if (context == null) {
      _showSnackBar(
        message: '$title: $details',
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        icon: success ? Icons.psychology : Icons.error_outline,
      );
      return;
    }

    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                success ? Icons.psychology : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  static void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 4),
  }) {
    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  /// Clear all notifications
  static void clearAll() {
    scaffoldMessengerKey.currentState?.clearSnackBars();
  }
}
