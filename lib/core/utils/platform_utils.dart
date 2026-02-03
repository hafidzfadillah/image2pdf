import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform utility functions
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on Android
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Check if running on iOS
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Check if running on mobile platform
  static bool get isMobile => isAndroid || isIOS;

  /// Get platform name
  static String get platformName {
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
