import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TranslateScreen extends StatefulWidget {
  final PlatformFile? file;
  final String sourceLang;
  final String targetLang;

  const TranslateScreen({
    super.key,
    this.file,
    this.sourceLang = 'TR',
    this.targetLang = 'EN',
  });

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  // idle | processing | done
  String _state = 'idle';
  String _activeTab = 'result';

  final _steps = [
    {'label': 'Metin çıkarılıyor', 'done': false, 'active': false},
    {'label': 'Bloklar analiz ediliyor', 'done': false, 'active': false},
    {'label': 'OPUS-MT çeviriyor', 'done': false, 'active': false},
    {'label': 'Layout yeniden oluşturuluyor', 'done': false, 'active': false},
  ];

  void _startTranslation() async {
    setState(() => _state = 'processing');

    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        if (i > 0) _steps[i - 1]['done'] = true;
        _steps[i]['active'] = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _steps[_steps.length - 1]['done'] = true;
      _steps[_steps.length - 1]['active'] = false;
      _state = 'done';
    });
  }

  String _fileIcon(String? name) {
    if (name == null) return '📄';
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return '📕';
    if (ext == 'docx' || ext == 'doc') return '📘';
    if (['png', 'jpg', 'jpeg', 'webp'].contains(ext)) return '🖼️';
    return '📄';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.file == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Çeviri')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📂', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Önce bir dosya yükleyin', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çeviri'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildFileCard(),
              const SizedBox(height: 14),
              if (_state == 'idle') _buildIdleState(),
              if (_state == 'processing') _buildProcessingState(),
              if (_state == 'done') _buildDoneState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    final file = widget.file!;
    final sizeKb = ((file.size ?? 0) / 1024).toStringAsFixed(1);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), AppColors.card],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(_fileIcon(file.name), style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$sizeKb KB • ${widget.sourceLang} → ${widget.targetLang}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'DMMono'),
                ),
              ],
            ),
          ),
          StatusBadge.local(),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: Column(
              children: [
                const Text('⏳', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                const Text('Çeviri başlatılmadı', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  'Aşağıdaki butona basarak başlatın',
                  style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(label: 'Çeviriyi Başlat →', onTap: _startTranslation),
      ],
    );
  }

  Widget _buildProcessingState() {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), AppColors.card],
                  ),
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(_fileIcon(widget.file?.name), style: const TextStyle(fontSize: 32)),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  builder: (_, v, __) => Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.primary.withOpacity(v), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('İşleniyor...', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Metin çıkarılıyor ve çevriliyor', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          ..._steps.map(_buildStep),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStep(Map<String, dynamic> step) {
    final isDone = step['done'] as bool;
    final isActive = step['active'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDone ? AppColors.successMuted : isActive ? AppColors.primaryMuted : AppColors.elevated,
              border: Border.all(
                color: isDone ? AppColors.successBorder : isActive ? AppColors.primaryBorder : AppColors.cardBorder,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? const Text('✓', style: TextStyle(color: AppColors.success, fontSize: 10))
                  : isActive
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        )
                      : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            step['label'] as String,
            style: TextStyle(
              color: isDone ? AppColors.success : isActive ? AppColors.primaryLight : AppColors.textDim,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneState() {
    return Column(
      children: [
        // Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: ['result', 'original'].map((tab) {
              final isActive = _activeTab == tab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryMuted : Colors.transparent,
                      border: Border.all(
                        color: isActive ? AppColors.primaryBorder : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        tab == 'result' ? 'Çeviri' : 'Orijinal',
                        style: TextStyle(
                          color: isActive ? AppColors.primaryLight : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Preview
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                height: 260,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 140, height: 10, decoration: BoxDecoration(color: const Color(0xFF1A1A2A), borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 8),
                        Container(width: 90, height: 8, decoration: BoxDecoration(color: const Color(0xFF2A2A3A), borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 14),
                        ...[90, 80, 95, 70, 85].map((w) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: FractionallySizedBox(
                                widthFactor: w / 100,
                                child: Container(
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _activeTab == 'result'
                                        ? AppColors.primary.withOpacity(0.2)
                                        : const Color(0xFFD0D0C8),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 14),
                        ...[75, 88, 65, 92, 78].map((w) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: FractionallySizedBox(
                                widthFactor: w / 100,
                                child: Container(
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _activeTab == 'result'
                                        ? AppColors.primary.withOpacity(0.15)
                                        : const Color(0xFFD0D0C8),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                    if (_activeTab == 'result')
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.targetLang,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('1 / 12 sayfa', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'DMMono')),
                    const Text('Layout korundu ✓', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Actions
        Row(
          children: [
            Expanded(child: PrimaryButton(label: '⬇ İndir PDF', onTap: () {})),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('↗ Paylaş', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
