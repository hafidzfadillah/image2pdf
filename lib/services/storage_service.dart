import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/core/utils/platform_utils.dart';

/// Service for handling file storage operations
class StorageService {
  StorageService._();

  /// Save PDF to Downloads folder (Android) or Documents (iOS)
  static Future<String?> savePdfToDownloads(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    if (PlatformUtils.isAndroid) {
      return _savePdfToDownloadsAndroid(pdfBytes, fileName);
    } else if (PlatformUtils.isIOS) {
      return _savePdfToDownloadsIOS(pdfBytes, fileName);
    } else {
      // Fallback for other platforms
      return _savePdfToTemp(pdfBytes, fileName);
    }
  }

  /// Save PDF to Downloads on Android using MediaStore API
  static Future<String?> _savePdfToDownloadsAndroid(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      // First, save to temporary app directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfBytes);

      // Use platform channel to save to Downloads using MediaStore
      const platform = MethodChannel(AppConstants.storageChannel);
      final result = await platform.invokeMethod<String>(
        AppConstants.savePdfMethod,
        {
          'filePath': tempFile.path,
          'fileName': fileName,
        },
      );

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Save PDF to Documents directory on iOS
  static Future<String?> _savePdfToDownloadsIOS(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final file = File('${documentsDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Save PDF to temporary directory (fallback)
  static Future<String?> _savePdfToTemp(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Get temporary file path for preview
  static Future<String> getTempFilePath(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/$fileName';
  }
}

