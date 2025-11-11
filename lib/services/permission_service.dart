import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions
class PermissionService {
  PermissionService._();

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permission (for Android 9 and below)
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }
}

