import 'dart:io';
import 'package:gal/gal.dart';

class GallerySaverService {
  static final GallerySaverService _instance = GallerySaverService._internal();
  factory GallerySaverService() => _instance;
  GallerySaverService._internal();

  Future<bool> saveToGallery(File imageFile) async {
    try {
      await Gal.putImage(imageFile.path, album: 'LocalLens');
      return true;
    } catch (e) {
      return false;
    }
  }
}
