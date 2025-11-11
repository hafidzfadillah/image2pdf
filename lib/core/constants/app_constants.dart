/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Image to PDF';
  static const String appTitle = 'Camera to PDF';

  // File Naming
  static const String pdfFileNamePrefix = 'captured_images_';
  static const String pdfFileExtension = '.pdf';

  // Platform Channels
  static const String storageChannel = 'image_to_pdf/storage';
  static const String savePdfMethod = 'savePdfToDownloads';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const int snackBarDurationSeconds = 3;
  static const int imageThumbnailSize = 80;
  static const int imageThumbnailHeight = 100;
}

