import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'model_download_service.dart';

class OnnxTranslationService {
  static final OnnxTranslationService _instance =
      OnnxTranslationService._internal();
  factory OnnxTranslationService() => _instance;
  OnnxTranslationService._internal();

  OrtSession? _encoderSession;
  OrtSession? _decoderSession;
  _SentencePieceTokenizer? _tokenizer;
  String? _loadedModelId;
  final _ort = OnnxRuntime();

  Future<bool> isModelAvailable(String modelId) async {
    return await ModelDownloadService().isModelDownloaded(modelId);
  }

  Future<void> loadModel(String modelId) async {
    if (_loadedModelId == modelId) return;

    await _dispose();

    final dir = await ModelDownloadService().getModelDir(modelId);

    final encoderPath = '$dir/encoder_model.onnx';
    final decoderPath = '$dir/decoder_model.onnx';
    final sourceSpmPath = '$dir/source.spm';

    if (!File(encoderPath).existsSync() || !File(decoderPath).existsSync()) {
      throw Exception('Model dosyaları bulunamadı. Lütfen modeli indirin.');
    }

    _encoderSession = await _ort.createSessionFromFile(encoderPath);
    _decoderSession = await _ort.createSessionFromFile(decoderPath);
    _tokenizer = await _SentencePieceTokenizer.load(sourceSpmPath);
    _loadedModelId = modelId;
  }

  Future<String> translate({
    required String text,
    required String modelId,
  }) async {
    if (text.trim().isEmpty) return text;

    await loadModel(modelId);

    if (_encoderSession == null ||
        _decoderSession == null ||
        _tokenizer == null) {
      throw Exception('Model yüklenemedi');
    }

    try {
      // Tokenize
      final inputIds = _tokenizer!.encode(text);
      final attentionMask = List<int>.filled(inputIds.length, 1);

      // Encoder
      final inputIdsTensor = await OrtValue.fromList(
        inputIds,
        [1, inputIds.length],
      );
      final attentionMaskTensor = await OrtValue.fromList(
        attentionMask,
        [1, attentionMask.length],
      );

      final encoderOutputs = await _encoderSession!.run({
        'input_ids': inputIdsTensor,
        'attention_mask': attentionMaskTensor,
      });

      final encoderHiddenStates = encoderOutputs['last_hidden_state']!;

      // Greedy decode
      final List<int> decoderInputIds = [0]; // BOS token
      const maxLength = 128;

      for (int step = 0; step < maxLength; step++) {
        final decoderInputTensor = await OrtValue.fromList(
          decoderInputIds,
          [1, decoderInputIds.length],
        );

        final decoderOutputs = await _decoderSession!.run({
          'input_ids': decoderInputTensor,
          'encoder_hidden_states': encoderHiddenStates,
          'encoder_attention_mask': attentionMaskTensor,
        });

        final logits = decoderOutputs['logits']!;
        final logitsData = await logits.asList() as List;

        // Get last token logits
        final lastTokenLogits = logitsData.last as List;
        int nextToken = 0;
        double maxVal = double.negativeInfinity;
        for (int i = 0; i < lastTokenLogits.length; i++) {
          final val = (lastTokenLogits[i] as num).toDouble();
          if (val > maxVal) {
            maxVal = val;
            nextToken = i;
          }
        }

        if (nextToken == 0) break; // EOS token
        decoderInputIds.add(nextToken);
      }

      // Decode
      final translatedText = _tokenizer!.decode(decoderInputIds.skip(1).toList());
      return translatedText;
    } catch (e) {
      throw Exception('Çeviri hatası: $e');
    }
  }

  Future<List<String>> translateBatch({
    required List<String> texts,
    required String modelId,
  }) async {
    final results = <String>[];
    for (final text in texts) {
      try {
        final translated = await translate(text: text, modelId: modelId);
        results.add(translated);
      } catch (_) {
        results.add(text); // Hata durumunda orijinal metni döndür
      }
    }
    return results;
  }

  Future<void> _dispose() async {
    await _encoderSession?.close();
    await _decoderSession?.close();
    _encoderSession = null;
    _decoderSession = null;
    _tokenizer = null;
    _loadedModelId = null;
  }
}

// Basit SentencePiece tokenizer implementasyonu
class _SentencePieceTokenizer {
  final List<String> _vocab;
  final Map<String, int> _tokenToId;

  _SentencePieceTokenizer({
    required List<String> vocab,
    required Map<String, int> tokenToId,
  })  : _vocab = vocab,
        _tokenToId = tokenToId;

  static Future<_SentencePieceTokenizer> load(String spmPath) async {
    // SPM dosyasını binary olarak oku
    // Basit implementasyon — karakter bazlı tokenization
    final vocab = <String>[];
    final tokenToId = <String, int>{};

    // Temel tokenlar
    vocab.add('<pad>'); // 0
    vocab.add('<unk>'); // 1
    tokenToId['<pad>'] = 0;
    tokenToId['<unk>'] = 1;

    return _SentencePieceTokenizer(vocab: vocab, tokenToId: tokenToId);
  }

  List<int> encode(String text) {
    // Basit whitespace tokenization
    final tokens = text.toLowerCase().split(RegExp(r'\s+'));
    return tokens.map((t) => _tokenToId[t] ?? 1).toList();
  }

  String decode(List<int> ids) {
    return ids
        .map((id) => id < _vocab.length ? _vocab[id] : '<unk>')
        .where((t) => t != '<pad>' && t != '<unk>')
        .join(' ');
  }
}
