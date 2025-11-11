# Image to PDF Converter

A Flutter application that allows users to capture multiple images using the device camera and convert them into a single PDF document.

## Features

- 📷 **Camera Integration**: Capture multiple images using your device's camera
- 📄 **PDF Generation**: Convert captured images into a single PDF document
- 👁️ **Preview**: Preview generated PDFs before saving
- 💾 **Device Storage**: Save PDFs to Downloads folder (accessible to other apps)
- 🔒 **Permission Handling**: Automatic permission requests for camera and storage

## Screenshots

_Add screenshots here when available_

## Requirements

- Flutter SDK 3.6.0 or higher
- Dart SDK 3.6.0 or higher
- Android SDK (for Android development)
- iOS SDK (for iOS development)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd image_to_pdf
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Permissions

### Android
- **Camera**: Required to capture images
- **Storage** (Android 9 and below): Required to save PDFs to Downloads folder
- **No special permissions needed** for Android 10+ (uses MediaStore API)

### iOS
- **Camera**: Required to capture images
- **Photo Library**: May be requested depending on iOS version

## How It Works

1. **Capture Images**: Tap the capture button to take photos
2. **Review**: View captured images in the horizontal scroll view
3. **Generate PDF**: Tap "Generate PDF" to create a PDF from all captured images
4. **Save**: PDF is automatically saved to Downloads folder (Android) or Documents (iOS)
5. **Preview**: View the generated PDF in the preview screen

## Storage Locations

- **Android 10+**: Downloads folder (via MediaStore API)
- **Android 9 and below**: Downloads folder (direct file access)
- **iOS**: Documents directory (accessible via Files app)

PDFs saved to these locations are accessible to:
- File managers
- Email clients
- Cloud storage apps
- Other applications

## Dependencies

- `camera: ^0.11.2` - Camera functionality
- `pdf: ^3.11.3` - PDF generation
- `path_provider: ^2.1.5` - File system paths
- `permission_handler: ^12.0.1` - Permission management

## Project Structure

```
lib/
├── main.dart                 # App entry point
└── screen/
    ├── camera_screen.dart    # Main camera and PDF generation screen
    └── preview_screen.dart   # PDF preview screen

android/
└── app/
    └── src/
        └── main/
            ├── kotlin/
            │   └── com/example/image_to_pdf/
            │       └── MainActivity.kt  # Platform channel for file operations
            └── AndroidManifest.xml      # App permissions and configuration
```

## Development

### Building for Android

```bash
flutter build apk
# or
flutter build appbundle
```

### Building for iOS

```bash
flutter build ios
```

## Technical Implementation

### Android File Storage

The app uses different approaches based on Android version:

- **Android 10+ (API 29+)**: Uses `MediaStore.Downloads` API via platform channel
  - No special permissions required
  - Files are saved to Downloads folder
  - Accessible to all apps

- **Android 9 and below**: Direct file system access
  - Requires `WRITE_EXTERNAL_STORAGE` permission
  - Uses `Environment.getExternalStoragePublicDirectory()`

### Platform Channel

A platform channel is implemented in `MainActivity.kt` to handle file operations:
- Method: `savePdfToDownloads`
- Parameters: `filePath`, `fileName`
- Returns: URI of saved file

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

_Add license information here_

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.
