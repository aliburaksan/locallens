# LocalLens

Offline, zero-knowledge belge çeviri uygulaması.
PDF, DOCX ve görüntü dosyalarını layout koruyarak çevirir.
Tüm işlem cihazda gerçekleşir, hiçbir veri dışarı çıkmaz.

## Proje Yapısı

```
lib/
├── main.dart                  # Uygulama giriş noktası + navigasyon
├── theme/
│   └── app_theme.dart         # Renkler ve tema
├── widgets/
│   └── common_widgets.dart    # Ortak bileşenler
└── screens/
    ├── home_screen.dart       # Ana sayfa
    ├── translate_screen.dart  # Çeviri ekranı
    └── other_screens.dart     # Modeller + Geçmiş ekranları
```

## Kurulum

```bash
flutter pub get
flutter run
```

## Build (Codemagic)

1. Kodu GitHub'a push et
2. Codemagic dashboard → Start new build
3. Workflow seç: android-release veya ios-release
4. APK/IPA indir

## Sonraki Adımlar

- [ ] pdf_service.dart — koordinatlı PDF parse
- [ ] ocr_service.dart — ML Kit OCR entegrasyonu
- [ ] translation_service.dart — ONNX Runtime çeviri
- [ ] export_service.dart — layout korumalı PDF üretimi
