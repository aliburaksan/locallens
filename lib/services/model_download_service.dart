import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
<<<<<<< HEAD
        ModelFile(
            name: 'decoder_model.onnx',
            url: '$_baseUrl/decoder_model.onnx'),
        ModelFile(
            name: 'encoder_model.onnx',
            url: '$_baseUrl/encoder_model.onnx'),
=======
        ModelFile(name: 'decoder_model.onnx', url: '$_baseUrl/decoder_model.onnx'),
        ModelFile(name: 'encoder_model.onnx', url: '$_baseUrl/encoder_model.onnx'),
>>>>>>> 69dd1de4df981552b320974360a160dd9b52c986
        ModelFile(name: 'source.spm', url: '$_baseUrl/source.spm'),
        ModelFile(name: 'target.spm', url: '$_baseUrl/target.spm'),
      ],
    ),
  ];

  // Kalıcı depolama — uygulama silinmediği sürece model korunur
  Future<String> getModelDir(String modelId) async {
    late String basePath;

    if (Platform.isAndroid) {
      // Android'de harici depolama — daha kalıcı
      final externalDirs = await getExternalStorageDirectories();
      if (externalDirs != null && externalDirs.isNotEmpty) {
        basePath = externalDirs.first.path;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        basePath = appDir.path;
      }
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      basePath = appDir.path;
    }

    final dir = '$basePath/LocalLens/models/$modelId';
    await Directory(dir).create(recursive: true);
    return dir;
  }

  Future<bool> isModelDownloaded(String modelId) async {
    try {
      final dir = await getModelDir(modelId);
      final encoderFile = File('$dir/encoder_model.onnx');
      final decoderFile = File('$dir/decoder_model.onnx');
      return encoderFile.existsSync() &&
          decoderFile.existsSync() &&
          encoderFile.lengthSync() > 1000;
    } catch (e) {
      return false;
    }
  }

  Future<void> downloadModel({
    required ModelInfo model,
    required Function(double progress, String status) onProgress,
    required Function() onComplete,
    required Function(String error) onError,
  }) async {
    // Ekran açık kalsın
    await WakelockPlus.enable();

    try {
      final dir = await getModelDir(model.id);
      final totalFiles = model.files.length;

      for (int i = 0; i < totalFiles; i++) {
        final file = model.files[i];

        onProgress(
          i / totalFiles,
          '${file.name} indiriliyor... (${i + 1}/$totalFiles)',
        );

        await _downloadFile(
          url: file.url,
          savePath: '$dir/${file.name}',
          onProgress: (fileProgress) {
            final overall = (i + fileProgress) / totalFiles;
            onProgress(
              overall,
              '${file.name} (${(fileProgress * 100).toInt()}%) — ${i + 1}/$totalFiles',
            );
          },
        );
      }

      onProgress(1.0, 'Tamamlandı!');
      onComplete();
    } catch (e) {
      onError(e.toString());
    } finally {
      await WakelockPlus.disable();
    }
  }

  Future<void> _downloadFile({
    required String url,
    required String savePath,
    required Function(double) onProgress,
  }) async {
    // Kısmi indirme desteği — ekran kilitlense bile devam eder
    final file = File(savePath);
    int existingBytes = 0;

    if (file.existsSync()) {
      existingBytes = file.lengthSync();
    }

    final request = http.Request('GET', Uri.parse(url));
    if (existingBytes > 0) {
      request.headers['Range'] = 'bytes=$existingBytes-';
    }

    final response = await http.Client().send(request);

    if (response.statusCode != 200 && response.statusCode != 206) {
      throw Exception('İndirme hatası: ${response.statusCode}');
    }

    final contentLength = (response.contentLength ?? 0) + existingBytes;
    final sink = file.openWrite(
      mode: existingBytes > 0 ? FileMode.append : FileMode.write,
    );

    int downloaded = existingBytes;

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
    try {
      final dir = await getModelDir(modelId);
      final directory = Directory(dir);
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      // ignore
    }
  }
}
