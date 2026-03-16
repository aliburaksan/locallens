import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'translate_screen.dart';

const _languages = [
  {'code': 'TR', 'name': 'Türkçe', 'flag': '🇹🇷'},
  {'code': 'EN', 'name': 'English', 'flag': '🇬🇧'},
  {'code': 'DE', 'name': 'Deutsch', 'flag': '🇩🇪'},
  {'code': 'FR', 'name': 'Français', 'flag': '🇫🇷'},
  {'code': 'ES', 'name': 'Español', 'flag': '🇪🇸'},
  {'code': 'AR', 'name': 'العربية', 'flag': '🇸🇦'},
  {'code': 'ZH', 'name': '中文', 'flag': '🇨🇳'},
  {'code': 'RU', 'name': 'Русский', 'flag': '🇷🇺'},
];

final _recentFiles = [
  {'name': 'Sözleşme_2024.pdf', 'from': 'TR', 'to': 'EN', 'time': '2 saat önce', 'pages': '12'},
  {'name': 'Report_Q3.docx', 'from': 'EN', 'to': 'TR', 'time': 'Dün', 'pages': '5'},
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sourceLang = 'TR';
  String _targetLang = 'EN';

  Map<String, String> _langData(String code) =>
      _languages.firstWhere((l) => l['code'] == code);

  void _swapLanguages() {
    setState(() {
      final tmp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = tmp;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TranslateScreen(
            file: result.files.first,
            sourceLang: _sourceLang,
            targetLang: _targetLang,
          ),
        ),
      );
    }
  }

  void _showLangPicker(bool isSource) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              itemCount: _languages.length,
              itemBuilder: (_, i) {
                final lang = _languages[i];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSource) {
                        _sourceLang = lang['code']!;
                      } else {
                        _targetLang = lang['code']!;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.elevated,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          lang['name']!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
              _buildHeader(),
              const SizedBox(height: 24),
              _buildLangSelector(),
              const SizedBox(height: 14),
              _buildUploadZone(),
              const SizedBox(height: 14),
              const PrivacyBanner(),
              const SizedBox(height: 24),
              const SectionLabel('Son İşlemler'),
              ..._recentFiles.map(_buildRecentItem),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('🔒', style: TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LocalLens',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'v1.0 • zero-knowledge',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'DMMono',
              ),
            ),
          ],
        ),
        StatusBadge.offline(),
      ],
    );
  }

  Widget _buildLangSelector() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Dil Çifti'),
          Row(
            children: [
              Expanded(child: _LangButton(lang: _langData(_sourceLang), onTap: () => _showLangPicker(true))),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _swapLanguages,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    border: Border.all(color: AppColors.primaryBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('⇄', style: TextStyle(color: AppColors.primaryLight, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _LangButton(lang: _langData(_targetLang), onTap: () => _showLangPicker(false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder, width: 2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.primaryLight.withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: AppColors.primaryBorder),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(child: Text('⬆', style: TextStyle(fontSize: 24, color: AppColors.primaryLight))),
            ),
            const SizedBox(height: 14),
            const Text(
              'Dosya Yükle',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'PDF, DOCX veya Görüntü\nDosya seçmek için dokun',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 6,
              children: [
                FormatTag('PDF'),
                FormatTag('DOCX'),
                FormatTag('PNG'),
                FormatTag('JPG'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(Map<String, String> item) {
    final isPdf = item['name']!.endsWith('.pdf');
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {},
      child: Row(
        children: [
          Text(isPdf ? '📕' : '📘', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['from']} → ${item['to']} • ${item['pages']} sayfa • ${item['time']}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Text('›', style: TextStyle(color: AppColors.textDim, fontSize: 18)),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final Map<String, String> lang;
  final VoidCallback onTap;

  const _LangButton({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E1A),
          border: Border.all(color: const Color(0xFF2A2A3A)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang['code']!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(lang['name']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
