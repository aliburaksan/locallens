import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/ocr_service.dart';
import '../services/translation_service.dart';
import '../services/image_overlay_service.dart';
import '../services/gallery_saver_service.dart';

enum TranslateStep { idle, picking, ocr, translating, rendering, done, error }

class ImageTranslateScreen extends StatefulWidget {
  const ImageTranslateScreen({super.key});

  @override
  State<ImageTranslateScreen> createState() => _ImageTranslateScreenState();
}

class _ImageTranslateScreenState extends State<ImageTranslateScreen> {
  final _ocrService = OcrService();
  final _translationService = TranslationService();
  final _overlayService = ImageOverlayService();
  final _gallerySaver = GallerySaverService();

  File? _originalImage;
  File? _resultImage;
  TranslateStep _step = TranslateStep.idle;
  String _errorMessage = '';
  int _detectedBlocks = 0;
  String _sourceLang = 'TR';
  String _targetLang = 'EN';
  bool _savedToGallery = false;

  Future<void> _pickAndTranslate() async {
    setState(() => _step = TranslateStep.picking);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null) {
        setState(() => _step = TranslateStep.idle);
        return;
      }

      _originalImage = File(picked.path);
      _savedToGallery = false;

      // Step 1: OCR
      setState(() => _step = TranslateStep.ocr);
      final blocks = await _ocrService.recognizeText(_originalImage!);

      if (blocks.isEmpty) {
        setState(() {
          _step = TranslateStep.error;
          _errorMessage = 'Görüntüde metin bulunamadı';
        });
        return;
      }

      _detectedBlocks = blocks.length;

      // Step 2: Translate
      setState(() => _step = TranslateStep.translating);
      final texts = blocks.map((b) => b.text).toList();
      final translated = await _translationService.translateBatch(
        texts: texts,
        from: _sourceLang,
        to: _targetLang,
      );

      // Step 3: Render overlay
      setState(() => _step = TranslateStep.rendering);
      final resultFile = await _overlayService.applyOverlay(
        originalImage: _originalImage!,
        blocks: blocks,
        translatedTexts: translated,
      );

      setState(() {
        _resultImage = resultFile;
        _step = TranslateStep.done;
      });
    } catch (e) {
      setState(() {
        _step = TranslateStep.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _saveToGallery() async {
    if (_resultImage == null) return;
    final success = await _gallerySaver.saveToGallery(_resultImage!);
    setState(() => _savedToGallery = success);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✓ Galeriye kaydedildi' : 'Kaydetme başarısız'),
          backgroundColor: success ? AppColors.success : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _reset() {
    setState(() {
      _originalImage = null;
      _resultImage = null;
      _step = TranslateStep.idle;
      _errorMessage = '';
      _detectedBlocks = 0;
      _savedToGallery = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görüntü Çeviri'),
        actions: [
          if (_step == TranslateStep.done)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Yeni çeviri',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildLangSelector(),
              const SizedBox(height: 16),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangSelector() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _LangChip(
            lang: _sourceLang,
            onTap: () => _showLangPicker(true),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              final tmp = _sourceLang;
              _sourceLang = _targetLang;
              _targetLang = tmp;
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                border: Border.all(color: AppColors.primaryBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('⇄',
                  style:
                      TextStyle(color: AppColors.primaryLight, fontSize: 18)),
            ),
          ),
          const Spacer(),
          _LangChip(
            lang: _targetLang,
            onTap: () => _showLangPicker(false),
          ),
        ],
      ),
    );
  }

  void _showLangPicker(bool isSource) {
    const langs = [
      {'code': 'TR', 'name': 'Türkçe', 'flag': '🇹🇷'},
      {'code': 'EN', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'DE', 'name': 'Deutsch', 'flag': '🇩🇪'},
      {'code': 'FR', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'ES', 'name': 'Español', 'flag': '🇪🇸'},
      {'code': 'AR', 'name': 'العربية', 'flag': '🇸🇦'},
      {'code': 'ZH', 'name': '中文', 'flag': '🇨🇳'},
      {'code': 'RU', 'name': 'Русский', 'flag': '🇷🇺'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSource ? 'Kaynak Dil' : 'Hedef Dil',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: langs.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSource) {
                      _sourceLang = langs[i]['code']!;
                    } else {
                      _targetLang = langs[i]['code']!;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(langs[i]['flag']!,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        langs[i]['name']!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case TranslateStep.idle:
        return _buildIdleState();
      case TranslateStep.picking:
        return _buildLoadingState('Görüntü seçiliyor...');
      case TranslateStep.ocr:
        return _buildLoadingState('Metin tanınıyor...\nML Kit analiz ediyor');
      case TranslateStep.translating:
        return _buildLoadingState(
            'Çevriliyor...\n$_detectedBlocks metin bloğu bulundu');
      case TranslateStep.rendering:
        return _buildLoadingState('Overlay oluşturuluyor...');
      case TranslateStep.done:
        return _buildResultState();
      case TranslateStep.error:
        return _buildErrorState();
    }
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndTranslate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primaryLight.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(color: AppColors.primaryBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('🖼️', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Görüntü Seç',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Galeriden bir ekran görüntüsü\nveya fotoğraf seç',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 6,
                  children: [
                    FormatTag('PNG'),
                    FormatTag('JPG'),
                    FormatTag('WEBP'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const PrivacyBanner(),
      ],
    );
  }

  Widget _buildLoadingState(String message) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    return Column(
      children: [
        // Result image
        AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              _resultImage!,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Stats
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(label: 'Blok', value: '$_detectedBlocks'),
              _StatChip(label: 'Kaynak', value: _sourceLang),
              _StatChip(label: 'Hedef', value: _targetLang),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Actions
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: _savedToGallery ? '✓ Kaydedildi' : '⬇ Galeriye Kaydet',
                onTap: _savedToGallery ? null : _saveToGallery,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      '↩ Yeni Çeviri',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Tekrar Dene', onTap: _pickAndTranslate),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String lang;
  final VoidCallback onTap;

  const _LangChip({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          lang,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
