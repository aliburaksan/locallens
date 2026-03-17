import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // Public LibreTranslate instances - fallback sırasıyla dener
  static const _endpoints = [
    'https://libretranslate.com',
    'https://translate.argosopentech.com',
    'https://libretranslate.de',
  ];

  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    if (text.trim().isEmpty) return text;

    for (final endpoint in _endpoints) {
      try {
        final result = await _tryTranslate(
          endpoint: endpoint,
          text: text,
          from: from.toLowerCase(),
          to: to.toLowerCase(),
        );
        if (result != null) return result;
      } catch (_) {
        continue;
      }
    }

    // Fallback: orijinal metni döndür
    return text;
  }

  Future<String?> _tryTranslate({
    required String endpoint,
    required String text,
    required String from,
    required String to,
  }) async {
    final response = await http
        .post(
          Uri.parse('$endpoint/translate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'q': text,
            'source': from,
            'target': to,
            'format': 'text',
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translated = data['translatedText'] as String?;
      if (translated != null && translated.isNotEmpty) {
        return translated;
      }
    }
    return null;
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
    }
    return results;
  }
}
