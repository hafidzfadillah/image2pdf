import 'package:pdf/pdf.dart';

/// PDF generation settings
class PdfSettings {
  final PdfPageFormat pageFormat;
  final bool isPortrait;
  final ImageQuality imageQuality;

  const PdfSettings({
    this.pageFormat = PdfPageFormat.a4,
    this.isPortrait = true,
    this.imageQuality = ImageQuality.high,
  });

  PdfSettings copyWith({
    PdfPageFormat? pageFormat,
    bool? isPortrait,
    ImageQuality? imageQuality,
  }) {
    return PdfSettings(
      pageFormat: pageFormat ?? this.pageFormat,
      isPortrait: isPortrait ?? this.isPortrait,
      imageQuality: imageQuality ?? this.imageQuality,
    );
  }

  PdfPageFormat get effectivePageFormat {
    if (isPortrait) {
      return pageFormat;
    } else {
      return PdfPageFormat(
        pageFormat.width,
        pageFormat.height,
        marginAll: pageFormat.marginTop,
      ).landscape;
    }
  }
}

/// Image quality levels
enum ImageQuality {
  low,
  medium,
  high,
}

extension ImageQualityExtension on ImageQuality {
  String get label {
    switch (this) {
      case ImageQuality.low:
        return 'Low';
      case ImageQuality.medium:
        return 'Medium';
      case ImageQuality.high:
        return 'High';
    }
  }

  int get compressionQuality {
    switch (this) {
      case ImageQuality.low:
        return 60;
      case ImageQuality.medium:
        return 80;
      case ImageQuality.high:
        return 100;
    }
  }
}

