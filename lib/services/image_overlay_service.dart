import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'ocr_service.dart';

class ImageOverlayService {
  static final ImageOverlayService _instance = ImageOverlayService._internal();
  factory ImageOverlayService() => _instance;
  ImageOverlayService._internal();

  Future<File> applyOverlay({
    required File originalImage,
    required List<TextBlock> blocks,
    required List<String> translatedTexts,
  }) async {
    // Load original image
    final imageBytes = await originalImage.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) throw Exception('Görüntü yüklenemedi');

    final imageWidth = decodedImage.width.toDouble();
    final imageHeight = decodedImage.height.toDouble();

    // Use Flutter's canvas to draw overlay
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw original image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    canvas.drawImage(frame.image, Offset.zero, Paint());

    // Draw translated text blocks
    for (int i = 0; i < blocks.length && i < translatedTexts.length; i++) {
      final block = blocks[i];
      final translatedText = translatedTexts[i];
      if (translatedText.trim().isEmpty) continue;

      // Draw background to cover original text
      final bgPaint = Paint()
        ..color = _detectBackgroundColor(decodedImage, block);

      canvas.drawRect(
        Rect.fromLTWH(block.left, block.top, block.width, block.height),
        bgPaint,
      );

      // Draw translated text
      final textColor = _contrastColor(bgPaint.color);
      final textPainter = TextPainter(
        text: TextSpan(
          text: translatedText,
          style: TextStyle(
            color: textColor,
            fontSize: block.fontSize,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      textPainter.layout(maxWidth: block.width);

      // Vertically center text in block
      final yOffset = block.top + (block.height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(block.left + 2, yOffset.clamp(block.top, block.top + block.height)));
    }

    // Convert to image
    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(
      imageWidth.toInt(),
      imageHeight.toInt(),
    );

    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) throw Exception('Görüntü dönüştürülemedi');

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/locallens_translated_${DateTime.now().millisecondsSinceEpoch}.png';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(byteData.buffer.asUint8List());

    return outputFile;
  }

  Color _detectBackgroundColor(img.Image image, TextBlock block) {
    // Sample pixels around the text block edges to detect background
    final samples = <img.Color>[];
    final x = block.left.toInt().clamp(0, image.width - 1);
    final y = block.top.toInt().clamp(0, image.height - 1);
    final w = block.width.toInt().clamp(1, image.width - x);
    final h = block.height.toInt().clamp(1, image.height - y);

    // Sample corners and edges
    for (int dx = 0; dx < w; dx += (w / 5).ceil()) {
      samples.add(image.getPixel(x + dx, y));
      samples.add(image.getPixel(x + dx, (y + h - 1).clamp(0, image.height - 1)));
    }
    for (int dy = 0; dy < h; dy += (h / 5).ceil()) {
      samples.add(image.getPixel(x, y + dy));
      samples.add(image.getPixel((x + w - 1).clamp(0, image.width - 1), y + dy));
    }

    if (samples.isEmpty) return Colors.white;

    // Average color
    int r = 0, g = 0, b = 0;
    for (final c in samples) {
      r += c.r.toInt();
      g += c.g.toInt();
      b += c.b.toInt();
    }
    r = (r / samples.length).round();
    g = (g / samples.length).round();
    b = (b / samples.length).round();

    return Color.fromARGB(255, r, g, b);
  }

  Color _contrastColor(Color background) {
    // Calculate luminance to decide black or white text
    final luminance = (0.299 * background.red +
            0.587 * background.green +
            0.114 * background.blue) /
        255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
