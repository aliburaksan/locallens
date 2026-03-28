import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelInfo {
  final String id;
  final String name;
  final String sourceLang;
  final String targetLang;
  final String size;
  final List<ModelFile> files;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.sourceLang,
    required this.targetLang,
    required this.size,
    required this.files,
  });
}

class ModelFile {
  final String name;
  final String url;

  const ModelFile({required this.name, required this.url});
}

class ModelDownloadService {
  static final ModelDownloadService _instance =
      ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._internal();

  static const _baseUrl =
      'https://github.com/aliburaksan/locallens/releases/download/v1.0-models';

  static const availableModels = [
    ModelInfo(
      id: 'opus-mt-tr-en',
      name: 'TR → EN',
      sourceLang: 'tr',
      targetLang: 'en',
      size: '~520 MB',
      files: [
        ModelFile(name: 'decoder_model.onnx', url: '$_baseUrl/decoder_model.onnx'),
        ModelFile(name: 'encoder_model.onnx', url: '$_baseUrl/encoder_model.onnx'),
        ModelFile(name: 'source.spm', url: '$_baseUrl/source.spm'),
        ModelFile(name: 'target.spm', url: '$_baseUrl/target.spm'),
      ],
    ),
  ];

  Future<String> getModelDir(String modelId) async {
  final appDir = await getExternalStorageDirectory() ?? 
                 await getApplicationDocumentsDirectory();
  final dir = '${appDir.path}/LocalLens/models/$modelId';
  await Directory(dir).create(recursive: true);
  return dir;
}

  Future<bool> isModelDownloaded(String modelId) async {
    final dir = await getModelDir(modelId);
    final configFile = File('$dir/config.json');
    return configFile.existsSync();
  }

  Future<void> downloadModel({
    required ModelInfo model,
    required Function(double progress, String status) onProgress,
    required Function() onComplete,
    required Function(String error) onError,
  }) async {
    try {
      final dir = await getModelDir(model.id);
      await Directory(dir).create(recursive: true);

      final totalFiles = model.files.length;

      for (int i = 0; i < totalFiles; i++) {
        final file = model.files[i];
        final progress = i / totalFiles;

        onProgress(progress, '${file.name} indiriliyor... (${i + 1}/$totalFiles)');

        await _downloadFile(
          url: file.url,
          savePath: '$dir/${file.name}',
          onProgress: (fileProgress) {
            final overall = (i + fileProgress) / totalFiles;
            onProgress(overall, '${file.name} indiriliyor... (${i + 1}/$totalFiles)');
          },
        );
      }

      onProgress(1.0, 'Tamamlandı!');
      onComplete();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> _downloadFile({
    required String url,
    required String savePath,
    required Function(double) onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('İndirme hatası: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    final file = File(savePath);
    final sink = file.openWrite();

    int downloaded = 0;

    await for (final chunk in response.stream) {
      sink.add(chunk);
      downloaded += chunk.length;
      if (contentLength > 0) {
        onProgress(downloaded / contentLength);
      }
    }

    await sink.close();
  }

  Future<void> deleteModel(String modelId) async {
    final dir = await getModelDir(modelId);
    final directory = Directory(dir);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }
}
