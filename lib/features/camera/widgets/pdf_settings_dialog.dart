// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:image_to_pdf/core/models/pdf_settings.dart';

/// Dialog for configuring PDF settings
class PdfSettingsDialog extends StatefulWidget {
  final PdfSettings initialSettings;

  const PdfSettingsDialog({
    super.key,
    required this.initialSettings,
  });

  @override
  State<PdfSettingsDialog> createState() => _PdfSettingsDialogState();
}

class _PdfSettingsDialogState extends State<PdfSettingsDialog> {
  late PdfSettings _settings;
  late PdfPageFormat _selectedFormat;
  late bool _isPortrait;
  late ImageQuality _imageQuality;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _selectedFormat = _settings.pageFormat;
    _isPortrait = _settings.isPortrait;
    _imageQuality = _settings.imageQuality;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PDF Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Size
            const Text(
              'Page Size',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<PdfPageFormat>(
              value: _selectedFormat,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: PdfPageFormat.a4,
                  child: Text('A4'),
                ),
                DropdownMenuItem(
                  value: PdfPageFormat.letter,
                  child: Text('Letter'),
                ),
                DropdownMenuItem(
                  value: PdfPageFormat.legal,
                  child: Text('Legal'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFormat = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Orientation
            const Text(
              'Orientation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Portrait'),
                    value: true,
                    groupValue: _isPortrait,
                    onChanged: (value) {
                      setState(() {
                        _isPortrait = value ?? true;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Landscape'),
                    value: false,
                    groupValue: _isPortrait,
                    onChanged: (value) {
                      setState(() {
                        _isPortrait = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Image Quality
            const Text(
              'Image Quality',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<ImageQuality>(
              value: _imageQuality,
              isExpanded: true,
              items: ImageQuality.values.map((quality) {
                return DropdownMenuItem(
                  value: quality,
                  child: Text(quality.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _imageQuality = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newSettings = PdfSettings(
              pageFormat: _selectedFormat,
              isPortrait: _isPortrait,
              imageQuality: _imageQuality,
            );
            Navigator.pop(context, newSettings);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
