import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/fonts.dart';
import '../models/volcanic_daily_report.dart';

/// Widget section laporan harian MAGMA Indonesia.
///
/// Ditampilkan di halaman Pantauan CCTV (visual_merapi_screen.dart)
/// antara section "Informasi Terkini" dan "Riwayat Erupsi".
class VolcanicReportSection extends StatelessWidget {
  final List<VolcanicDailyReport> reports;
  final bool isLoading;

  const VolcanicReportSection({
    super.key,
    required this.reports,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ──
        Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Laporan Harian MAGMA',
                style: AppFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E2C),
                ),
              ),
            ),
            // Badge sumber data
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Text(
                'PVMBG',
                style: AppFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Sumber: magma.esdm.go.id',
          style: AppFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF9E9EAE),
          ),
        ),
        const SizedBox(height: 14),

        // ── Content ──
        if (isLoading)
          _buildLoadingState()
        else if (reports.isEmpty)
          _buildEmptyState()
        else
          ...reports.asMap().entries.map(
                (entry) => _VolcanicReportCard(
                  report: entry.value,
                  delay: entry.key * 80,
                ),
              ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Memuat laporan MAGMA...',
              style: AppFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF9E9EAE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFFF9800),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan belum tersedia',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Data laporan MAGMA akan muncul setelah sistem scraper berjalan.',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF9E9EAE),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ──────────────────────────────────────────────────────────────
// Card per laporan — dengan section Pengamatan Visual & Klimatologi
// ──────────────────────────────────────────────────────────────

class _VolcanicReportCard extends StatefulWidget {
  final VolcanicDailyReport report;
  final int delay;

  const _VolcanicReportCard({required this.report, required this.delay});

  @override
  State<_VolcanicReportCard> createState() => _VolcanicReportCardState();
}

class _VolcanicReportCardState extends State<_VolcanicReportCard> {
  bool _isExpanded = false;

  Color get _levelColor => Color(widget.report.style.colorHex);

  Color get _levelBgColor {
    final base = _levelColor;
    return Color.fromRGBO(base.red, base.green, base.blue, 0.08);
  }

  Color get _levelBorderColor {
    final base = _levelColor;
    return Color.fromRGBO(base.red, base.green, base.blue, 0.25);
  }

  Future<void> _openDetailUrl(BuildContext context) async {
    if (widget.report.detailUrl == null) return;
    final uri = Uri.tryParse(widget.report.detailUrl!);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka laporan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = widget.report.visualObservation;
    final climate = widget.report.climatology;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isExpanded ? _levelBorderColor : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? _levelColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: _isExpanded ? 14 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            splashColor: _levelColor.withValues(alpha: 0.06),
            highlightColor: _levelColor.withValues(alpha: 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header (Selalu Tampil) ──
                _buildHeader(),

                // ── Body Sections (Expandable) ──
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: _buildBody(visual, climate, context),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: 280.ms,
                  alignment: Alignment.topCenter,
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: widget.delay), duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _levelBgColor,
        border: Border(
          bottom: BorderSide(
            color: _isExpanded ? _levelBorderColor : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Level badge dot
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: _levelColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _levelColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.report.volcanoName,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _levelColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _levelColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.report.levelName,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.report.levelCode == 2
                              ? const Color(0xFFB45309)
                              : _levelColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(widget.report.reportDate),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF9E9EAE),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            _isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF9E9EAE),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      String visual, String? climate, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pengamatan Visual ──
        _buildSection(
          icon: Icons.remove_red_eye_rounded,
          iconColor: const Color(0xFF5C6BC0),
          bgColor: const Color(0xFFF3F4FF),
          title: 'Pengamatan Visual',
          content: visual.isNotEmpty ? visual : 'Tidak tersedia.',
          isItalic: visual.isEmpty,
        ),

        // ── Divider tipis ──
        if (climate != null && climate.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: const Color(0xFFF0F0F0),
          ),

        // ── Klimatologi ──
        if (climate != null && climate.isNotEmpty)
          _buildSection(
            icon: Icons.wb_cloudy_rounded,
            iconColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFF0F8FF),
            title: 'Klimatologi',
            content: climate,
          ),

        // ── Footer: Lihat Detail / Author ──
        _buildFooter(context),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String content,
    bool isItalic = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Content text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              content,
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF3D3D4E),
                height: 1.65,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final hasDetail = widget.report.detailUrl != null;
    final author = widget.report.author ?? 'PVMBG';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          // Author chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 12,
                  color: Color(0xFF9E9EAE),
                ),
                const SizedBox(width: 4),
                Text(
                  author,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B6B78),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Lihat Detail button
          if (hasDetail)
            GestureDetector(
              onTap: () => _openDetailUrl(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Lihat di MAGMA',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 11,
                      color: Color(0xFF1565C0),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
