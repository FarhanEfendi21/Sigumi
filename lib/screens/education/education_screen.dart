import 'package:flutter/cupertino.dart';
import '../../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sigumi/config/fonts.dart';
import '../../config/theme.dart';
import '../../config/theme_extensions.dart';
import '../../models/education_model.dart';
import '../../providers/volcano_provider.dart';
import '../../repositories/education_repository.dart';
import 'education_detail_from_db_screen.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
            title: Text(
            context.trText('Edukasi Bencana'),
            style: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: context.textPrimary,
            ),
          ),
          backgroundColor: context.bgSurface,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: context.textPrimary),
          bottom: TabBar(
            indicatorColor: context.accentPrimary,
            labelColor: context.textPrimary,
            unselectedLabelColor: context.textSecondary,
            indicatorWeight: 3,
            labelStyle: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: context.trText('Umum')),
              Tab(text: context.tr('kids_education')),
              Tab(text: context.tr('inclusive_education')),
            ],
          ),
        ),
        backgroundColor: isHC ? context.bgPrimary : Colors.grey.shade50,
        body: Consumer<VolcanoProvider>(
          builder: (context, volcano, _) {
            return TabBarView(
              children: [
                _GeneralEducationGrid(
                  selectedRegion: volcano.selectedRegion,
                ),
                _ChildrenEducationGrid(
                  selectedRegion: volcano.selectedRegion,
                ),
                _DisabilityEducationGrid(
                  selectedRegion: volcano.selectedRegion,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GeneralEducationGrid extends StatefulWidget {
  final String selectedRegion;

  const _GeneralEducationGrid({required this.selectedRegion});

  @override
  State<_GeneralEducationGrid> createState() => _GeneralEducationGridState();
}

class _GeneralEducationGridState extends State<_GeneralEducationGrid> {
  final _repo = EducationRepository();
  List<EducationItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEducations();
  }

  @override
  void didUpdateWidget(_GeneralEducationGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRegion != widget.selectedRegion) {
      _loadEducations();
    }
  }

  Future<void> _loadEducations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchGeneralEducations(
        lokasi: widget.selectedRegion,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = context.trTextSafe('Gagal memuat data edukasi.');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _AnimatedHeader(
              title: context.tr('general_education_guide'),
              subtitle:
                  'Menampilkan panduan kesiapsiagaan bencana untuk wilayah ${widget.selectedRegion}.',
              icon: Icons.menu_book,
            ),
          ),
        ),

        // ── Loading / Error / Content ────────────────────────────────
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadEducations,
                    child: Text(context.tr('try_again')),
                  ),
                ],
              ),
            ),
          )
        else if (_items.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada konten edukasi\nuntuk wilayah ${widget.selectedRegion}.',
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 240,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _EducationItemCard(
                  item: _items[index],
                  index: index,
                ),
                childCount: _items.length,
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

// ── Kartu item dari database ──────────────────────────────────────────────────

class _EducationItemCard extends StatelessWidget {
  final EducationItem item;
  final int index;

  const _EducationItemCard({required this.item, required this.index});

  static const List<Color> _fallbackColors = [
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFC62828),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = _fallbackColors[index % _fallbackColors.length];
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor, width: context.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EducationDetailFromDbScreen(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gambar / Gradient fallback ───────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                ),
                child: hasImage
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.article,
                              size: 40, color: accentColor),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.article,
                            size: 40, color: accentColor),
                      ),
              ),
            ),

            // ── Info ─────────────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chip kategori
                    if (item.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category!.toUpperCase(),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Judul
                    Text(
                      item.title,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: context.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Ringkasan konten
                    Text(
                      item.content,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 80 * index),
          duration: 400.ms,
        )
        .scale(
          delay: Duration(milliseconds: 80 * index),
          duration: 400.ms,
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

class _ChildrenEducationGrid extends StatefulWidget {
  final String selectedRegion;

  const _ChildrenEducationGrid({required this.selectedRegion});

  @override
  State<_ChildrenEducationGrid> createState() => _ChildrenEducationGridState();
}

class _ChildrenEducationGridState extends State<_ChildrenEducationGrid> {
  final _repo = EducationRepository();
  List<EducationItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEducations();
  }

  @override
  void didUpdateWidget(_ChildrenEducationGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRegion != widget.selectedRegion) {
      _loadEducations();
    }
  }

  Future<void> _loadEducations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchChildrenEducations(
        lokasi: widget.selectedRegion,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = context.trTextSafe('Gagal memuat data edukasi anak-anak.');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _AnimatedHeader(
              title: context.tr('kids_education'),
              subtitle:
                  'Panduan kesiapsiagaan bencana anak-anak untuk wilayah ${widget.selectedRegion}.',
              icon: Icons.child_care,
            ),
          ),
        ),

        // ── Loading / Error / Content ────────────────────────────────
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadEducations,
                    child: Text(context.tr('try_again')),
                  ),
                ],
              ),
            ),
          )
        else if (_items.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.child_care,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada konten edukasi anak-anak\nuntuk wilayah ${widget.selectedRegion}.',
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 240,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _EducationItemCard(
                  item: _items[index],
                  index: index,
                ),
                childCount: _items.length,
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

class _DisabilityEducationGrid extends StatefulWidget {
  final String selectedRegion;

  const _DisabilityEducationGrid({required this.selectedRegion});

  @override
  State<_DisabilityEducationGrid> createState() =>
      _DisabilityEducationGridState();
}

class _DisabilityEducationGridState extends State<_DisabilityEducationGrid> {
  final _repo = EducationRepository();
  List<EducationItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEducations();
  }

  @override
  void didUpdateWidget(_DisabilityEducationGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRegion != widget.selectedRegion) {
      _loadEducations();
    }
  }

  Future<void> _loadEducations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchDisabilityEducations(
        lokasi: widget.selectedRegion,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = context.trTextSafe('Gagal memuat data edukasi difabel.');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _AnimatedHeader(
              title: context.tr('accessibility_inclusion'),
              subtitle:
                  'Panduan khusus difabel dan lansia untuk wilayah ${widget.selectedRegion}.',
              icon: Icons.accessibility_new,
            ),
          ),
        ),

        // ── Kartu fitur aksesibilitas ────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Consumer<VolcanoProvider>(
              builder: (context, provider, _) {
                final isHC = provider.highContrast;
                final accentColor =
                    isHC ? SigumiTheme.hcSecondary : SigumiTheme.primaryBlue;
                final surfaceColor =
                    isHC ? SigumiTheme.hcSurface : Colors.white;
                final borderColor =
                    isHC ? SigumiTheme.hcBorder : const Color(0xFFE5E7EB);
                final primaryText =
                    isHC ? SigumiTheme.hcPrimary : const Color(0xFF1E1E2C);
                final tertiaryText =
                    isHC ? SigumiTheme.hcDivider : const Color(0xFF6B6B78);
                final borderW = isHC ? 2.0 : 1.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Label seksi ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded,
                              size: 14, color: tertiaryText),
                          const SizedBox(width: 6),
                          Text(
                            'FITUR AKSESIBILITAS',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: tertiaryText,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Kartu Kontras Tinggi ─────────────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: borderW),
                        boxShadow: isHC
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.contrast_rounded,
                                color: accentColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Kontras Tinggi',
                                        style: AppFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: primaryText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          showCupertinoDialog(
                                            context: context,
                                            builder: (ctx) =>
                                                CupertinoAlertDialog(
                                              title: const Text(
                                                'Kontras Tinggi',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              content: const Padding(
                                                padding:
                                                    EdgeInsets.only(top: 8),
                                                child: Text(
                                                  'Mengubah warna antarmuka ke skema hitam/putih dengan kontras WCAG AAA agar teks dan elemen lebih mudah dibaca oleh pengguna dengan gangguan penglihatan.',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 13,
                                                    height: 1.6,
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                CupertinoDialogAction(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text(
                                                    'Mengerti',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Plus Jakarta Sans',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            CupertinoIcons.info_circle,
                                            size: 15,
                                            color: tertiaryText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isHC
                                      ? 'Aktif — hitam/putih WCAG AAA'
                                      : 'Optimalkan keterbacaan warna',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: tertiaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: provider.highContrast,
                            onChanged: (v) {
                              HapticFeedback.mediumImpact();
                              provider.setHighContrast(v);
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    // ── Kartu Panduan Audio ──────────────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: borderW),
                        boxShadow: isHC
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              CupertinoIcons.mic_fill,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Panduan Audio',
                                        style: AppFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: primaryText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          showCupertinoDialog(
                                            context: context,
                                            builder: (ctx) =>
                                                CupertinoAlertDialog(
                                              title: const Text(
                                                'Panduan Audio',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              content: const Padding(
                                                padding:
                                                    EdgeInsets.only(top: 8),
                                                child: Text(
                                                  'Aktifkan panduan suara interaktif dengan mengucapkan "Halo Sigumi". Fitur ini membantu pengguna tunanetra atau low-vision menavigasi aplikasi dan menerima peringatan bencana secara verbal.',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 13,
                                                    height: 1.6,
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                CupertinoDialogAction(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text(
                                                    'Mengerti',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Plus Jakarta Sans',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            CupertinoIcons.info_circle,
                                            size: 15,
                                            color: tertiaryText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  provider.audioGuidance
                                      ? 'Aktif — Ucapkan "Halo Sigumi"'
                                      : 'Nonaktif',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: tertiaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: provider.audioGuidance,
                            activeTrackColor: accentColor,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              provider.setAudioGuidance(val);
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
                  ],
                );
              },
            ),
          ),
        ),

        // ── Loading / Error / Content ────────────────────────────────
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadEducations,
                    child: Text(context.tr('try_again')),
                  ),
                ],
              ),
            ),
          )
        else if (_items.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.accessibility_new,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada konten edukasi difabel\nuntuk wilayah ${widget.selectedRegion}.',
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 240,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _EducationItemCard(
                  item: _items[index],
                  index: index,
                ),
                childCount: _items.length,
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

// =============================================================================
// REUSABLE UI COMPONENTS
// =============================================================================

class _AnimatedHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AnimatedHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: context.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.accentPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.accentPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.5,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
