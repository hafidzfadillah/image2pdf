enum PdfGenerationMode {
  standard,
  canvas,
}

extension PdfGenerationModeExtension on PdfGenerationMode {
  String get label {
    switch (this) {
      case PdfGenerationMode.standard:
        return 'One image per page';
      case PdfGenerationMode.canvas:
        return 'Canvas mode';
    }
  }

  String get storageKey {
    switch (this) {
      case PdfGenerationMode.standard:
        return 'standard';
      case PdfGenerationMode.canvas:
        return 'canvas';
    }
  }

  static PdfGenerationMode fromStorageKey(String? key) {
    switch (key) {
      case 'canvas':
        return PdfGenerationMode.canvas;
      case 'standard':
      default:
        return PdfGenerationMode.standard;
    }
  }
}

