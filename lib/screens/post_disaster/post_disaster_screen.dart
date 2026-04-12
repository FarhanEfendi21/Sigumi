import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../models/shelter_model.dart';
import '../../providers/volcano_provider.dart';
import '../../repositories/shelter_repository.dart';
import '../../services/location_service.dart';

// ══════════════════════════════════════════════════════════════════
// HALAMAN LOKASI POSKO & FASILITAS KESEHATAN
// Data dari Supabase RPC get_nearby_shelters (PostGIS)
// Dengan pagination client-side, 10 item per halaman
// ══════════════════════════════════════════════════════════════════

class PostDisasterScreen extends StatefulWidget {
  const PostDisasterScreen({super.key});

  @override
  State<PostDisasterScreen> createState() => _PostDisasterScreenState();
}

class _PostDisasterScreenState extends State<PostDisasterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ShelterRepository _repo = ShelterRepository();

  List<ShelterModel> _allShelters = [];
  bool _isLoading = true;
  String? _error;
  String _lastLoadedRegion = '';

  // ── Pagination ──
  static const int _pageSize = 10;
  final List<int> _currentPages = [0, 0, 0]; // per tab: [semua, posko, faskes]

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShelters());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── DATA LOADING ──────────────────────────────────────────────
  Future<void> _loadShelters({bool forceReload = false}) async {
    final provider = context.read<VolcanoProvider>();
    final loc = context.read<LocationService>();
    final region = provider.selectedRegion;

    if (!forceReload &&
        region == _lastLoadedRegion &&
        _allShelters.isNotEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Gunakan dbId dari model — sudah otomatis mapping mock ID → UUID Supabase
      final volcanoId = provider.volcano.dbId;

      final shelters = await _repo.getNearbyShelters(
        lat: loc.userLat,
        lng: loc.userLng,
        volcanoId: volcanoId, // null jika tidak dikenal → ambil semua
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _allShelters = shelters;
          _isLoading = false;
          _lastLoadedRegion = region;
          _currentPages[0] = 0;
          _currentPages[1] = 0;
          _currentPages[2] = 0;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data. Periksa koneksi internet.';
          _isLoading = false;
        });
      }
    }
  }

  List<ShelterModel> get _poskoList =>
      _allShelters.where((s) => s.isShelter).toList();

  List<ShelterModel> get _faskesList =>
      _allShelters.where((s) => s.isHealthFacility).toList();

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        if (_lastLoadedRegion.isNotEmpty &&
            provider.selectedRegion != _lastLoadedRegion) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _loadShelters(forceReload: true));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Posko & Layanan Kesehatan',
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF1E1E2C),
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E1E2C)),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  labelColor: SigumiTheme.primaryBlue,
                  unselectedLabelColor: const Color(0xFF6B6B78),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(width: 3, color: SigumiTheme.primaryBlue),
                    borderRadius: BorderRadius.circular(2),
                    insets: const EdgeInsets.symmetric(horizontal: -8),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    _tabItem('Semua', _allShelters.length),
                    _tabItem('Posko', _poskoList.length),
                    _tabItem('Faskes', _faskesList.length),
                  ],
                ),
              ),
            ),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Tab _tabItem(String label, int count) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0 && !_isLoading) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SigumiTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: SigumiTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  // ── BODY ──────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPaginatedList(_allShelters, 0),
        _buildPaginatedList(_poskoList, 1),
        _buildPaginatedList(_faskesList, 2),
      ],
    );
  }

  Widget _buildPaginatedList(List<ShelterModel> items, int tabIdx) {
    if (items.isEmpty) return _buildEmpty();

    final totalPages = (items.length / _pageSize).ceil();
    final page = _currentPages[tabIdx].clamp(0, totalPages - 1);
    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    final pageItems = items.sublist(start, end);

    return RefreshIndicator(
      color: SigumiTheme.primaryBlue,
      onRefresh: () => _loadShelters(forceReload: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Info bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.sort_rounded,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Menampilkan ${start + 1}–$end dari ${items.length}',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _loadShelters(forceReload: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: SigumiTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 13, color: SigumiTheme.primaryBlue),
                          const SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SigumiTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Card list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => ShelterCard(shelter: pageItems[i], index: i),
                childCount: pageItems.length,
              ),
            ),
          ),

          // Pagination bar (hanya tampil jika > 1 halaman)
          if (totalPages > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: PaginationBar(
                  currentPage: page,
                  totalPages: totalPages,
                  onPageChanged: (p) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentPages[tabIdx] = p);
                  },
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // ── STATES ────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1200.ms,
            delay: Duration(milliseconds: 120 * i),
            color: Colors.white.withValues(alpha: 0.6),
          ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text('Koneksi Bermasalah',
                style: AppFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _loadShelters(forceReload: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: SigumiTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SigumiTheme.primaryBlue.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.home_work_outlined,
                size: 48,
                color: SigumiTheme.primaryBlue.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text('Belum Ada Data',
              style: AppFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Text('Tidak ada posko atau fasilitas\nuntuk kategori ini.',
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  height: 1.5)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PAGINATION BAR
// ══════════════════════════════════════════════════════════════════

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentPage > 0;
    final hasNext = currentPage < totalPages - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageNavBtn(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 8),
          ...List.generate(totalPages, (i) {
            final active = i == currentPage;
            return GestureDetector(
              onTap: () => onPageChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: active ? 32 : 28,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color:
                      active ? SigumiTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active
                        ? SigumiTheme.primaryBlue
                        : Colors.grey.shade300,
                    width: active ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          _PageNavBtn(
            icon: Icons.chevron_right_rounded,
            enabled: hasNext,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PageNavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageNavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? SigumiTheme.primaryBlue.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20,
            color:
                enabled ? SigumiTheme.primaryBlue : Colors.grey.shade300),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SHELTER CARD
// ══════════════════════════════════════════════════════════════════

class ShelterCard extends StatelessWidget {
  final ShelterModel shelter;
  final int index;

  const ShelterCard({super.key, required this.shelter, required this.index});

  @override
  Widget build(BuildContext context) {
    final st = _ShelterStyle.of(shelter.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetail(context, st),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: st.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(st.icon, color: st.color, size: 26),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _Badge(label: shelter.typeLabel, color: st.color),
                          if (shelter.is24h) ...[
                            const SizedBox(width: 6),
                            _Badge(
                              label: '24 Jam',
                              color: Colors.green.shade600,
                              icon: Icons.access_time_rounded,
                            ),
                          ],
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          shelter.name,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                            height: 1.25,
                          ),
                        ),
                        if (shelter.address != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            shelter.address!,
                            style: AppFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.near_me_outlined,
                              size: 13, color: st.color),
                          const SizedBox(width: 4),
                          Text(
                            shelter.distanceLabel,
                            style: AppFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: st.color,
                            ),
                          ),
                          if (shelter.capacity != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.people_outline_rounded,
                                size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text(
                              '${shelter.capacity} org',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (shelter.hasMedical)
                            _FacilityDot(
                                icon: Icons.medical_services_outlined,
                                color: Colors.red.shade400),
                          if (shelter.hasKitchen)
                            _FacilityDot(
                                icon: Icons.restaurant_rounded,
                                color: Colors.orange.shade400),
                        ]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 20, color: Colors.grey.shade300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 40 * index), duration: 380.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }

  void _showDetail(BuildContext context, _ShelterStyle st) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(shelter: shelter, style: st),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DETAIL BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════

class _DetailSheet extends StatelessWidget {
  final ShelterModel shelter;
  final _ShelterStyle style;

  const _DetailSheet({required this.shelter, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(style.icon, color: style.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Badge(label: shelter.typeLabel, color: style.color),
                    const SizedBox(height: 4),
                    Text(
                      shelter.name,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 4),

          // Detail rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              if (shelter.address != null)
                _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Alamat',
                    value: shelter.address!,
                    color: style.color),
              if (shelter.distanceFromUser != null)
                _DetailRow(
                    icon: Icons.near_me_rounded,
                    label: 'Jarak dari Anda',
                    value: shelter.distanceLabel,
                    color: style.color,
                    highlighted: true),
              if (shelter.capacity != null)
                _DetailRow(
                    icon: Icons.people_rounded,
                    label: 'Kapasitas',
                    value: '${shelter.capacity} orang',
                    color: style.color),
              if (shelter.notes != null)
                _DetailRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Catatan',
                    value: shelter.notes!,
                    color: style.color),
            ]),
          ),

          // Fasilitas chips
          if (shelter.hasMedical ||
              shelter.hasKitchen ||
              shelter.hasToilet ||
              shelter.is24h)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FASILITAS',
                      style: AppFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (shelter.hasMedical)
                      _FacilityChip(
                          label: 'Tenaga Medis',
                          icon: Icons.medical_services_outlined,
                          color: Colors.red.shade500),
                    if (shelter.hasKitchen)
                      _FacilityChip(
                          label: 'Dapur Umum',
                          icon: Icons.restaurant_rounded,
                          color: Colors.orange.shade600),
                    if (shelter.hasToilet)
                      _FacilityChip(
                          label: 'MCK',
                          icon: Icons.wc_rounded,
                          color: Colors.blue.shade500),
                    if (shelter.is24h)
                      _FacilityChip(
                          label: 'Buka 24 Jam',
                          icon: Icons.access_time_rounded,
                          color: Colors.green.shade600),
                  ]),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Row(children: [
              if (shelter.phone != null) ...[
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.call_rounded,
                    label: 'Hubungi',
                    color: Colors.green.shade600,
                    onTap: () async {
                      final uri = Uri.parse('tel:${shelter.phone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _ActionBtn(
                  icon: Icons.map_rounded,
                  label: 'Buka Maps',
                  color: SigumiTheme.primaryBlue,
                  onTap: () async {
                    final query = Uri.encodeComponent(shelter.name);
                    final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$query');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ]),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
        ],
        Text(label,
            style: AppFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2)),
      ]),
    );
  }
}

class _FacilityDot extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _FacilityDot({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _FacilityChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: AppFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool highlighted;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: AppFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.6)),
              const SizedBox(height: 2),
              Text(value,
                  style: AppFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: highlighted
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: highlighted
                          ? color
                          : const Color(0xFF1A1A2E),
                      height: 1.4)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 7),
              Text(label,
                  style: AppFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// STYLE HELPER
// ══════════════════════════════════════════════════════════════════

class _ShelterStyle {
  final Color color;
  final IconData icon;
  const _ShelterStyle({required this.color, required this.icon});

  static _ShelterStyle of(String type) {
    switch (type) {
      case 'posko_evakuasi':
        return const _ShelterStyle(
            color: Color(0xFF0F52BA), icon: Icons.home_work_rounded);
      case 'rumah_sakit':
        return _ShelterStyle(
            color: Colors.red.shade600, icon: Icons.local_hospital_rounded);
      case 'puskesmas':
        return _ShelterStyle(
            color: Colors.teal.shade600,
            icon: Icons.medical_services_rounded);
      case 'klinik':
        return _ShelterStyle(
            color: Colors.cyan.shade700,
            icon: Icons.health_and_safety_rounded);
      case 'balai_desa':
        return _ShelterStyle(
            color: Colors.amber.shade700,
            icon: Icons.account_balance_rounded);
      case 'gor':
        return _ShelterStyle(
            color: Colors.purple.shade600, icon: Icons.stadium_rounded);
      default:
        return const _ShelterStyle(
            color: Color(0xFF1B2E7B), icon: Icons.place_rounded);
    }
  }
}

