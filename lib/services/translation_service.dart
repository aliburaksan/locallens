import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    if (text.trim().isEmpty) return text;
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}'
        '&langpair=${from.toLowerCase()}|${to.toLowerCase()}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
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
      // Rate limit için kısa bekleme
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return results;
  }
}
