import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/eruption_history.dart';
import '../../models/volcano_model.dart';
import '../../providers/volcano_provider.dart';

/// Data kamera CCTV Merapi
class _CctvCamera {
  final String label;
  final String location;
  final String url;
  final IconData icon;

  const _CctvCamera({
    required this.label,
    required this.location,
    required this.url,
    required this.icon,
  });
}

const List<_CctvCamera> _merapiCameras = [
  _CctvCamera(
    label: 'Ngandong',
    location: 'Pos Ngandong',
    url: 'https://cctv.jogjaprov.go.id/pantauan-merapi-ngandong',
    icon: Icons.videocam_rounded,
  ),
  _CctvCamera(
    label: 'Klangon',
    location: 'View dari Klangon',
    url: 'https://cctv.jogjaprov.go.id/gunung-merapi-view-dari-klangon',
    icon: Icons.videocam_rounded,
  ),
  _CctvCamera(
    label: 'Museum',
    location: 'View dari Museum',
    url: 'https://cctv.jogjaprov.go.id/gunung-merapi-view-dari-museum',
    icon: Icons.videocam_rounded,
  ),
];

class VisualMerapiScreen extends StatefulWidget {
  final VolcanoModel? volcano;
  final String? volcanoId;

  const VisualMerapiScreen({super.key, this.volcano, this.volcanoId});

  @override
  State<VisualMerapiScreen> createState() => _VisualMerapiScreenState();
}

class _VisualMerapiScreenState extends State<VisualMerapiScreen> {
  int _selectedCameraIndex = 0;
  late WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _hasWebViewError = false;

  @override
  void initState() {
    super.initState();
    _initWebView(_merapiCameras[0].url);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolcanoProvider>().fetchEruptionHistory();
    });
  }

  void _initWebView(String url) {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFF8F9FA))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {
                if (mounted)
                  setState(() {
                    _isWebViewLoading = true;
                    _hasWebViewError = false;
                  });
              },
              onPageFinished: (_) {
                if (mounted) setState(() => _isWebViewLoading = false);
              },
              onWebResourceError: (_) {
                if (mounted)
                  setState(() {
                    _isWebViewLoading = false;
                    _hasWebViewError = true;
                  });
              },
            ),
          )
          ..loadRequest(Uri.parse(url));
  }

  void _switchCamera(int index) {
    if (_selectedCameraIndex == index) return;
    setState(() {
      _selectedCameraIndex = index;
      _isWebViewLoading = true;
      _hasWebViewError = false;
    });
    _webViewController.loadRequest(Uri.parse(_merapiCameras[index].url));
  }

  void _reloadCamera() {
    setState(() {
      _isWebViewLoading = true;
      _hasWebViewError = false;
    });
    _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        // Tentukan volcano: dari parameter atau dari provider
        late VolcanoModel volcano;
        if (widget.volcano != null) {
          volcano = widget.volcano!;
        } else {
          volcano = provider.volcano;
        }

        // Cek apakah ini Merapi (punya CCTV)
        final hasCctv = volcano.id == 'merapi_001';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              hasCctv ? 'Pantauan CCTV' : 'Detail ${volcano.name}',
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── CCTV Section (hanya untuk Merapi) ──
                if (hasCctv) ...[
                  // Camera Selector Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: List.generate(_merapiCameras.length, (i) {
                        final cam = _merapiCameras[i];
                        final isSelected = _selectedCameraIndex == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _switchCamera(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.07,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cam.icon,
                                    size: 18,
                                    color:
                                        isSelected
                                            ? Colors.redAccent
                                            : const Color(0xFF9E9EAE),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cam.label,
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? const Color(0xFF1E1E2C)
                                              : const Color(0xFF9E9EAE),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Live WebView Section ──
                  Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // ── WebView ──
                            Positioned.fill(
                              child:
                                  _hasWebViewError
                                      ? _buildErrorView()
                                      : WebViewWidget(
                                        controller: _webViewController,
                                      ),
                            ),

                            // ── Loading Overlay ──
                            if (_isWebViewLoading)
                              Positioned.fill(
                                child: Container(
                                  color: const Color(0xFFF8F9FA),
                                  child: Stack(
                                    children: [
                                      CustomPaint(
                                        size: const Size(double.infinity, 280),
                                        painter: _MountainPainter(),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Center(
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Center(
                                            child: Text(
                                              'Memuat siaran live...',
                                              style: AppFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF6B6B78),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Center(
                                            child: Text(
                                              _merapiCameras[_selectedCameraIndex]
                                                  .location,
                                              style: AppFonts.plusJakartaSans(
                                                fontSize: 11,
                                                color: const Color(0xFF9E9EAE),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // ── LIVE Badge ──
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                        .animate(
                                          onPlay:
                                              (c) => c.repeat(reverse: true),
                                        )
                                        .fade(
                                          duration: 800.ms,
                                          begin: 0.2,
                                          end: 1.0,
                                        ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'LIVE',
                                      style: AppFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── Reload Button ──
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _buildGlassButton(
                                Icons.refresh_rounded,
                                _reloadCamera,
                              ),
                            ),

                            // ── Location + Dots ──
                            Positioned(
                              bottom: 10,
                              left: 12,
                              right: 12,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.white,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _merapiCameras[_selectedCameraIndex]
                                              .location,
                                          style: AppFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      _merapiCameras.length,
                                      (i) => AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        margin: const EdgeInsets.only(left: 4),
                                        width:
                                            _selectedCameraIndex == i ? 18 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color:
                                              _selectedCameraIndex == i
                                                  ? Colors.white
                                                  : Colors.white.withValues(
                                                    alpha: 0.35,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 28),
                ] else ...[
                  // ── Info Gunung (untuk yang tidak ada CCTV) ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_rounded,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${volcano.name}',
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Belum memiliki sistem CCTV. Silakan lihat informasi detail di bawah.',
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 28),
                ],

                // ── Informasi Terkini ──
                Text(
                  'Informasi Terkini',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 14),

                GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.7,
                      children: [
                        _buildInfoGridCard(
                          icon: Icons.thermostat_rounded,
                          title: 'Suhu Kawah',
                          value: '${volcano.temperature ?? '-'}°C',
                          color: Colors.orange,
                        ),
                        _buildInfoGridCard(
                          icon: Icons.air_rounded,
                          title: 'Arah Angin',
                          value: volcano.windDirection ?? '-',
                          color: Colors.blue,
                        ),
                        _buildInfoGridCard(
                          icon: Icons.speed_rounded,
                          title: 'Kecepatan',
                          value: '${volcano.windSpeed ?? '-'} km/h',
                          color: Colors.teal,
                        ),
                        _buildInfoGridCard(
                          icon: Icons.height_rounded,
                          title: 'Elevasi',
                          value: '${volcano.elevation} mdpl',
                          color: Colors.indigo,
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: 32),

                // ── Riwayat Erupsi ──
                Text(
                  'Riwayat Erupsi',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 16),
                _buildEruptionHistoryContent(provider),

                const SizedBox(height: 32),

                // ── Galeri Visual ──
                Text(
                  'Galeri Visual',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 14),

                GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _GalleryItem(
                          'Puncak Kawah',
                          Icons.landscape_rounded,
                          Colors.brown,
                        ),
                        _GalleryItem(
                          'Kubah Lava',
                          Icons.local_fire_department_rounded,
                          Colors.redAccent,
                        ),
                        _GalleryItem(
                          'Guguran Vulkanik',
                          Icons.cloud_rounded,
                          Colors.grey.shade700,
                        ),
                        _GalleryItem(
                          'Aliran Lahar',
                          Icons.water_drop_rounded,
                          Colors.blueAccent,
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 280),
            painter: _MountainPainter(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat siaran',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Periksa koneksi internet kamu',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF9E9EAE),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _reloadCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF1E1E2C)),
        ),
      ),
    );
  }

  Widget _buildInfoGridCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B6B78),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1E2C),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEruptionHistoryContent(VolcanoProvider provider) {
    if (provider.isLoadingEruptions) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 10),
              Text(
                'Memuat riwayat erupsi...',
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

    if (!provider.hasEruptionHistory) {
      return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volcano_rounded,
                    size: 28,
                    color: Color(0xFFB0B0BE),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Belum Ada Riwayat Erupsi',
                  textAlign: TextAlign.center,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B6B78),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Data historis erupsi gunung akan ditampilkan di sini '
                  'setelah diinput oleh admin PVMBG/BPPTKG.',
                  textAlign: TextAlign.center,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF9E9EAE),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(delay: 300.ms, duration: 400.ms)
          .slideY(begin: 0.05, end: 0);
    }

    final eruptions = provider.eruptionHistory;
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: List.generate(
              eruptions.length,
              (i) => _EruptionTimelineItem(
                eruption: eruptions[i],
                isLatest: i == 0,
                isLast: i == eruptions.length - 1,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

// ─────────────────────────────────────────────
// Eruption Timeline Item
// ─────────────────────────────────────────────
class _EruptionTimelineItem extends StatelessWidget {
  final EruptionHistory eruption;
  final bool isLatest;
  final bool isLast;

  const _EruptionTimelineItem({
    required this.eruption,
    this.isLatest = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isLatest ? Colors.white : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLatest ? Colors.redAccent : const Color(0xFFD1D5DB),
                  width: 3,
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 56, color: const Color(0xFFF3F4F6)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      eruption.year.toString(),
                      style: AppFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color:
                            isLatest
                                ? Colors.redAccent
                                : const Color(0xFF1E1E2C),
                      ),
                    ),
                    if (eruption.veiLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withAlpha(30)),
                        ),
                        child: Text(
                          eruption.veiLabel!,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  eruption.description,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF6B6B78),
                  ),
                ),
                if (eruption.hasCasualties || eruption.hasEvacuees) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (eruption.hasCasualties)
                        _buildStatBadge(
                          '${eruption.casualties} korban jiwa',
                          Colors.red,
                        ),
                      if (eruption.hasEvacuees)
                        _buildStatBadge(
                          '${_formatNumber(eruption.evacuees)} mengungsi',
                          Colors.orange,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}jt';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}rb';
    return n.toString();
  }
}

// ─────────────────────────────────────────────
// Gallery Item
// ─────────────────────────────────────────────
class _GalleryItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _GalleryItem(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF1E1E2C),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Mountain Painter (background saat loading)
// ─────────────────────────────────────────────
class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final skyPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue.shade50.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.2),
            ],
          ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    final highlightPaint =
        Paint()
          ..color = Colors.grey.shade300.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    final basePaint =
        Paint()
          ..color = Colors.grey.shade400.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    final path1 =
        Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width * 0.2, size.height * 0.5)
          ..lineTo(size.width * 0.5, size.height)
          ..close();
    canvas.drawPath(path1, highlightPaint);

    final path =
        Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width * 0.15, size.height * 0.6)
          ..lineTo(size.width * 0.3, size.height * 0.75)
          ..lineTo(size.width * 0.45, size.height * 0.25)
          ..lineTo(size.width * 0.55, size.height * 0.22)
          ..lineTo(size.width * 0.7, size.height * 0.65)
          ..lineTo(size.width * 0.85, size.height * 0.5)
          ..lineTo(size.width, size.height * 0.7)
          ..lineTo(size.width, size.height)
          ..close();
    canvas.drawPath(path, basePaint);

    final snow =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

    final snowPath =
        Path()
          ..moveTo(size.width * 0.42, size.height * 0.32)
          ..lineTo(size.width * 0.45, size.height * 0.25)
          ..lineTo(size.width * 0.55, size.height * 0.22)
          ..lineTo(size.width * 0.58, size.height * 0.3)
          ..quadraticBezierTo(
            size.width * 0.5,
            size.height * 0.35,
            size.width * 0.42,
            size.height * 0.32,
          )
          ..close();
    canvas.drawPath(snowPath, snow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
