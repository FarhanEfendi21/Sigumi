import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/volcano_provider.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Aksesibilitas Inklusif')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SigumiTheme.primaryBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.accessibility_new, color: SigumiTheme.primaryBlue, size: 32),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'SIGUMI dirancang agar dapat digunakan oleh semua orang, termasuk penyandang disabilitas.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Ukuran Teks', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('A', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Slider(
                                value: provider.fontSize,
                                min: 0.8, max: 1.5, divisions: 7,
                                label: '${(provider.fontSize * 100).toInt()}%',
                                onChanged: (v) => provider.setFontSize(v),
                              ),
                            ),
                            const Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Text('Contoh teks ${(provider.fontSize * 100).toInt()}%',
                            style: TextStyle(fontSize: 14 * provider.fontSize)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: SwitchListTile(
                    title: const Text('Mode Kontras Tinggi'),
                    subtitle: const Text('Meningkatkan kontras warna', style: TextStyle(fontSize: 12)),
                    secondary: const Icon(Icons.contrast),
                    value: provider.highContrast,
                    onChanged: (v) => provider.setHighContrast(v),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: SwitchListTile(
                    title: const Text('Panduan Audio'),
                    subtitle: const Text('Text-to-speech untuk informasi penting', style: TextStyle(fontSize: 12)),
                    secondary: const Icon(Icons.volume_up, color: Colors.blue),
                    value: provider.audioGuidance,
                    onChanged: (v) => provider.setAudioGuidance(v),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.language, color: Colors.green),
                    title: const Text('Bahasa'),
                    subtitle: Text(provider.language == 'en' ? 'English' : 'Bahasa Indonesia',
                        style: const TextStyle(fontSize: 12)),
                    trailing: ToggleButtons(
                      isSelected: [provider.language == 'en', provider.language == 'id'],
                      onPressed: (i) => provider.setLanguage(i == 0 ? 'en' : 'id'),
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minWidth: 50, minHeight: 32),
                      children: const [Text('EN'), Text('ID')],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.school, color: Colors.orange, size: 24),
                      SizedBox(width: 12),
                      Expanded(child: Text('Tersedia dalam bahasa Inggris dan Indonesia.',
                          style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
