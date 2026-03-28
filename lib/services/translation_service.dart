import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model_download_service.dart';
import 'onnx_translation_service.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final _onnxService = OnnxTranslationService();
  final _downloadService = ModelDownloadService();

  String _getModelId(String from, String to) {
    return 'opus-mt-${from.toLowerCase()}-${to.toLowerCase()}';
  }

  Future<bool> isOfflineAvailable(String from, String to) async {
    final modelId = _getModelId(from, to);
    return await _downloadService.isModelDownloaded(modelId);
  }

  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    if (text.trim().isEmpty) return text;

    final modelId = _getModelId(from, to);
    final isOffline = await isOfflineAvailable(from, to);

    if (isOffline) {
      try {
        return await _onnxService.translate(text: text, modelId: modelId);
      } catch (_) {
        // ONNX başarısız olursa API'ye düş
      }
    }

    // Fallback: MyMemory API
    return await _translateOnline(text: text, from: from, to: to);
  }

  Future<String> _translateOnline({
    required String text,
    required String from,
    required String to,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}'
        '&langpair=${from.toLowerCase()}|${to.toLowerCase()}',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['responseData']['translatedText'] as String?;
        if (translated != null && translated.isNotEmpty) {
          return translated;
        }
      }
    } catch (_) {}
    return text;
  }

  Future<List<String>> translateBatch({
    required List<String> texts,
    required String from,
    required String to,
  }) async {
    final results = <String>[];
    for (final text in texts) {
      final translated = await translate(text: text, from: from, to: to);
      results.add(translated);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return results;
  }
}
