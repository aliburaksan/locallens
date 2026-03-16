import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ── Models Screen ────────────────────────────────────────────────

class ModelPack {
  final String id;
  final String name;
  final String size;
  bool downloaded;
  double progress;

  ModelPack({
    required this.id,
    required this.name,
    required this.size,
    this.downloaded = false,
    this.progress = 0,
  });
}

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  final _packs = [
    ModelPack(id: 'tr-en', name: 'TR ↔ EN', size: '98 MB', downloaded: true, progress: 100),
    ModelPack(id: 'tr-de', name: 'TR ↔ DE', size: '102 MB'),
    ModelPack(id: 'tr-fr', name: 'TR ↔ FR', size: '97 MB'),
    ModelPack(id: 'en-de', name: 'EN ↔ DE', size: '95 MB'),
  ];

  String? _downloadingId;

  void _download(ModelPack pack) async {
    setState(() => _downloadingId = pack.id);

    for (double p = 0; p <= 100; p += (15 + (5 * (p / 100)))) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => pack.progress = p.clamp(0, 100));
    }

    setState(() {
      pack.progress = 100;
      pack.downloaded = true;
      _downloadingId = null;
    });
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
              const Text('Dil Modelleri', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              const Text('Cihazınıza indirilen modeller offline çalışır', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 20),
              _buildStorageBar(),
              const SizedBox(height: 20),
              const SectionLabel('Mevcut Paketler'),
              ..._packs.map((p) => _buildPackCard(p)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageBar() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Depolama Kullanımı', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              const Text('98 MB / 2 GB', style: TextStyle(color: AppColors.primary, fontSize: 12, fontFamily: 'DMMono')),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 0.05,
              backgroundColor: AppColors.elevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(ModelPack pack) {
    final isDownloading = _downloadingId == pack.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(
            color: pack.downloaded ? AppColors.successBorder : AppColors.cardBorder,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pack.downloaded ? AppColors.successMuted : AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🌐', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pack.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(pack.size, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'DMMono')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isDownloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: pack.progress / 100,
                        backgroundColor: AppColors.elevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('${pack.progress.toInt()}% indiriliyor...', style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                  ] else
                    Text(
                      pack.downloaded ? '✓ Yüklü • Offline kullanılabilir' : 'İndirilmedi',
                      style: TextStyle(color: pack.downloaded ? AppColors.success : AppColors.textMuted, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (!pack.downloaded && !isDownloading) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _download(pack),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    border: Border.all(color: AppColors.primaryBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('⬇', style: TextStyle(color: AppColors.primaryLight, fontSize: 14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── History Screen ───────────────────────────────────────────────

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _items = [
    {'name': 'Sözleşme_2024.pdf', 'from': 'TR', 'to': 'EN', 'time': 'Bugün 14:23', 'pages': '12', 'size': '2.1 MB'},
    {'name': 'Report_Q3.docx', 'from': 'EN', 'to': 'TR', 'time': 'Dün 09:11', 'pages': '5', 'size': '840 KB'},
    {'name': 'screenshot_001.png', 'from': 'DE', 'to': 'TR', 'time': '15 Mar', 'pages': '1', 'size': '320 KB'},
    {'name': 'Manual_v2.pdf', 'from': 'EN', 'to': 'TR', 'time': '12 Mar', 'pages': '48', 'size': '8.4 MB'},
  ];

  String _icon(String name) {
    if (name.endsWith('.pdf')) return '📕';
    if (name.endsWith('.docx')) return '📘';
    return '🖼️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Geçmiş', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              const Text('Tüm işlemler yalnızca bu cihazda saklanır', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildItem(_items[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, String> item) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {},
      child: Row(
        children: [
          Text(_icon(item['name']!), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${item['from']} → ${item['to']} • ${item['pages']} sayfa • ${item['size']}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item['time']!, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('TAMAMLANDI', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
