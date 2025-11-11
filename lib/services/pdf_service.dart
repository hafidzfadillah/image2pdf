import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/services/storage_service.dart';
import 'package:image_to_pdf/services/permission_service.dart';
import 'package:image_to_pdf/core/utils/platform_utils.dart';

/// Service for PDF generation and management
class PdfService {
  PdfService._();

  /// Generate PDF from list of image files
  static Future<PdfResult> generatePdfFromImages(
    List<File> imageFiles,
  ) async {
    if (imageFiles.isEmpty) {
      throw Exception('No images provided');
    }

    // Request storage permission for Android 9 and below
    if (PlatformUtils.isAndroid) {
      await PermissionService.requestStoragePermission();
    }

    // Create PDF document
    final pdf = pw.Document();

    // Add each image as a page
    for (final imageFile in imageFiles) {
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    // Generate filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${AppConstants.pdfFileNamePrefix}$timestamp${AppConstants.pdfFileExtension}';
    final pdfBytes = await pdf.save();

    // Save PDF to device storage
    final savedPath = await StorageService.savePdfToDownloads(pdfBytes, fileName);

    // Create temp file for preview
    final tempPath = await StorageService.getTempFilePath(fileName);
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(pdfBytes);

    return PdfResult(
      fileName: fileName,
      savedPath: savedPath ?? tempPath,
      previewPath: tempPath,
      pageCount: imageFiles.length,
    );
  }
}

/// Result of PDF generation
class PdfResult {
  final String fileName;
  final String savedPath;
  final String previewPath;
  final int pageCount;

  const PdfResult({
    required this.fileName,
    required this.savedPath,
    required this.previewPath,
    required this.pageCount,
  });
}

