import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/product_analyzer_service.dart';
import '../../../services/nutrition_rules_engine.dart';
import '../../../theme/app_theme.dart';

class ScanTabOcrWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onNutritionExtracted;

  const ScanTabOcrWidget({super.key, required this.onNutritionExtracted});

  @override
  State<ScanTabOcrWidget> createState() => _ScanTabOcrWidgetState();
}

class _ScanTabOcrWidgetState extends State<ScanTabOcrWidget> {
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ProductAnalyzerService _productAnalyzer = ProductAnalyzerService();
  final NutritionRulesEngine _rulesEngine = NutritionRulesEngine();
  String? _previewPath;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _simulateOcrScan() async {
    await _scanFromSource(ImageSource.camera);
  }

  Future<void> _scanFromGallery() async {
    await _scanFromSource(ImageSource.gallery);
  }

  // helper removed - nutrient extraction handled by ProductAnalyzerService

  Future<void> _scanFromSource(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (file == null || !mounted) return;

      setState(() {
        _isScanning = true;
        _previewPath = file.path;
      });

      final inputImage = InputImage.fromFilePath(file.path);
      // Use ProductAnalyzerService to extract nutrients and advice
      await _rulesEngine.initialize();
      await _productAnalyzer.initialize(_rulesEngine);

      final result = await _productAnalyzer.analyzeProductImage(inputImage, _rulesEngine.getAvailableDiseases().isNotEmpty ? _rulesEngine.getAvailableDiseases().first : null);

      setState(() => _isScanning = false);

      if (result['success'] == true) {
        widget.onNutritionExtracted({
          'name': result['product_name'] ?? result['extracted_text'] ?? 'Produit',
          'calories': result['nutrients']?['calories'] ?? 0,
          'proteins': result['nutrients']?['protein'] ?? 0,
          'carbs': result['nutrients']?['carbs'] ?? 0,
          'fats': result['nutrients']?['fat'] ?? 0,
          'sugar': result['nutrients']?['sugar'] ?? 0,
          'sodium': result['nutrients']?['sodium'] ?? 0,
          'scanType': 'ocr',
          'rawText': result['extracted_text'],
          'verdict': result['verdict'],
          'warnings': result['warnings'],
          'advice': result['advice'],
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Erreur OCR')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur OCR: caméra/scan indisponible.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF111827),
          child: Center(
            child: _previewPath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner_outlined,
                        size: 48,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Capturez une étiquette nutritionnelle',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  )
                : Image.file(
                    File(_previewPath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white30,
                      size: 40,
                    ),
                  ),
          ),
        ),
        Center(
          child: Container(
            width: 280,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isScanning ? AppTheme.statusGreen : Colors.white60,
                width: 1.5,
              ),
            ),
            child: _isScanning
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.statusGreen,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Reading label...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Point at nutrition label',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withAlpha(217)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Text(
                  'Align nutrition facts label inside the frame',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isScanning ? null : _simulateOcrScan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withAlpha(102),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isScanning)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          const Icon(
                            Icons.document_scanner_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        const SizedBox(width: 10),
                        Text(
                          _isScanning ? 'Scanning...' : 'Scan Label',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _isScanning ? null : _scanFromGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Importer depuis la galerie',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
