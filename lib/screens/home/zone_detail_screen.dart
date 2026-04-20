import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/volcano_provider.dart';

/// ZoneDetailScreen — Halaman detail status zona bencana.
/// Tampilan dinamis berdasarkan level status gunung:
/// - Level 1–2 (Normal/Waspada): warna netral, zona KRB bisa di-collapse
/// - Level 3–4 (Siaga/Awas): warna urgent, zona KRB selalu tampil penuh
class ZoneDetailScreen extends StatefulWidget {
  const ZoneDetailScreen({super.key});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  // State collapse/expand untuk section KRB (level 1–2)
  bool _isKrbExpanded = false;

  // Warna background halaman berdasarkan JARAK user ke gunung (zoneLevel)
  Color _getPageBgColor(int zoneLevel) {
    switch (zoneLevel) {
      case 4:
        return const Color(0xFFFFF1F1); // merah soft — Zona Bahaya
      case 3:
        return const Color(0xFFFFF4EC); // oranye soft — Zona Waspada
      case 2:
        return const Color(0xFFFFF8E8); // amber soft — Zona Perhatian
      default:
        return const Color(0xFFF7F8FA); // abu-abu netral — Zona Aman
    }
  }

  // Warna header AppBar berdasarkan JARAK user ke gunung (zoneLevel)
  Color _getHeaderColor(int zoneLevel) {
    return SigumiTheme.getStatusColor(zoneLevel);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final distance = provider.distanceFromMerapi;
        final zoneLevel = provider.zoneLevel;
        final zoneColor = SigumiTheme.getStatusColor(zoneLevel);
        final volcano = provider.volcano;
        final volcanoLevel = volcano.statusLevel;
        final isHighAlert = volcanoLevel >= 3;

        // Warna dari JARAK user (zoneLevel), bukan status gunung
        final headerColor = _getHeaderColor(zoneLevel);
        final pageBg = _getPageBgColor(zoneLevel);

        final mq = MediaQuery.of(context);
        final screenW = mq.size.width;
        final hPad = screenW > 500 ? 32.0 : 20.0;

        // Font style dinamis berdasarkan level gunung
        final heroFontWeight =
            isHighAlert ? FontWeight.w800 : FontWeight.w700;
        final heroFontStyle =
            isHighAlert ? FontStyle.italic : FontStyle.normal;

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: headerColor,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Status Zona',
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            // ── Tombol Refresh di AppBar ──
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: 'Perbarui data status',
                  icon: provider.isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 22),
                  onPressed: provider.isRefreshing
                      ? null
                      : () => provider.forceRefresh(),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Header — Dinamis berdasarkan level ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [headerColor, headerColor.withAlpha(180)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Badge urgent saat level tinggi
                      if (isHighAlert) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                volcanoLevel == 4
                                    ? 'AWAS — SIAGA PENUH'
                                    : 'SIAGA — TINGKATKAN KEWASPADAAN',
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Zone name
                      Text(
                        provider.zoneLabel,
                        textAlign: TextAlign.center,
                        style: AppFonts.plusJakartaSans(
                          fontSize: isHighAlert ? 23 : 20,
                          fontWeight: heroFontWeight,
                          fontStyle: heroFontStyle,
                          color: Colors.white,
                          letterSpacing: isHighAlert ? 0.5 : 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km dari puncak ${volcano.name}',
                        textAlign: TextAlign.center,
                        style: AppFonts.plusJakartaSans(
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
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
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
                            _buildInfoRow(
                              'Jarak dari Puncak',
                              '${distance.toStringAsFixed(1)} km',
                              Icons.straighten_rounded,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              'Zona Saat Ini',
                              provider.zoneLabel,
                              Icons.shield_outlined,
                              valueColor: zoneColor,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              'Status Gunung',
                              volcano.statusLabel,
                              Icons.landscape_rounded,
                              valueColor: SigumiTheme.getStatusColor(
                                volcanoLevel,
                              ),
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              'Terakhir Diperbarui',
                              _formatTime(volcano.lastUpdate),
                              Icons.update_rounded,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                      const SizedBox(height: 14),

                      // ── Aktivitas Terkini ──
                      _buildSectionCard(
                        icon: Icons.history_rounded,
                        iconColor: Colors.deepPurple,
                        title: 'Aktivitas Terkini',
                        child: volcano.recentActivities.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Belum ada data aktivitas terkini untuk saat ini.',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF9E9EAE),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : Column(
                                children: List.generate(
                                  volcano.recentActivities.length,
                                  (i) => _buildActivityItem(
                                    volcano.recentActivities[i],
                                    i,
                                    volcano.recentActivities.length,
                                    SigumiTheme.getStatusColor(
                                        volcanoLevel),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // ── Pembagian Zona KRB — Kondisional dengan dropdown ──
                      _buildKrbSection(
                          context, zoneLevel, isHighAlert, hPad),

                      Center(
                        child: Text(
                          'Sumber: PVMBG, BPPTKG, BPBD',
                          style: AppFonts.plusJakartaSans(
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

  // ────────────────────────────────────────────────────────
  // SECTION ZONA KRB — Selalu ada, tapi bisa di-collapse
  // Level 1–2: default collapsed, ada dropdown
  // Level 3–4: selalu expanded, tidak bisa di-collapse
  // ────────────────────────────────────────────────────────
  Widget _buildKrbSection(
    BuildContext context,
    int zoneLevel,
    bool isHighAlert,
    double hPad,
  ) {
    final showExpand = !isHighAlert;
    final isExpanded = isHighAlert || _isKrbExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section dengan tombol toggle
        GestureDetector(
          onTap: showExpand
              ? () => setState(() => _isKrbExpanded = !_isKrbExpanded)
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembagian Zona KRB',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isHighAlert
                            ? SigumiTheme.getStatusColor(
                                zoneLevel > 2 ? zoneLevel : 3)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kawasan Rawan Bencana berdasarkan jarak dari puncak',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF6B6B78),
                      ),
                    ),
                  ],
                ),
              ),
              if (showExpand) ...[
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isKrbExpanded ? -0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Konten zona — animasi expand/collapse
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              _buildZoneCard(
                level: 4,
                title: 'Zona Bahaya',
                subtitle: 'KRB III — Radius ≤ 5 km',
                description:
                    'Area terlarang untuk aktivitas apapun. Rawan awan panas, '
                    'lontaran material vulkanik, dan aliran lava.',
                isActive: zoneLevel == 4,
                isHighAlert: isHighAlert,
                delay: 0,
              ),
              _buildZoneCard(
                level: 3,
                title: 'Zona Waspada',
                subtitle: 'KRB II — Radius 5–10 km',
                description:
                    'Rawan lahar hujan, hujan abu vulkanik, dan potensi awan '
                    'panas pada erupsi besar.',
                isActive: zoneLevel == 3,
                isHighAlert: isHighAlert,
                delay: 80,
              ),
              _buildZoneCard(
                level: 2,
                title: 'Zona Perhatian',
                subtitle: 'KRB I — Radius 10–15 km',
                description:
                    'Berpotensi terkena hujan abu dan lahar hujan melalui '
                    'aliran sungai.',
                isActive: zoneLevel == 2,
                isHighAlert: isHighAlert,
                delay: 160,
              ),
              _buildZoneCard(
                level: 1,
                title: 'Zona Aman',
                subtitle: 'Di luar KRB — Radius > 15 km',
                description:
                    'Di luar kawasan rawan bencana langsung. Tetap pantau '
                    'informasi dan waspadai dampak sekunder.',
                isActive: zoneLevel == 1,
                isHighAlert: isHighAlert,
                delay: 240,
              ),
              const SizedBox(height: 16),
            ],
          ),
          secondChild: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ketuk untuk melihat pembagian zona kawasan rawan bencana',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneCard({
    required int level,
    required String title,
    required String subtitle,
    required String description,
    required bool isActive,
    required bool isHighAlert,
    required int delay,
  }) {
    final color = SigumiTheme.getStatusColor(level);

    // Saat gunung level tinggi, font judul zona lebih bold dan warna lebih intens
    final titleFontWeight =
        isHighAlert && isActive ? FontWeight.w800 : FontWeight.w700;
    final titleFontStyle =
        isHighAlert && isActive ? FontStyle.italic : FontStyle.normal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(isHighAlert ? 15 : 10) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? color.withAlpha(isHighAlert ? 100 : 70)
              : const Color(0xFFE8E8ED),
          width: isActive && isHighAlert ? 2 : (isActive ? 1.5 : 1),
        ),
        // Glow subtle saat active + high alert
        boxShadow: isActive && isHighAlert
            ? [
                BoxShadow(
                  color: color.withAlpha(40),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
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
            child: Text(
              _zoneEmoji(level),
              style: const TextStyle(fontSize: 18),
            ),
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
                        style: AppFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: titleFontWeight,
                          fontStyle: titleFontStyle,
                          color: color,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: isHighAlert
                              ? Border.all(color: color.withAlpha(60))
                              : null,
                        ),
                        child: Text(
                          'Anda',
                          style: AppFonts.plusJakartaSans(
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
                  style: AppFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B6B78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppFonts.plusJakartaSans(
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
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms);
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
                style: AppFonts.plusJakartaSans(
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
            style: AppFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B6B78),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppFonts.plusJakartaSans(
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
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: index == 0 ? statusColor : statusColor.withAlpha(50),
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
                    color: const Color(0xFFE0E0E8)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF3A3A4A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _fakeTimestamp(index),
                  style: AppFonts.plusJakartaSans(
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
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month]}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} WIB';
  }

  String _zoneEmoji(int level) {
    switch (level) {
      case 4:
        return '🔴';
      case 3:
        return '🟠';
      case 2:
        return '🟡';
      default:
        return '🟢';
    }
  }

  String _formatTime(DateTime dt) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} WIB';
  }
}
