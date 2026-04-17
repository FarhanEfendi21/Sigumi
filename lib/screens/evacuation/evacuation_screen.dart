import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../config/fonts.dart';
import '../../models/shelter_model.dart';
import '../../providers/volcano_provider.dart';
import '../../repositories/shelter_repository.dart';
import '../../services/location_service.dart';
import '../map/widgets/blur_top_bar.dart';
import '../map/widgets/map_controls.dart';

// ══════════════════════════════════════════════════════════════════
// HALAMAN TITIK AMAN EVAKUASI (MAP CENTRIC)
// Menampilkan titik evakuasi terdekat (Posko + Faskes) pada peta
// dan dalam bentuk Draggable Bottom Sheet.
// ══════════════════════════════════════════════════════════════════

class EvacuationScreen extends StatefulWidget {
  const EvacuationScreen({super.key});

  @override
  State<EvacuationScreen> createState() => _EvacuationScreenState();
}

class _EvacuationScreenState extends State<EvacuationScreen>
    with SingleTickerProviderStateMixin {
  final ShelterRepository _repo = ShelterRepository();
  late final MapController _mapController;
  late final AnimationController _glowController;

  List<ShelterModel> _shelters = [];
  bool _isLoading = true;
  String? _error;
  String _lastLoadedRegion = '';
  LatLngBounds? _currentBounds;

  // Pagination untuk list view
  static const int _pageSize = 5;
  int _currentPage = 0;

  // Filter: null = semua, 'posko' = posko, 'faskes' = faskes
  String? _activeFilter;

  // Fullscreen mode untuk peta
  bool _isMapFocused = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final locationService = context.read<LocationService>();
    await locationService.refreshLocation();
    await _loadShelters();
    _recenterMap();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ── DATA LOADING ──────────────────────────────────────────────
  Future<void> _loadShelters({bool forceReload = false}) async {
    if (!mounted) return;

    final provider = context.read<VolcanoProvider>();
    final loc = context.read<LocationService>();
    final region = provider.selectedRegion;

    if (!forceReload && _lastLoadedRegion.isNotEmpty && region == _lastLoadedRegion && _shelters.isNotEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final volcanoId = provider.volcano.dbId;

      final shelters = await _repo.getNearbyShelters(
        lat: loc.userLat,
        lng: loc.userLng,
        volcanoId: volcanoId,
        limit: 200, // Load area yang lebih luas untuk di-filter secara real-time via map
      );

      if (mounted) {
        setState(() {
          _shelters = shelters;
          _isLoading = false;
          _currentPage = 0;
          _lastLoadedRegion = region;
        });

        if (forceReload) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
               _recenterMap();
           });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data. Periksa koneksi internet Anda.';
          _isLoading = false;
        });
      }
    }
  }

  // ── FILTERED + PAGED LIST ─────────────────────────────────────
  List<ShelterModel> get _filteredList {
    var items = _shelters;

    if (_activeFilter == 'posko') {
      items = items.where((s) => s.isShelter).toList();
    } else if (_activeFilter == 'faskes') {
      items = items.where((s) => s.isHealthFacility).toList();
    }

    if (_currentBounds != null) {
      // Hanya tampilkan yang masuk ke dalam area map (Real-time tracking)
      final visible = items.where((s) => 
         _currentBounds!.contains(LatLng(s.latitude, s.longitude))
      ).toList();
      return visible;
    }

    return items;
  }

  int get _totalPages => max(1, (_filteredList.length / _pageSize).ceil());

  List<ShelterModel> get _pagedList {
    final items = _filteredList;
    if (items.isEmpty) return [];
    final page = _currentPage.clamp(0, _totalPages - 1);
    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  // ── MAP CONTROLS ──────────────────────────────────────────────
  void _recenterMap() {
    final loc = context.read<LocationService>();
    final pos = LatLng(loc.userLat, loc.userLng);
    _mapController.move(pos, 13.5);
    setState(() {
      _currentBounds = _mapController.camera.visibleBounds;
      _currentPage = 0;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<VolcanoProvider, LocationService>(
      builder: (context, volcanoProvider, locService, _) {
        final region = volcanoProvider.selectedRegion;
        if (_lastLoadedRegion.isNotEmpty && region != _lastLoadedRegion) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _loadShelters(forceReload: true));
        }

        final userPos = LatLng(locService.userLat, locService.userLng);

        return Scaffold(
          backgroundColor: Colors.white,
          // Agar peta terlihat sampai belakang status/app bar
          extendBodyBehindAppBar: true, 
          body: Stack(
            children: [
              // ── LAYER 1: PETA ──
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userPos,
                  initialZoom: 13.5,
                  minZoom: 8,
                  maxZoom: 18,
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd) {
                      if (mounted) {
                        setState(() {
                          _currentBounds = _mapController.camera.visibleBounds;
                          _currentPage = 0;
                        });
                      }
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sigumi.app',
                    maxZoom: 19,
                  ),

                  // User Radius Circle (Hanya pemanis)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: userPos,
                        radius: 500, // 500m dari user
                        useRadiusInMeter: true,
                        color: SigumiTheme.primaryBlue.withAlpha(20),
                        borderColor: SigumiTheme.primaryBlue.withAlpha(50),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),

                  // Marker Layer: User & Shelters
                  MarkerLayer(
                    markers: [
                      // User Marker
                      Marker(
                        point: userPos,
                        width: 48,
                        height: 48,
                        child: _buildUserMarker(locService),
                      ),
                      
                      // Shelters Markers
                      ..._filteredList.map((shelter) => Marker(
                            point: LatLng(shelter.latitude, shelter.longitude),
                            width: 100, // Diperlebar untuk memuat teks
                            height: 60, // Dipertinggi untuk ikon dan teks
                            alignment: Alignment.topCenter,
                            child: _buildShelterMarker(shelter),
                          )),
                    ],
                  ),
                ],
              ),

              // ── LAYER 2: BLUR TOP BAR ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BlurTopBar(
                  title: 'Titik Evakuasi',
                  isMapFocused: _isMapFocused,
                  onToggleFocus: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isMapFocused = !_isMapFocused);
                  },
                  onBack: () => Navigator.pop(context),
                ),
              ),

              // ── LAYER 3: FLOATING CONTROLS ──
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _isMapFocused ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShadcnMapButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Lokasi Saya',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          locService.refreshLocation();
                          _recenterMap();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── LAYER 4: DRAGGABLE SHEET ──
              IgnorePointer(
                ignoring: _isMapFocused,
                child: AnimatedOpacity(
                  opacity: _isMapFocused ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.35,
                    minChildSize: 0.2, 
                    maxChildSize: 0.85,
                    snap: true,
                    snapSizes: const [0.2, 0.35, 0.85],
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            // HANDLE & HEADER (NON-PINNED to avoid crash)
                            SliverToBoxAdapter(
                              child: Container(
                                color: Colors.white,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Grab handle
                                    Center(
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            top: 12, bottom: 12),
                                        width: 40,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                    // Judul & Filter
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Lokasi Terdekat',
                                            style: AppFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Filter Chips (Scrollable horizontal)
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                _FilterChip(
                                                  label: 'Semua',
                                                  count: _shelters.length,
                                                  isActive:
                                                      _activeFilter == null,
                                                  onTap: () {
                                                    setState(() {
                                                      _activeFilter = null;
                                                      _currentPage = 0;
                                                    });
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                _FilterChip(
                                                  label: 'Posko',
                                                  count: _shelters
                                                      .where((s) =>
                                                          s.isShelter)
                                                      .length,
                                                  isActive: _activeFilter ==
                                                      'posko',
                                                  onTap: () {
                                                    setState(() {
                                                      _activeFilter = 'posko';
                                                      _currentPage = 0;
                                                    });
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                _FilterChip(
                                                  label: 'Faskes',
                                                  count: _shelters
                                                      .where((s) => s
                                                          .isHealthFacility)
                                                      .length,
                                                  isActive: _activeFilter ==
                                                      'faskes',
                                                  onTap: () {
                                                    setState(() {
                                                      _activeFilter =
                                                          'faskes';
                                                      _currentPage = 0;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                        height: 1, color: Colors.grey.shade100),
                                  ],
                                ),
                              ),
                            ),

                            // STATE: LOADING
                            if (_isLoading) ...[
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, i) => _ShimmerCard(index: i),
                                    childCount: 5,
                                  ),
                                ),
                              ),
                              const SliverToBoxAdapter(child: SizedBox(height: 24)),
                            ]

                            // STATE: ERROR
                            else if (_error != null)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _ErrorState(
                                  message: _error!,
                                  onRetry: () => _loadShelters(forceReload: true),
                                ),
                              )

                            // STATE: EMPTY
                            else if (_filteredList.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyState(
                                  filter: _activeFilter,
                                  onReset: () {
                                    setState(() {
                                      _activeFilter = null;
                                      _currentPage = 0;
                                    });
                                  },
                                ),
                              )

                            // STATE: DATA MUNCUL
                            else ...[
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final shelter = _pagedList[index];
                                      return _EvacuationCard(
                                        shelter: shelter,
                                        index: index,
                                        onTap: () => _focusOnShelter(shelter),
                                      );
                                    },
                                    childCount: _pagedList.length,
                                  ),
                                ),
                              ),

                              // PAGINATION
                              if (_totalPages > 1)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                    child: _PaginationControls(
                                      currentPage: _currentPage,
                                      totalPages: _totalPages,
                                      totalItems: _filteredList.length,
                                      pageSize: _pageSize,
                                      onPrev: () {
                                        if (_currentPage > 0) {
                                          HapticFeedback.selectionClick();
                                          setState(() => _currentPage--);
                                        }
                                      },
                                      onNext: () {
                                        if (_currentPage < _totalPages - 1) {
                                          HapticFeedback.selectionClick();
                                          setState(() => _currentPage++);
                                        }
                                      },
                                    ),
                                  ).animate().fadeIn(),
                                ),
                              const SliverToBoxAdapter(child: SizedBox(height: 24)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── MARKERS ───────────────────────────────────────────────────

  Widget _buildUserMarker(LocationService locationService) {
    final isActive = locationService.gpsStatus == GpsStatus.active;
    const color = Color(0xFF2563EB); // Biru GPS

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isActive)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(50),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.2, 1.2),
                duration: 2000.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(begin: 0.8, duration: 2000.ms),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShelterMarker(ShelterModel shelter) {
    final style = _ShelterStyle.of(shelter.type);
    
    return GestureDetector(
      onTap: () => _focusOnShelter(shelter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon Floating
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(style.icon, color: Colors.white, size: 18),
          ).animate().slideY(begin: -0.2, duration: 400.ms).fadeIn(),
          
          // Tooltip/Label yang disetujui User
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black.withAlpha(10), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Text(
              shelter.name,
              style: AppFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E2C),
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── DETAIL ACTION ─────────────────────────────────────────────

  void _focusOnShelter(ShelterModel shelter) {
    // 1. Move camera ke posisi marker (agak diturunkan sedikit y-axisnya supaya pas di tengah screen saat bottom sheet muncul)
    final pos = LatLng(shelter.latitude, shelter.longitude);
    _mapController.move(pos, 15);
    
    // 2. Munculkan detail
    _showDetail(context, shelter);
  }

  void _showDetail(BuildContext context, ShelterModel shelter) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(shelter: shelter),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// FILTER CHIP
// ══════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1E1E2C)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF1E1E2C)
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withAlpha(50)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: AppFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CARD EVAKUASI (UNTUK LIST)
// ══════════════════════════════════════════════════════════════════

class _EvacuationCard extends StatelessWidget {
  final ShelterModel shelter;
  final int index;
  final VoidCallback onTap;

  const _EvacuationCard({
    required this.shelter,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _ShelterStyle.of(shelter.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Content ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges Row
                        Row(
                          children: [
                            _TypeBadge(
                              label: shelter.typeLabel,
                              color: style.color,
                            ),
                            if (shelter.is24h) ...[
                              const SizedBox(width: 6),
                              _TypeBadge(
                                label: '24 Jam',
                                color: Colors.green.shade600,
                                icon: Icons.access_time_rounded,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Nama
                        Text(
                          shelter.name,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                            height: 1.25,
                          ),
                        ),
                        if (shelter.address != null) ...[
                          const SizedBox(height: 4),
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
                        // Jarak + Kapasitas
                        Row(
                          children: [
                            Icon(Icons.near_me_outlined,
                                size: 14, color: style.color),
                            const SizedBox(width: 4),
                            Text(
                              shelter.distanceLabel,
                              style: AppFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: style.color,
                              ),
                            ),
                            if (shelter.capacity != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.people_outline_rounded,
                                  size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                '${shelter.capacity} org',
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Mini facility icons
                            if (shelter.hasMedical)
                              _MiniIcon(
                                icon: Icons.medical_services_outlined,
                                color: Colors.red.shade400,
                              ),
                            if (shelter.hasKitchen)
                              _MiniIcon(
                                icon: Icons.restaurant_rounded,
                                color: Colors.orange.shade400,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Action (Buka di peta) ──
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        size: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(key: ValueKey('${shelter.id}_$index'))
        .fadeIn(
          // Gunakan 5 (literal) karena di dalam scope ini _pageSize tidak diinherit
          delay: Duration(milliseconds: 40 * (index % 5)),
          duration: 380.ms,
        )
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

// ══════════════════════════════════════════════════════════════════
// PAGINATION CONTROLS
// ══════════════════════════════════════════════════════════════════

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final start = currentPage * pageSize + 1;
    final end = ((currentPage + 1) * pageSize).clamp(0, totalItems);
    final hasPrev = currentPage > 0;
    final hasNext = currentPage < totalPages - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            label: 'Seb',
            enabled: hasPrev,
            onTap: onPrev,
          ),
          Text(
            '$start–$end dari $totalItems',
            style: AppFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            label: 'Sel',
            isIconRight: true,
            enabled: hasNext,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool isIconRight;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isIconRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF1A1A1A) : Colors.grey.shade300;
    return Material(
      color: enabled ? Colors.grey.shade200 : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isIconRight) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (isIconRight) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DETAIL BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════

class _DetailSheet extends StatelessWidget {
  final ShelterModel shelter;
  const _DetailSheet({required this.shelter});

  @override
  Widget build(BuildContext context) {
    final style = _ShelterStyle.of(shelter.type);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: style.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeBadge(label: shelter.typeLabel, color: style.color),
                      const SizedBox(height: 4),
                      Text(
                        shelter.name,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade100),

          // Detail Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              children: [
                if (shelter.address != null)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Alamat',
                    value: shelter.address!,
                    color: style.color,
                  ),
                if (shelter.distanceFromUser != null)
                  _DetailRow(
                    icon: Icons.near_me_rounded,
                    label: 'Jarak dari Anda',
                    value: shelter.distanceLabel,
                    color: style.color,
                    highlighted: true,
                  ),
                if (shelter.capacity != null)
                  _DetailRow(
                    icon: Icons.people_rounded,
                    label: 'Kapasitas',
                    value: '${shelter.capacity} orang',
                    color: style.color,
                  ),
                if (shelter.notes != null)
                  _DetailRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Catatan',
                    value: shelter.notes!,
                    color: style.color,
                  ),
              ],
            ),
          ),

          // Fasilitas
          if (shelter.hasMedical ||
              shelter.hasKitchen ||
              shelter.hasToilet ||
              shelter.is24h)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FASILITAS',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (shelter.hasMedical)
                        _FacilityChip(
                          label: 'Tenaga Medis',
                          icon: Icons.medical_services_outlined,
                          color: Colors.red.shade500,
                        ),
                      if (shelter.hasKitchen)
                        _FacilityChip(
                          label: 'Dapur Umum',
                          icon: Icons.restaurant_rounded,
                          color: Colors.orange.shade600,
                        ),
                      if (shelter.hasToilet)
                        _FacilityChip(
                          label: 'MCK',
                          icon: Icons.wc_rounded,
                          color: Colors.blue.shade500,
                        ),
                      if (shelter.is24h)
                        _FacilityChip(
                          label: 'Buka 24 Jam',
                          icon: Icons.access_time_rounded,
                          color: Colors.green.shade600,
                        ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Row(
              children: [
                if (shelter.phone != null) ...[
                  Expanded(
                    child: _ActionButton(
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
                  child: _ActionButton(
                    icon: Icons.directions_rounded,
                    label: 'Arahkan (Maps)',
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
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// REUSABLE SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _TypeBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MiniIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
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
  const _FacilityChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool highlighted;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color.withAlpha(150)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight:
                        highlighted ? FontWeight.w700 : FontWeight.w500,
                    color:
                        highlighted ? color : const Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// STATES: LOADING / EMPTY / ERROR
// ══════════════════════════════════════════════════════════════════

class _ShimmerCard extends StatelessWidget {
  final int index;
  const _ShimmerCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 14,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 12,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          delay: Duration(milliseconds: 120 * index),
          duration: 1000.ms,
          color: Colors.grey.shade300,
        );
  }
}

class _EmptyState extends StatelessWidget {
  final String? filter;
  final VoidCallback onReset;
  const _EmptyState({this.filter, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Data',
              style: AppFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter != null
                  ? 'Tidak ditemukan ${filter == 'posko' ? 'posko' : 'fasilitas kesehatan'} untuk area ini.'
                  : 'Tidak ditemukan titik evakuasi untuk area ini.',
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            if (filter != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: Text(
                  'Tampilkan Semua',
                  style:
                      AppFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: SigumiTheme.primaryBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Koneksi Bermasalah',
              style: AppFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: SigumiTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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
            color: Color(0xFFE53935), icon: Icons.local_hospital_rounded);
      case 'puskesmas':
        return _ShelterStyle(
            color: Color(0xFF00897B),
            icon: Icons.medical_services_rounded);
      case 'klinik':
        return _ShelterStyle(
            color: Color(0xFF00ACC1),
            icon: Icons.health_and_safety_rounded);
      case 'balai_desa':
        return _ShelterStyle(
            color: Color(0xFFF57C00),
            icon: Icons.account_balance_rounded);
      case 'gor':
        return _ShelterStyle(
            color: Color(0xFF8E24AA), icon: Icons.stadium_rounded);
      default:
        return const _ShelterStyle(
            color: Color(0xFF1B2E7B), icon: Icons.place_rounded);
    }
  }
}
