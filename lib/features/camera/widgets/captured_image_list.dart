import 'dart:io';
import 'package:flutter/material.dart';

/// Widget to display a horizontal list of captured images with delete and reorder functionality
class CapturedImageList extends StatelessWidget {
  final List<File> images;
  final Function(int)? onDelete;
  final Function(int, int)? onReorder;
  final Function(int)? onTap;

  const CapturedImageList({
    super.key,
    required this.images,
    this.onDelete,
    this.onReorder,
    this.onTap,
  });

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) {
      onDelete!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      color: Colors.grey[200],
      child: onReorder != null
          ? ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                onReorder!(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                return _ImageThumbnail(
                  key: Key(images[index].path),
                  image: images[index],
                  index: index,
                  onDelete: onDelete != null
                      ? () => _showDeleteConfirmation(context, index)
                      : null,
                  onTap: onTap != null ? () => onTap!(index) : null,
                );
              },
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return _ImageThumbnail(
                  image: images[index],
                  index: index,
                  onDelete: onDelete != null
                      ? () => _showDeleteConfirmation(context, index)
                      : null,
                  onTap: onTap != null ? () => onTap!(index) : null,
                );
              },
            ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final File image;
  final int index;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _ImageThumbnail({
    super.key,
    required this.image,
    required this.index,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                image,
                fit: BoxFit.cover,
                width: 80,
                height: 100,
              ),
            ),
            if (onDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
