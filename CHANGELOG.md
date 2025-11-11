# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-XX

### Added
- Initial release of Image to PDF converter app
- Camera functionality to capture multiple images
- PDF generation from captured images
- Preview screen to view generated PDFs
- Save PDFs to device storage (Downloads folder) accessible to other apps

### Changed
- **Storage Implementation**: Migrated from app-private storage to device storage
  - Android 10+ (API 29+): Uses MediaStore API for saving PDFs to Downloads folder
  - Android 9 and below: Uses direct file access with storage permissions
  - iOS: Saves to Documents directory (accessible via Files app)
- Removed dependency on `MANAGE_EXTERNAL_STORAGE` permission
  - Now uses MediaStore API which doesn't require special permissions on Android 10+

### Technical Details
- Implemented platform channel in `MainActivity.kt` for Android file operations
- Added proper permission handling for different Android versions
- PDF files are saved with timestamp-based filenames
- Files are accessible to other apps and appear in Downloads folder

### Fixed
- PDF files now save to device storage instead of app-private storage
- Files are accessible to file managers, email clients, and other apps

