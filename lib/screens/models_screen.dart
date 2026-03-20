import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/model_download_service.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  final _downloadService = ModelDownloadService();
  final Map<String, bool> _downloaded = {};
  final Map<String, double> _progress = {};
  final Map<String, String> _status = {};
  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
  }

  Future<void> _checkDownloadedModels() async {
    for (final model in ModelDownloadService.availableModels) {
      final isDownloaded = await _downloadService.isModelDownloaded(model.id);
      if (mounted) {
        setState(() => _downloaded[model.id] = isDownloaded);
      }
    }
  }

  Future<void> _downloadModel(ModelInfo model) async {
    setState(() {
      _downloading.add(model.id);
      _progress[model.id] = 0;
      _status[model.id] = 'Başlıyor...';
    });

    await _downloadService.downloadModel(
      model: model,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _progress[model.id] = progress;
            _status[model.id] = status;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _downloading.remove(model.id);
            _downloaded[model.id] = true;
            _progress[model.id] = 1.0;
            _status[model.id] = 'Tamamlandı';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${model.name} modeli hazır!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _downloading.remove(model.id);
            _progress.remove(model.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $error'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteModel(ModelInfo model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Modeli Sil',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${model.name} modeli silinecek. Tekrar kullanmak için indirmen gerekecek.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _downloadService.deleteModel(model.id);
      if (mounted) {
        setState(() => _downloaded[model.id] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dil Modelleri',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'İndirilen modeller internet olmadan çalışır',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              _buildInfoCard(),
              const SizedBox(height: 20),
              const SectionLabel('Mevcut Modeller'),
              ...ModelDownloadService.availableModels
                  .map((m) => _buildModelCard(m)),
              const SizedBox(height: 16),
              _buildComingSoonCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nasıl Çalışır?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Modeli bir kez indir, sonra internet olmadan kullan. Her dil çifti ayrı model gerektirir.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(ModelInfo model) {
    final isDownloaded = _downloaded[model.id] ?? false;
    final isDownloading = _downloading.contains(model.id);
    final progress = _progress[model.id] ?? 0.0;
    final status = _status[model.id] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(
            color: isDownloaded
                ? AppColors.successBorder
                : AppColors.cardBorder,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDownloaded
                        ? AppColors.successMuted
                        : AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      isDownloaded ? '✓' : '🌐',
                      style: TextStyle(
                        fontSize: isDownloaded ? 20 : 18,
                        color: isDownloaded
                            ? AppColors.success
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDownloaded
                            ? '✓ Yüklü • Offline kullanılabilir'
                            : isDownloading
                                ? status
                                : 'Boyut: ${model.size}',
                        style: TextStyle(
                          color: isDownloaded
                              ? AppColors.success
                              : AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDownloaded && !isDownloading)
                  GestureDetector(
                    onTap: () => _downloadModel(model),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'İndir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (isDownloaded)
                  GestureDetector(
                    onTap: () => _deleteModel(model),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            if (isDownloading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.elevated,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '%${(progress * 100).toInt()}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard() {
    final upcoming = [
      {'name': 'EN → TR', 'flag': '🇬🇧'},
      {'name': 'TR → DE', 'flag': '🇩🇪'},
      {'name': 'TR → FR', 'flag': '🇫🇷'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yakında',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...upcoming.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(l['flag']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(
                      l['name']!,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Yakında',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
