import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Camera control buttons (flash, switch, zoom)
class CameraControls extends StatelessWidget {
  final CameraController? controller;
  final List<CameraDescription>? cameras;
  final Function(CameraDescription)? onCameraSwitch;
  final double? currentZoom;
  final Function(double)? onZoomChanged;

  const CameraControls({
    super.key,
    this.controller,
    this.cameras,
    this.onCameraSwitch,
    this.currentZoom,
    this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      top: 16,
      child: Column(
        children: [
          // Flash control
          _FlashControl(controller: controller),
          const SizedBox(height: 16),
          // Camera switch
          if (cameras != null && cameras!.length > 1)
            _CameraSwitchButton(
              controller: controller,
              cameras: cameras!,
              onSwitch: onCameraSwitch,
            ),
          if (cameras != null && cameras!.length > 1)
            const SizedBox(height: 16),
          // Zoom control
          _ZoomControl(
            controller: controller,
            currentZoom: currentZoom ?? 1.0,
            onZoomChanged: onZoomChanged,
          ),
        ],
      ),
    );
  }
}

class _FlashControl extends StatefulWidget {
  final CameraController? controller;

  const _FlashControl({this.controller});

  @override
  State<_FlashControl> createState() => _FlashControlState();
}

class _FlashControlState extends State<_FlashControl> {
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _flashMode = widget.controller!.value.flashMode;
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }

  Color _getFlashColor() {
    switch (_flashMode) {
      case FlashMode.off:
        return Colors.grey;
      case FlashMode.auto:
        return Colors.blue;
      case FlashMode.always:
        return Colors.amber;
      case FlashMode.torch:
        return Colors.orange;
    }
  }

  Future<void> _toggleFlash() async {
    if (widget.controller == null) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.off;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }

    try {
      await widget.controller!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(_getFlashIcon(), color: _getFlashColor()),
        onPressed: _toggleFlash,
        tooltip: 'Flash: ${_flashMode.name}',
      ),
    );
  }
}

class _CameraSwitchButton extends StatelessWidget {
  final CameraController? controller;
  final List<CameraDescription> cameras;
  final Function(CameraDescription)? onSwitch;

  const _CameraSwitchButton({
    required this.controller,
    required this.cameras,
    this.onSwitch,
  });

  CameraDescription _getOtherCamera() {
    if (controller == null) return cameras[0];
    final currentLens = controller!.description.lensDirection;
    return cameras.firstWhere(
      (camera) => camera.lensDirection != currentLens,
      orElse: () => cameras[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.length < 2) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.cameraswitch, color: Colors.white),
        onPressed: () {
          final otherCamera = _getOtherCamera();
          onSwitch?.call(otherCamera);
        },
        tooltip: 'Switch camera',
      ),
    );
  }
}

class _ZoomControl extends StatefulWidget {
  final CameraController? controller;
  final double currentZoom;
  final Function(double)? onZoomChanged;

  const _ZoomControl({
    required this.controller,
    required this.currentZoom,
    this.onZoomChanged,
  });

  @override
  State<_ZoomControl> createState() => _ZoomControlState();
}

class _ZoomControlState extends State<_ZoomControl> {
  double _maxZoom = 1.0;
  double _minZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _loadZoomLevels();
  }

  Future<void> _loadZoomLevels() async {
    if (widget.controller == null) return;
    try {
      _maxZoom = await widget.controller!.getMaxZoomLevel();
      _minZoom = await widget.controller!.getMinZoomLevel();
      if (mounted) setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) return const SizedBox.shrink();

    if (_maxZoom <= _minZoom) return const SizedBox.shrink();

    return Container(
      width: 60,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
      ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Slider(
            value: widget.currentZoom.clamp(_minZoom, _maxZoom),
            min: _minZoom,
            max: _maxZoom,
            onChanged: (value) {
              widget.controller?.setZoomLevel(value);
              widget.onZoomChanged?.call(value);
            },
          ),
        ),
    );
  }
}

