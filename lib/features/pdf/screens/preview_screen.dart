import 'package:flutter/material.dart';

/// PDF preview screen showing success message and PDF info
class PreviewScreen extends StatelessWidget {
  final String pdfPath;
  final int imageCount;

  const PreviewScreen({
    super.key,
    required this.pdfPath,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Generated'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'PDF Generated Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pages: $imageCount',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Saved to:\n$pdfPath',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.camera),
                label: const Text('Capture More'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

