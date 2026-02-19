import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../config/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profil & Pengaturan')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: SigumiTheme.primaryLight,
                          child: Icon(Icons.person, size: 40, color: SigumiTheme.primaryBlue),
                        ),
                        const SizedBox(height: 12),
                        Text('Pengguna SIGUMI',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('pengguna@sigumi.id',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: SigumiTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Bahasa: ${provider.language == "en" ? "English" : "Indonesia"}',
                            style: const TextStyle(fontSize: 12, color: SigumiTheme.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsTile(
                  icon: Icons.accessibility_new, title: 'Aksesibilitas',
                  subtitle: 'Ukuran teks, kontras, audio',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.accessibility),
                ),
                _SettingsTile(
                  icon: Icons.language, title: 'Bahasa',
                  subtitle: provider.language == 'en' ? 'English' : 'Bahasa Indonesia',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.accessibility),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined, title: 'Notifikasi',
                  subtitle: 'Atur peringatan dini & notifikasi',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.cloud_off_outlined, title: 'Data Offline',
                  subtitle: provider.isOffline ? 'Mode offline aktif' : 'Mode online',
                  trailing: Switch(
                    value: provider.isOffline,
                    onChanged: (_) => provider.toggleOffline(),
                  ),
                  onTap: () => provider.toggleOffline(),
                ),
                _SettingsTile(
                  icon: Icons.info_outline, title: 'Tentang SIGUMI',
                  subtitle: 'Versi 1.0.0',
                  onTap: () => _showAbout(context),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Keluar', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tentang SIGUMI'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SIGUMI v1.0.0'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: SigumiTheme.primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: SigumiTheme.primaryBlue, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
