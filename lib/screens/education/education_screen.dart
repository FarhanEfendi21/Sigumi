import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sigumi/config/fonts.dart';
import '../../config/theme.dart';
import '../../models/education_model.dart';
import '../../providers/volcano_provider.dart';
import '../../repositories/education_repository.dart';
import 'education_detail_from_db_screen.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Edukasi Bencana',
            style: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: const Color(0xFF1E1E2C),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
          bottom: TabBar(
            indicatorColor: SigumiTheme.primaryBlue,
            labelColor: const Color(0xFF1E1E2C),
            unselectedLabelColor: const Color(0xFF1E1E2C).withValues(alpha: 0.5),
            indicatorWeight: 3,
            labelStyle: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Umum'),
              Tab(text: 'Anak-Anak'),
              Tab(text: 'Difabel'),
            ],
          ),
        ),
        backgroundColor: Colors.grey.shade50,
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
          _error = 'Gagal memuat data edukasi.';
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
              title: 'Panduan Edukasi Umum',
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
                    child: const Text('Coba Lagi'),
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
        side: BorderSide(color: Colors.grey.shade200),
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
                        color: Colors.black87,
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
                        color: SigumiTheme.textSecondary,
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
          _error = 'Gagal memuat data edukasi anak-anak.';
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
              title: 'Edukasi Anak-Anak 🧒',
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
                    child: const Text('Coba Lagi'),
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
          _error = 'Gagal memuat data edukasi difabel.';
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
              title: 'Aksesibilitas & Inklusi ♿',
              subtitle:
                  'Panduan khusus difabel dan lansia untuk wilayah ${widget.selectedRegion}.',
              icon: Icons.accessibility_new,
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
                    child: const Text('Coba Lagi'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                  color: SigumiTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SigumiTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
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
              color: SigumiTheme.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
