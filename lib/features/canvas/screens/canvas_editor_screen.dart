import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/core/models/pdf_settings.dart';
import 'package:image_to_pdf/features/canvas/models/canvas_image_item.dart';
import 'package:image_to_pdf/features/pdf/screens/preview_screen.dart';
import 'package:image_to_pdf/services/pdf_service.dart';

class CanvasEditorScreen extends StatefulWidget {
  const CanvasEditorScreen({
    super.key,
    required this.images,
    required this.pdfSettings,
  });

  final List<File> images;
  final PdfSettings pdfSettings;

  @override
  State<CanvasEditorScreen> createState() => _CanvasEditorScreenState();
}

class _CanvasEditorScreenState extends State<CanvasEditorScreen> {
  static const int _numColumns = 3;
  static const double _columnSpacing = 12.0;
  static const double _itemSpacing = 12.0;
  static const double _pageMargin = 16.0;

  final List<CanvasImageItem> _items = [];
  bool _isLoading = true;
  bool _isPreviewMode = false;

  // Page dimensions based on PDF settings
  late double _pageWidth;
  late double _pageHeight;
  late double _columnWidth;

  @override
  void initState() {
    super.initState();
    _initializePageDimensions();
    _initializeCanvasItems();
  }

  void _initializePageDimensions() {
    // Get page format from settings
    final pageFormat = widget.pdfSettings.effectivePageFormat;
    _pageWidth = pageFormat.width;
    _pageHeight = pageFormat.height;

    // Calculate column width (3 columns with spacing)
    final double availableWidth =
        _pageWidth - (_pageMargin * 2) - (_columnSpacing * (_numColumns - 1));
    _columnWidth = availableWidth / _numColumns;
  }

  Future<void> _initializeCanvasItems() async {
    final List<CanvasImageItem> items = [];

    for (final file in widget.images) {
      final size = await _getImageSize(file);
      final displaySize = _calculateImageSize(size);

      items.add(
        CanvasImageItem(
          id: _generateId(),
          file: file,
          position: Offset.zero, // Will be set by layout
          size: displaySize,
          rotation: 0,
          zIndex: 0,
          originalSize: size,
        ),
      );
    }

    _arrangeInStaggeredGrid(items);

    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(items);
      _isLoading = false;
    });
  }

  Future<Size> _getImageSize(File file) async {
    try {
      final data = await file.readAsBytes();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(data, completer.complete);
      final image = await completer.future;
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (_) {
      final fallback = img.decodeImage(await file.readAsBytes());
      if (fallback != null) {
        return Size(
          fallback.width.toDouble(),
          fallback.height.toDouble(),
        );
      }
      return const Size(800, 1000);
    }
  }

  Size _calculateImageSize(Size originalSize) {
    final double aspectRatio = originalSize.width / originalSize.height;
    final double availableHeight = _pageHeight - (_pageMargin * 2);

    // Calculate size to fit column width
    double width = _columnWidth;
    double height = width / aspectRatio;

    // If height exceeds available page height, constrain it
    if (height > availableHeight) {
      height = availableHeight;
      width = height * aspectRatio;
    }

    return Size(width, height);
  }

  void _arrangeInStaggeredGrid(List<CanvasImageItem> items) {
    if (items.isEmpty) return;

    // Track current row position
    int currentColumn = 0; // 0, 1, or 2
    double currentRowTop = 0.0; // Y position of current row
    double currentRowHeight = 0.0; // Height of tallest item in current row
    double currentPageTop = 0.0; // Absolute Y position of current page start
    final double availableHeight = _pageHeight - (_pageMargin * 2);

    for (final item in items) {
      // Calculate display size
      item.size = _calculateImageSize(item.originalSize);
      final double itemHeight = item.size.height;

      // Check if we need to start a new row (current row is full)
      if (currentColumn >= _numColumns) {
        // Move to next row
        currentRowTop += currentRowHeight + _itemSpacing;
        currentColumn = 0;
        currentRowHeight = 0.0;
      }

      // Check if current row (with this item) fits on current page
      // Use the maximum of current row height and item height
      final double maxRowHeight =
          currentRowHeight > itemHeight ? currentRowHeight : itemHeight;
      final double rowBottom = currentRowTop + maxRowHeight;

      // If row doesn't fit on current page, start new page
      if (rowBottom > availableHeight && currentRowTop > 0) {
        // Start new page
        currentPageTop += availableHeight + (_pageMargin * 2);
        currentRowTop = 0.0;
        currentColumn = 0;
        currentRowHeight = 0.0;
      }

      // Update row height to tallest item in current row
      if (itemHeight > currentRowHeight) {
        currentRowHeight = itemHeight;
      }

      // Position item in current row and column
      final double x =
          _pageMargin + currentColumn * (_columnWidth + _columnSpacing);
      final double y = currentPageTop + _pageMargin + currentRowTop;

      item.position = Offset(x, y);

      // Move to next column
      currentColumn++;
    }
  }

  String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      Random().nextInt(1 << 32).toString();

  void _togglePreviewMode() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
    });
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final XFile? result =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);

    if (result == null) return;

    final file = File(result.path);
    final size = await _getImageSize(file);
    final displaySize = _calculateImageSize(size);

    setState(() {
      final item = CanvasImageItem(
        id: _generateId(),
        file: file,
        position: Offset.zero,
        size: displaySize,
        rotation: 0,
        zIndex: 0,
        originalSize: size,
      );
      _items.add(item);
      _arrangeInStaggeredGrid(_items);
    });
  }

  Future<void> _generatePdfFromCanvas() async {
    if (_items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one image to the canvas')),
      );
      return;
    }

    try {
      final result = await PdfService.generatePdfFromStaggeredGrid(
        pageWidth: _pageWidth,
        pageHeight: _pageHeight,
        items: _items,
        numColumns: _numColumns,
        columnSpacing: _columnSpacing,
        itemSpacing: _itemSpacing,
        pageMargin: _pageMargin,
        pdfSettings: widget.pdfSettings,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to Downloads: ${result.fileName}'),
          duration:
              const Duration(seconds: AppConstants.snackBarDurationSeconds),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            pdfPath: result.previewPath,
            imageCount: result.pageCount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas Mode - Staggered Grid'),
        actions: [
          IconButton(
            tooltip: _isPreviewMode ? 'Exit preview' : 'Preview',
            icon: Icon(
              _isPreviewMode ? Icons.edit : Icons.remove_red_eye,
            ),
            onPressed: _togglePreviewMode,
          ),
          IconButton(
            tooltip: 'Add image',
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _addImage,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePdfFromCanvas,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate PDF'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth * 0.9;
                final double displayWidth = maxWidth;
                final double displayHeight =
                    (displayWidth / _pageWidth) * _pageHeight;

                // Calculate total height needed for all pages
                double maxY = 0;
                for (final item in _items) {
                  final double itemBottom = item.position.dy + item.size.height;
                  if (itemBottom > maxY) {
                    maxY = itemBottom;
                  }
                }
                final int numPages =
                    ((maxY - _pageMargin) / (_pageHeight - (_pageMargin * 2)))
                        .ceil();

                return SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        for (int pageIndex = 0;
                            pageIndex < numPages;
                            pageIndex++)
                          Container(
                            margin: EdgeInsets.only(
                              bottom: pageIndex < numPages - 1 ? 20 : 0,
                            ),
                            child: Container(
                              width: displayWidth,
                              height: displayHeight,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                border: Border.all(color: Colors.grey.shade500),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                width: _pageWidth,
                                height: _pageHeight,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: Colors.grey.shade600),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: _buildCanvasItemsForPage(pageIndex),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  List<Widget> _buildCanvasItemsForPage(int pageIndex) {
    final double pageContentHeight = _pageHeight - (_pageMargin * 2);
    final double pageStartY = pageIndex * (pageContentHeight + _pageMargin * 2);
    final double pageEndY = pageStartY + _pageHeight;

    // Filter items that belong to this page
    final pageItems = _items.where((item) {
      final double itemTop = item.position.dy;
      final double itemBottom = itemTop + item.size.height;
      return itemTop < pageEndY && itemBottom > pageStartY;
    }).toList();

    return pageItems.map((item) {
      // Adjust Y position relative to page
      final double adjustedY = item.position.dy - pageStartY;

      return Positioned(
        left: item.position.dx,
        top: adjustedY,
        child: Container(
          width: item.size.width,
          height: item.size.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              item.file,
              fit: BoxFit.cover,
              width: item.size.width,
              height: item.size.height,
            ),
          ),
        ),
      );
    }).toList();
  }
}
