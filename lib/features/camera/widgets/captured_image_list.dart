import 'dart:io';
import 'package:flutter/material.dart';

/// Widget to display a horizontal list of captured images
class CapturedImageList extends StatelessWidget {
  final List<File> images;

  const CapturedImageList({
    super.key,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      color: Colors.grey[200],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(8),
            width: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                images[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}

