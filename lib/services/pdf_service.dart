import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/core/models/pdf_settings.dart';
import 'package:image_to_pdf/services/storage_service.dart';
import 'package:image_to_pdf/services/permission_service.dart';
import 'package:image_to_pdf/core/utils/platform_utils.dart';
import 'package:image_to_pdf/features/canvas/models/canvas_image_item.dart';

/// Service for PDF generation and management
class PdfService {
  PdfService._();

  /// Generate PDF from list of image files with settings
  static Future<PdfResult> generatePdfFromImages(
    List<File> imageFiles, {
    PdfSettings? settings,
  }) async {
    if (imageFiles.isEmpty) {
      throw Exception('No images provided');
    }

    final pdfSettings = settings ?? const PdfSettings();

    // Request storage permission for Android 9 and below
    if (PlatformUtils.isAndroid) {
      await PermissionService.requestStoragePermission();
    }

    // Create PDF document
    final pdf = pw.Document();

    // Add each image as a page
    for (final imageFile in imageFiles) {
      var imageBytes = await imageFile.readAsBytes();
      
      // Compress image based on quality setting
      if (pdfSettings.imageQuality != ImageQuality.high) {
        final decodedImage = img.decodeImage(imageBytes);
        if (decodedImage != null) {
          final quality = pdfSettings.imageQuality.compressionQuality;
          imageBytes = Uint8List.fromList(
            img.encodeJpg(decodedImage, quality: quality),
          );
        }
      }

      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: pdfSettings.effectivePageFormat,
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

  /// Generate PDF from canvas layout.
  static Future<PdfResult> generatePdfFromCanvas({
    required double canvasWidth,
    required double canvasHeight,
    required List<CanvasImageItem> items,
    required PdfSettings pdfSettings,
  }) async {
    if (items.isEmpty) {
      throw Exception('No canvas items provided');
    }

    if (PlatformUtils.isAndroid) {
      await PermissionService.requestStoragePermission();
    }

    final sortedItems = List<CanvasImageItem>.from(items)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    final pdf = pw.Document();
    final scaleX = pdfSettings.effectivePageFormat.width / canvasWidth;
    final scaleY = pdfSettings.effectivePageFormat.height / canvasHeight;

    final List<pw.MemoryImage> images = [];
    for (final item in sortedItems) {
      var bytes = await item.file.readAsBytes();
      if (pdfSettings.imageQuality != ImageQuality.high) {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          bytes = Uint8List.fromList(
            img.encodeJpg(
              decoded,
              quality: pdfSettings.imageQuality.compressionQuality,
            ),
          );
        }
      }
      images.add(pw.MemoryImage(bytes));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pdfSettings.effectivePageFormat,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              for (int index = 0; index < sortedItems.length; index++)
                _buildCanvasPositionedImage(
                  item: sortedItems[index],
                  image: images[index],
                  scaleX: scaleX,
                  scaleY: scaleY,
                ),
            ],
          );
        },
      ),
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        '${AppConstants.pdfFileNamePrefix}$timestamp${AppConstants.pdfFileExtension}';
    final pdfBytes = await pdf.save();

    final savedPath =
        await StorageService.savePdfToDownloads(pdfBytes, fileName);

    final tempPath = await StorageService.getTempFilePath(fileName);
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(pdfBytes);

    return PdfResult(
      fileName: fileName,
      savedPath: savedPath ?? tempPath,
      previewPath: tempPath,
      pageCount: 1,
    );
  }

  static pw.Widget _buildCanvasPositionedImage({
    required CanvasImageItem item,
    required pw.MemoryImage image,
    required double scaleX,
    required double scaleY,
  }) {
    final double left = item.position.dx * scaleX;
    final double top = item.position.dy * scaleY;
    final double width = item.size.width * scaleX;
    final double height = item.size.height * scaleY;
    final double rotationRadians = item.rotation * math.pi / 180;

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Transform.rotate(
        angle: rotationRadians,
        child: pw.Container(
          width: width,
          height: height,
          child: pw.Image(image, fit: pw.BoxFit.fill),
        ),
      ),
    );
  }

  /// Generate PDF from staggered grid layout.
  /// Items are arranged in a 3-column staggered grid across multiple pages.
  static Future<PdfResult> generatePdfFromStaggeredGrid({
    required double pageWidth,
    required double pageHeight,
    required List<CanvasImageItem> items,
    required int numColumns,
    required double columnSpacing,
    required double itemSpacing,
    required double pageMargin,
    required PdfSettings pdfSettings,
  }) async {
    if (items.isEmpty) {
      throw Exception('No canvas items provided');
    }

    if (PlatformUtils.isAndroid) {
      await PermissionService.requestStoragePermission();
    }

    final pdf = pw.Document();
    final scaleX = pdfSettings.effectivePageFormat.width / pageWidth;
    final scaleY = pdfSettings.effectivePageFormat.height / pageHeight;

    // Group items by page based on their Y position
    // The layout algorithm positions items with absolute Y coordinates
    // We need to determine which page each item belongs to
    final Map<int, List<CanvasImageItem>> itemsByPage = {};
    final double pageContentHeight = pageHeight - (pageMargin * 2);
    
    for (final item in items) {
      // Calculate which page this item belongs to
      // Items are positioned with absolute Y coordinates
      // Each page starts at: pageIndex * (pageContentHeight + pageMargin * 2)
      int pageIndex = 0;
      double itemY = item.position.dy;
      
      // Find the page index by checking how many page heights we've passed
      if (itemY > pageMargin) {
        final double relativeY = itemY - pageMargin;
        pageIndex = (relativeY / (pageContentHeight + pageMargin * 2)).floor();
      }
      
      if (!itemsByPage.containsKey(pageIndex)) {
        itemsByPage[pageIndex] = [];
      }
      itemsByPage[pageIndex]!.add(item);
    }

    // If no items found, use first page
    if (itemsByPage.isEmpty) {
      itemsByPage[0] = items;
    }

    // Load all images
    final List<pw.MemoryImage> images = [];
    for (final item in items) {
      var bytes = await item.file.readAsBytes();
      if (pdfSettings.imageQuality != ImageQuality.high) {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          bytes = Uint8List.fromList(
            img.encodeJpg(
              decoded,
              quality: pdfSettings.imageQuality.compressionQuality,
            ),
          );
        }
      }
      images.add(pw.MemoryImage(bytes));
    }

    // Create a map from item to image index
    final Map<String, int> itemImageIndex = {};
    for (int i = 0; i < items.length; i++) {
      itemImageIndex[items[i].id] = i;
    }

    // Generate pages
    final sortedPages = itemsByPage.keys.toList()..sort();
    for (final pageIndex in sortedPages) {
      final pageItems = itemsByPage[pageIndex]!;
      
      pdf.addPage(
        pw.Page(
          pageFormat: pdfSettings.effectivePageFormat,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                for (final item in pageItems)
                  _buildStaggeredGridImage(
                    item: item,
                    image: images[itemImageIndex[item.id]!],
                    scaleX: scaleX,
                    scaleY: scaleY,
                    pageIndex: pageIndex,
                    pageHeight: pageHeight,
                    pageMargin: pageMargin,
                  ),
              ],
            );
          },
        ),
      );
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        '${AppConstants.pdfFileNamePrefix}$timestamp${AppConstants.pdfFileExtension}';
    final pdfBytes = await pdf.save();

    final savedPath =
        await StorageService.savePdfToDownloads(pdfBytes, fileName);

    final tempPath = await StorageService.getTempFilePath(fileName);
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(pdfBytes);

    return PdfResult(
      fileName: fileName,
      savedPath: savedPath ?? tempPath,
      previewPath: tempPath,
      pageCount: sortedPages.length,
    );
  }

  static pw.Widget _buildStaggeredGridImage({
    required CanvasImageItem item,
    required pw.MemoryImage image,
    required double scaleX,
    required double scaleY,
    required int pageIndex,
    required double pageHeight,
    required double pageMargin,
  }) {
    // Adjust Y position for multi-page layouts
    // Items are positioned with absolute Y coordinates
    // We need to convert to relative Y for the current page
    final double pageContentHeight = pageHeight - (pageMargin * 2);
    final double pageStartY = pageIndex * (pageContentHeight + pageMargin * 2);
    final double adjustedY = item.position.dy - pageStartY;

    final double left = item.position.dx * scaleX;
    final double top = adjustedY * scaleY;
    final double width = item.size.width * scaleX;
    final double height = item.size.height * scaleY;

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: width,
        height: height,
        child: pw.Image(image, fit: pw.BoxFit.cover),
      ),
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

