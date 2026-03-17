import 'dart:io';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class GallerySaverService {
  static final GallerySaverService _instance = GallerySaverService._internal();
  factory GallerySaverService() => _instance;
  GallerySaverService._internal();

  Future<bool> saveToGallery(File imageFile) async {
    // Request permission
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final photos = await Permission.photos.request();
        if (!photos.isGranted) return false;
      }
    }

    final result = await ImageGallerySaver.saveFile(
      imageFile.path,
      name: 'LocalLens_${DateTime.now().millisecondsSinceEpoch}',
    );

    return result['isSuccess'] == true;
  }
}
