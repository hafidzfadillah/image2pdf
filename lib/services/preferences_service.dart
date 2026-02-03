import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_to_pdf/core/models/pdf_generation_mode.dart';

/// Service to manage app preferences.
class PreferencesService {
  PreferencesService._();

  static const String _pdfGenerationModeKey = 'pdf_generation_mode';

  /// Gets the stored PDF generation mode preference.
  static Future<PdfGenerationMode> getPdfGenerationMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_pdfGenerationModeKey);
    return PdfGenerationModeExtension.fromStorageKey(value);
  }

  /// Saves the PDF generation mode preference.
  static Future<void> setPdfGenerationMode(PdfGenerationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pdfGenerationModeKey, mode.storageKey);
  }
}

