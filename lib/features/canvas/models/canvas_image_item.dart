import 'dart:io';

import 'package:flutter/material.dart';

class CanvasImageItem {
  CanvasImageItem({
    required this.id,
    required this.file,
    required this.position,
    required this.size,
    required this.rotation,
    required this.zIndex,
    required this.originalSize,
  });

  final String id;
  final File file;
  Offset position;
  Size size;
  double rotation; // in degrees
  int zIndex;
  final Size originalSize;

  CanvasImageItem copyWith({
    Offset? position,
    Size? size,
    double? rotation,
    int? zIndex,
  }) {
    return CanvasImageItem(
      id: id,
      file: file,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      originalSize: originalSize,
    );
  }
}
