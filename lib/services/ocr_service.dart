import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextBlock {
  final String text;
  final double left;
  final double top;
  final double width;
  final double height;
  final double fontSize;

  TextBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  @override
  String toString() =>
      'TextBlock(text: $text, left: $left, top: $top, w: $width, h: $height)';
}

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<TextBlock>> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final blocks = <TextBlock>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final boundingBox = line.boundingBox;
        if (line.text.trim().isEmpty) continue;

        // Estimate font size from bounding box height
        final estimatedFontSize = boundingBox.height * 0.75;

        blocks.add(TextBlock(
          text: line.text.trim(),
          left: boundingBox.left,
          top: boundingBox.top,
          width: boundingBox.width,
          height: boundingBox.height,
          fontSize: estimatedFontSize.clamp(10.0, 72.0),
        ));
      }
    }

    return blocks;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
