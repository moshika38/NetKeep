import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service class to encapsulate runtime permission checks and requests.
class PermissionService {
  /// Checks if the notification permission (`POST_NOTIFICATIONS`) is granted.
  ///
  /// If the permission is not granted, automatically prompts the user with
  /// the system notification permission dialog on supported platforms (Android 13+).
  /// If already granted, does nothing and returns [PermissionStatus.granted].
  static Future<PermissionStatus> checkAndRequestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      debugPrint('PermissionService: Notification status is $status');

      if (status.isGranted) {
        return status;
      }

      // Automatically request permission if not already granted
      final requestedStatus = await Permission.notification.request();
      debugPrint('PermissionService: User responded with $requestedStatus');
      return requestedStatus;
    } catch (e) {
      debugPrint('PermissionService: Error checking/requesting notification permission: $e');
      return PermissionStatus.denied;
    }
  }
}
