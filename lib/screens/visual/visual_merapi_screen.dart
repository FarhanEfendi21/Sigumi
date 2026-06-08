import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../models/eruption_history.dart';
import '../../models/volcano_model.dart';
import '../../providers/volcano_provider.dart';
import '../../widgets/volcanic_report_section.dart';
import 'package:url_launcher/url_launcher.dart';

/// Data kamera CCTV Merapi
class _CctvCamera {
  final String label;
  final String location;
  final String url;
  final IconData icon;
  final LatLng position;

  const _CctvCamera({
    required this.label,
    required this.location,
    required this.url,
    required this.icon,
    required this.position,
  });
}

const List<_CctvCamera> _merapiCameras = [
  _CctvCamera(
    label: 'Ngandong',
    location: 'Pos Ngandong',
    url: 'https://cctv.jogjaprov.go.id/pantauan-merapi-ngandong',
    icon: Icons.videocam_rounded,
    position: LatLng(-7.5333, 110.4283),
  ),
  _CctvCamera(
    label: 'Klangon',
    location: 'View dari Klangon',
    url: 'https://cctv.jogjaprov.go.id/gunung-merapi-view-dari-klangon',
    icon: Icons.videocam_rounded,
    position: LatLng(-7.5852, 110.4505),
  ),
  _CctvCamera(
    label: 'Museum',
    location: 'View dari Museum',
    url: 'https://cctv.jogjaprov.go.id/gunung-merapi-view-dari-museum',
    icon: Icons.videocam_rounded,
    position: LatLng(-7.6158, 110.4244),
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
  WebViewController? _webViewController;
  bool _isWebViewLoading = true;
  bool _hasWebViewError = false;
  bool _isPlatformSupported = true;

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
    if (_isPlatformSupported) {
      _initWebView(_merapiCameras[0].url);
    } else {
      _isWebViewLoading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolcanoProvider>().fetchEruptionHistory();
      context.read<VolcanoProvider>().fetchDailyReports();
    });
  }

  void _checkPlatformSupport() {
    if (kIsWeb) {
      _isPlatformSupported = false;
      return;
    }
    // webview_flutter only supports Android, iOS, and macOS out of the box
    if (Platform.isWindows || Platform.isLinux) {
      _isPlatformSupported = false;
    }
  }

  void _initWebView(String url) {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFF8F9FA))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {
                if (mounted) {
                  setState(() {
                    _isWebViewLoading = true;
                    _hasWebViewError = false;
                  });
                }
              },
              onPageFinished: (_) {
                if (mounted) {
                  setState(() => _isWebViewLoading = false);
                }
              },
              onWebResourceError: (_) {
                if (mounted) {
                  setState(() {
                    _isWebViewLoading = false;
                    _hasWebViewError = true;
                  });
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(url));
  }

  void _switchCamera(int index) {
    if (!_isPlatformSupported) {
      setState(() => _selectedCameraIndex = index);
      return;
    }
    if (_selectedCameraIndex == index) return;
    setState(() {
      _selectedCameraIndex = index;
    });
    _webViewController?.loadRequest(Uri.parse(_merapiCameras[index].url));
  }

  void _reloadCamera() {
    if (!_isPlatformSupported) return;
    _webViewController?.reload();
  }

  Future<void> _openFullScreen() async {
    final url = _merapiCameras[_selectedCameraIndex].url;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan kamera')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        late VolcanoModel volcano;
        if (widget.volcano != null) {
          volcano = widget.volcano!;
        } else {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is VolcanoModel) {
            volcano = args;
          } else {
            volcano = provider.volcano;
          }
        }

        final hasCctv = volcano.id == 'merapi_001' || 
                        volcano.id == VolcanoModel.kMerapiUuid || 
                        volcano.name.toLowerCase().contains('merapi');

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── CCTV Section (hanya untuk Merapi) ──
                if (hasCctv) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 420,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141B),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // ── WebView ──
                        Positioned.fill(
                          child:
                              !_isPlatformSupported
                                  ? _buildUnsupportedView()
                                  : _hasWebViewError
                                      ? _buildErrorView()
                                      : WebViewWidget(
                                        controller: _webViewController!,
                                      ),
                        ),

                        // ── Loading Overlay ──
                        if (_isWebViewLoading)
                          Positioned.fill(
                            child: Container(
                              color: const Color(0xFF14141B),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Menghubungkan ke Kamera...',
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ── Top Info Overlay ──
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _merapiCameras[_selectedCameraIndex].location,
                                      style: AppFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _reloadCamera,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _openFullScreen,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms, begin: 0.3, end: 1.0),
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
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Camera Selector (Floating Bottom) ──
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: _merapiCameras.asMap().entries.map((entry) {
                                final i = entry.key;
                                final camera = entry.value;
                                final isSelected = _selectedCameraIndex == i;
                                return GestureDetector(
                                  onTap: () => _switchCamera(i),
                                  child: AnimatedContainer(
                                    duration: 300.ms,
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? Colors.white 
                                          : Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isSelected 
                                            ? Colors.white 
                                            : Colors.white.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          camera.icon,
                                          size: 16,
                                          color: isSelected ? const Color(0xFF1E1E2C) : Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          camera.label,
                                          style: AppFonts.plusJakartaSans(
                                            color: isSelected ? const Color(0xFF1E1E2C) : Colors.white,
                                            fontSize: 13,
                                            fontWeight: isSelected 
                                                ? FontWeight.w800 
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms),

                  const SizedBox(height: 24),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasCctv) ...[
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
                                      volcano.name,
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

                      // ── Informasi Terkini (dari MAGMA Indonesia) ──
                      Row(
                        children: [
                          Text(
                            'Informasi Terkini',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E2C),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              'PVMBG',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.redAccent.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sumber: MAGMA Indonesia',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF9E9EAE),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildClimatologySection(provider, volcano)
                          .animate()
                          .fadeIn(delay: 150.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0),

                      const SizedBox(height: 32),

                      // ── Laporan Harian MAGMA ──
                      VolcanicReportSection(
                        reports: provider.dailyReports,
                        isLoading: provider.isLoadingDailyReports,
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

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

  Widget _buildUnsupportedView() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E2C), Color(0xFF14141B)],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.devices_other_rounded,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'CCTV Tidak Tersedia',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Siaran CCTV hanya dapat dibuka pada perangkat Android, iOS, atau macOS.',
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF9E9EAE),
                      height: 1.4,
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

  Widget _buildErrorView() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E2C), Color(0xFF14141B)],
              ),
            ),
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




  // ── Seksi Informasi Klimatologi dari MAGMA ──────────────────────
  Widget _buildClimatologySection(VolcanoProvider provider, VolcanoModel volcano) {
    // Ambil laporan terbaru untuk gunung ini
    final key = volcano.name.toLowerCase().contains('merapi')
        ? 'merapi'
        : volcano.name.toLowerCase().contains('agung')
            ? 'agung'
            : 'rinjani';

    final report = provider.dailyReports
        .where((r) => r.volcanoKey == key)
        .isNotEmpty
        ? provider.dailyReports.firstWhere((r) => r.volcanoKey == key)
        : null;

    final isLoading = provider.isLoadingDailyReports;

    // Jika loading → skeleton
    if (isLoading) {
      return Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSkeletonCard(),
          ),
        ),
      );
    }

    // Tentukan nilai: pakai MAGMA jika ada, fallback ke volcano mock
    final hasReport = report != null && report.hasClimatologyData;

    final weather = hasReport
        ? (report.weather ?? '-')
        : 'Data belum tersedia';
    final windVal = hasReport
        ? report.windLabel
        : (volcano.windDirection != null
            ? '${volcano.windDirection}'
            : '-');
    final humidityVal = hasReport ? report.humidityLabel : '-';
    final pressureVal = hasReport ? report.pressureLabel : '-';
    final elevationVal = '${volcano.elevation.toInt()} mdpl';

    return Column(
      children: [
        // Cuaca - Full Width
        _buildMetricCard(
          icon: Icons.wb_sunny_rounded,
          label: 'Kondisi Cuaca',
          value: weather,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),
        // Angin - Full Width
        _buildMetricCard(
          icon: Icons.air_rounded,
          label: 'Angin',
          value: windVal,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        // Elevasi - Full Width
        _buildMetricCard(
          icon: Icons.height_rounded,
          label: 'Elevasi',
          value: elevationVal,
          color: Colors.indigo,
        ),
        const SizedBox(height: 12),
        // Tekanan Udara & Kelembaban - sejajar
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.compress_rounded,
                label: 'Tekanan Udara',
                value: pressureVal,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_drop_rounded,
                label: 'Kelembaban',
                value: humidityVal,
                color: Colors.teal,
              ),
            ),
          ],
        ),

        // Badge sumber + tanggal laporan
        if (hasReport) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Data per ${_formatReportDate(report.reportDate)}',
                style: AppFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }


  /// Unified Metric Card (Bisa Full Width atau dalam Row)
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF8E8E9E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E2C),
              height: 1.3,
            ),
            // Hapus maxLines & overflow agar text bisa multiline (wrap)
          ),
        ],
      ),
    );
  }

  /// Skeleton card saat loading
  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
          begin: 0.4,
          end: 0.8,
          duration: 800.ms,
        );
  }

  String _formatReportDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
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

