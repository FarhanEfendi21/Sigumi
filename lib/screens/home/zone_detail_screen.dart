import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/volcano_provider.dart';

class ZoneDetailScreen extends StatelessWidget {
  const ZoneDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final distance = provider.distanceFromMerapi;
        final zoneLevel = provider.zoneLevel;
        final zoneColor = SigumiTheme.getStatusColor(zoneLevel);
        final volcano = provider.volcano;
        final mq = MediaQuery.of(context);
        final screenW = mq.size.width;
        final hPad = screenW > 500 ? 32.0 : 20.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: zoneColor,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Status Zona',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero header ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [zoneColor, zoneColor.withAlpha(180)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Zone name
                      Text(
                        provider.zoneLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km dari puncak ${volcano.name}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withAlpha(220),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.05, end: 0, duration: 400.ms),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Position Info ──
                      _buildSectionCard(
                        icon: Icons.my_location_rounded,
                        iconColor: zoneColor,
                        title: 'Posisi Anda Saat Ini',
                        child: Column(
                          children: [
                            _buildInfoRow('Jarak dari Puncak',
                                '${distance.toStringAsFixed(1)} km',
                                Icons.straighten_rounded),
                            const Divider(height: 20),
                            _buildInfoRow('Zona Saat Ini',
                                provider.zoneLabel,
                                Icons.shield_outlined,
                                valueColor: zoneColor),
                            const Divider(height: 20),
                            _buildInfoRow('Status Gunung',
                                volcano.statusLabel,
                                Icons.landscape_rounded,
                                valueColor: SigumiTheme.getStatusColor(
                                    volcano.statusLevel)),
                            const Divider(height: 20),
                            _buildInfoRow('Terakhir Diperbarui',
                                _formatTime(volcano.lastUpdate),
                                Icons.update_rounded),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                      const SizedBox(height: 14),

                      // ── Aktivitas Terkini ──
                      _buildSectionCard(
                        icon: Icons.history_rounded,
                        iconColor: Colors.deepPurple,
                        title: 'Aktivitas Terkini',
                        child: Column(
                          children: List.generate(
                            volcano.recentActivities.length,
                            (i) => _buildActivityItem(
                              volcano.recentActivities[i],
                              i,
                              volcano.recentActivities.length,
                              SigumiTheme.getStatusColor(volcano.statusLevel),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Zone-specific advice ──
                      _buildCurrentZoneAdvice(zoneLevel, zoneColor),

                      const SizedBox(height: 20),

                      // ── All Zones ──
                      Text(
                        'Pembagian Zona KRB Merapi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kawasan Rawan Bencana berdasarkan jarak dari puncak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF6B6B78),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildZoneCard(
                        level: 4,
                        title: 'ZONA BAHAYA UTAMA',
                        subtitle: 'KRB III — Radius ≤ 5 km',
                        description:
                            'Area terlarang untuk aktivitas apapun. Rawan awan panas, '
                            'lontaran material vulkanik, dan aliran lava.',
                        isActive: zoneLevel == 4,
                        delay: 100,
                      ),
                      _buildZoneCard(
                        level: 3,
                        title: 'ZONA WASPADA',
                        subtitle: 'KRB II — Radius 5–10 km',
                        description:
                            'Rawan lahar hujan, hujan abu vulkanik, dan potensi awan '
                            'panas pada erupsi besar.',
                        isActive: zoneLevel == 3,
                        delay: 200,
                      ),
                      _buildZoneCard(
                        level: 2,
                        title: 'ZONA PERHATIAN',
                        subtitle: 'KRB I — Radius 10–15 km',
                        description:
                            'Berpotensi terkena hujan abu dan lahar hujan melalui '
                            'aliran sungai.',
                        isActive: zoneLevel == 2,
                        delay: 300,
                      ),
                      _buildZoneCard(
                        level: 1,
                        title: 'ZONA RELATIF AMAN',
                        subtitle: 'Di luar KRB — Radius > 15 km',
                        description:
                            'Di luar kawasan rawan bencana langsung. Tetap pantau '
                            'informasi dan waspadai dampak sekunder.',
                        isActive: zoneLevel == 1,
                        delay: 400,
                      ),

                      const SizedBox(height: 14),

                      // ── Weather ──
                      if (volcano.temperature != null ||
                          volcano.windDirection != null)
                        _buildSectionCard(
                          icon: Icons.air_rounded,
                          iconColor: Colors.blue,
                          title: 'Kondisi Cuaca',
                          child: Column(
                            children: [
                              if (volcano.temperature != null)
                                _buildInfoRow('Suhu',
                                    '${volcano.temperature!.toInt()}°C',
                                    Icons.thermostat_rounded),
                              if (volcano.temperature != null &&
                                  volcano.windDirection != null)
                                const Divider(height: 20),
                              if (volcano.windDirection != null)
                                _buildInfoRow('Arah Angin',
                                    volcano.windDirection!,
                                    Icons.navigation_rounded),
                              if (volcano.windSpeed != null) ...[
                                const Divider(height: 20),
                                _buildInfoRow('Kec. Angin',
                                    '${volcano.windSpeed!.toInt()} km/jam',
                                    Icons.speed_rounded),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                      const SizedBox(height: 14),

                      // ── Tips ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF3E0), Color(0xFFFFF8E1)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withAlpha(50),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_rounded,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tips Kesiapsiagaan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Siapkan tas siaga: dokumen penting, obat, '
                                    'pakaian ganti, makanan, senter. '
                                    'Hafalkan jalur evakuasi terdekat.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF6B6B78),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                      const SizedBox(height: 16),

                      Center(
                        child: Text(
                          'Sumber: PVMBG, BPPTKG, BPBD',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF9E9EAE),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentZoneAdvice(int zoneLevel, Color zoneColor) {
    final advice = {
      4: {
        'icon': Icons.warning_amber_rounded,
        'title': 'Anda di Zona Bahaya!',
        'items': [
          'Segera evakuasi jika status naik ke Siaga/Awas',
          'Jangan beraktivitas di radius 3 km dari puncak',
          'Waspadai awan panas, lontaran material, dan lahar',
          'Siapkan jalur evakuasi dan tas darurat',
        ],
      },
      3: {
        'icon': Icons.notification_important_rounded,
        'title': 'Zona Waspada — Tingkatkan Kewaspadaan',
        'items': [
          'Siapkan rencana evakuasi keluarga',
          'Pantau informasi dari BPPTKG dan BPBD',
          'Siapkan masker dan pelindung mata',
          'Waspadai aliran lahar di sungai-sungai',
        ],
      },
      2: {
        'icon': Icons.info_outline_rounded,
        'title': 'Zona Perhatian — Tetap Waspada',
        'items': [
          'Pantau perkembangan status gunung',
          'Siapkan masker untuk hujan abu',
          'Hindari bantaran sungai saat hujan deras',
          'Simpan nomor darurat di ponsel',
        ],
      },
      1: {
        'icon': Icons.check_circle_outline_rounded,
        'title': 'Zona Aman — Tetap Informasi',
        'items': [
          'Posisi Anda relatif aman dari ancaman langsung',
          'Tetap pantau berita dan arahan resmi',
          'Waspadai dampak sekunder jika erupsi besar',
          'Bantu sebarkan info ke masyarakat rentan',
        ],
      },
    };

    final data = advice[zoneLevel]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: zoneColor.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: zoneColor.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data['icon'] as IconData, color: zoneColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  data['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: zoneColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate((data['items'] as List).length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: zoneColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (data['items'] as List)[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF3A3A4A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildZoneCard({
    required int level,
    required String title,
    required String subtitle,
    required String description,
    required bool isActive,
    required int delay,
  }) {
    final color = SigumiTheme.getStatusColor(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? color.withAlpha(70) : const Color(0xFFE8E8ED),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(isActive ? 30 : 18),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(_zoneEmoji(level),
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Anda',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B6B78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B6B78),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9EAE)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B6B78),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String activity,
    int index,
    int total,
    Color statusColor,
  ) {
    final isLast = index == total - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot + line
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: index == 0
                      ? statusColor
                      : statusColor.withAlpha(50),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withAlpha(100),
                    width: 1.5,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: const Color(0xFFE0E0E8),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF3A3A4A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _fakeTimestamp(index),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF9E9EAE),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fakeTimestamp(int index) {
    final now = DateTime.now();
    final offset = Duration(hours: index * 6 + 2);
    final dt = now.subtract(offset);
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} WIB';
  }

  String _zoneEmoji(int level) {
    switch (level) {
      case 4: return '🔴';
      case 3: return '🟠';
      case 2: return '🟡';
      default: return '🟢';
    }
  }

  String _formatTime(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} WIB';
  }
}
