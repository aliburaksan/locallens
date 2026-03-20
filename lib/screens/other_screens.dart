import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

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
