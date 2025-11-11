import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/features/camera/widgets/captured_image_list.dart';
import 'package:image_to_pdf/features/pdf/screens/preview_screen.dart';
import 'package:image_to_pdf/services/permission_service.dart';
import 'package:image_to_pdf/services/pdf_service.dart';

/// Main camera screen for capturing images and generating PDFs
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  List<File> _capturedImages = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
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
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
      );

      await _controller!.initialize();
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

  Future<void> _generatePdf() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images captured yet')),
      );
      return;
    }

    try {
      final result = await PdfService.generatePdfFromImages(_capturedImages);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to Downloads: ${result.fileName}'),
            duration: const Duration(seconds: AppConstants.snackBarDurationSeconds),
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
          if (_capturedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearImages,
              tooltip: 'Clear all images',
            ),
        ],
      ),
      body: _isInitialized
          ? Column(
              children: [
                Expanded(
                  flex: 3,
                  child: CameraPreview(_controller!),
                ),
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
                            onPressed:
                                _capturedImages.isEmpty ? null : _generatePdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Generate PDF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CapturedImageList(images: _capturedImages),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

