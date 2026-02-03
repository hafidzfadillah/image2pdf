// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/core/models/pdf_generation_mode.dart';
import 'package:image_to_pdf/core/models/pdf_settings.dart';
import 'package:image_to_pdf/features/canvas/screens/canvas_editor_screen.dart';
import 'package:image_to_pdf/features/camera/widgets/captured_image_list.dart';
import 'package:image_to_pdf/features/camera/widgets/camera_controls.dart';
import 'package:image_to_pdf/features/camera/widgets/pdf_settings_dialog.dart';
import 'package:image_to_pdf/features/camera/screens/image_preview_screen.dart';
import 'package:image_to_pdf/features/pdf/screens/preview_screen.dart';
import 'package:image_to_pdf/services/permission_service.dart';
import 'package:image_to_pdf/services/pdf_service.dart';
import 'package:image_to_pdf/services/preferences_service.dart';

/// Main camera screen for capturing images and generating PDFs
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _GenerationModeSelection {
  final PdfGenerationMode mode;
  final bool rememberChoice;

  const _GenerationModeSelection({
    required this.mode,
    required this.rememberChoice,
  });
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final List<File> _capturedImages = [];
  bool _isInitialized = false;
  double _currentZoom = 1.0;
  PdfSettings _pdfSettings = const PdfSettings();
  PdfGenerationMode _preferredGenerationMode = PdfGenerationMode.standard;
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final mode = await PreferencesService.getPdfGenerationMode();
    if (!mounted) return;
    setState(() {
      _preferredGenerationMode = mode;
      _isLoadingPreferences = false;
    });
  }

  Future<void> _initializeCamera([CameraDescription? camera]) async {
    // Request camera permission
    final hasPermission = await PermissionService.requestCameraPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
      return;
    }

    try {
      _cameras ??= await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      final cameraToUse = camera ?? _cameras![0];

      // Dispose previous controller
      await _controller?.dispose();

      _controller = CameraController(
        cameraToUse,
        ResolutionPreset.high,
      );

      await _controller!.initialize();

      // Set initial zoom
      _currentZoom = await _controller!.getMinZoomLevel();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  Future<void> _switchCamera(CameraDescription newCamera) async {
    setState(() {
      _isInitialized = false;
    });
    await _initializeCamera(newCamera);
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(File(image.path));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image captured! Total: ${_capturedImages.length}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image deleted')),
    );
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _capturedImages.removeAt(oldIndex);
      _capturedImages.insert(newIndex, item);
    });
  }

  void _openImagePreview(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          images: _capturedImages,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _openPdfSettings() async {
    final settings = await showDialog<PdfSettings>(
      context: context,
      builder: (context) => PdfSettingsDialog(
        initialSettings: _pdfSettings,
      ),
    );

    if (settings != null) {
      setState(() {
        _pdfSettings = settings;
      });
    }
  }

  Future<void> _handleGeneratePdf() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images captured yet')),
      );
      return;
    }

    if (_isLoadingPreferences) {
      await _loadPreferences();
    }

    final selection = await _showGenerationModeDialog();
    if (selection == null) {
      return;
    }

    if (selection.rememberChoice) {
      await PreferencesService.setPdfGenerationMode(selection.mode);
      if (mounted) {
        setState(() {
          _preferredGenerationMode = selection.mode;
        });
      }
    }

    if (selection.mode == PdfGenerationMode.canvas) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CanvasEditorScreen(
            images: List<File>.from(_capturedImages),
            pdfSettings: _pdfSettings,
          ),
        ),
      );
    } else {
      await _generateStandardPdf();
    }
  }

  Future<_GenerationModeSelection?> _showGenerationModeDialog() async {
    PdfGenerationMode selectedMode = _preferredGenerationMode;
    bool rememberChoice = false;

    return showDialog<_GenerationModeSelection>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select PDF generation mode'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<PdfGenerationMode>(
                    title: Text(PdfGenerationMode.standard.label),
                    value: PdfGenerationMode.standard,
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedMode = value;
                      });
                    },
                  ),
                  RadioListTile<PdfGenerationMode>(
                    title: Text(PdfGenerationMode.canvas.label),
                    value: PdfGenerationMode.canvas,
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: rememberChoice,
                    onChanged: (value) {
                      setState(() {
                        rememberChoice = value ?? false;
                      });
                    },
                    title: const Text('Remember my choice'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _GenerationModeSelection(
                        mode: selectedMode,
                        rememberChoice: rememberChoice,
                      ),
                    );
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateStandardPdf() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images captured yet')),
      );
      return;
    }

    try {
      final result = await PdfService.generatePdfFromImages(
        _capturedImages,
        settings: _pdfSettings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to Downloads: ${result.fileName}'),
            duration:
                const Duration(seconds: AppConstants.snackBarDurationSeconds),
          ),
        );

        // Navigate to preview screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(
              pdfPath: result.previewPath,
              imageCount: result.pageCount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  void _clearImages() {
    setState(() {
      _capturedImages.clear();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openPdfSettings,
            tooltip: 'PDF Settings',
          ),
          if (_capturedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearImages,
              tooltip: 'Clear all images',
            ),
        ],
      ),
      body: _isInitialized
          ? Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: CameraPreview(_controller!),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      color: Colors.black87,
                      child: Column(
                        children: [
                          Text(
                            'Images captured: ${_capturedImages.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _captureImage,
                                icon: const Icon(Icons.camera),
                                label: const Text('Capture'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _capturedImages.isEmpty
                                    ? null
                                    : _handleGeneratePdf,
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Generate PDF'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CapturedImageList(
                      images: _capturedImages,
                      onDelete:
                          _capturedImages.isNotEmpty ? _deleteImage : null,
                      onReorder:
                          _capturedImages.length > 1 ? _reorderImages : null,
                      onTap:
                          _capturedImages.isNotEmpty ? _openImagePreview : null,
                    ),
                  ],
                ),
                CameraControls(
                  controller: _controller,
                  cameras: _cameras,
                  onCameraSwitch: _switchCamera,
                  currentZoom: _currentZoom,
                  onZoomChanged: (zoom) {
                    setState(() {
                      _currentZoom = zoom;
                    });
                  },
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
