import '../../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:sigumi/config/theme_extensions.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../models/volcano_model.dart';
import '../../providers/volcano_provider.dart';
import '../../widgets/volcano_summarizer_widget.dart';

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
          ..setBackgroundColor(const Color(0xFF080B10))
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
                _focusCameraPlayer();
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

  void _focusCameraPlayer() {
    _webViewController?.runJavaScript(r'''(() => {
      let attempts = 0;
      const isolatePlayer = () => {
        const player = document.querySelector('.video-js, .plyr, video') ||
          document.querySelector('iframe');
        if (!player && attempts++ < 30) {
          window.setTimeout(isolatePlayer, 500);
          return;
        }
        if (!player) return;

        let node = player;
        while (node && node !== document.body) {
          for (const sibling of Array.from(node.parentElement?.children || [])) {
            if (sibling !== node) sibling.style.setProperty('display', 'none', 'important');
          }
          node.style.setProperty('width', '100vw', 'important');
          node.style.setProperty('height', '100vh', 'important');
          node.style.setProperty('max-width', 'none', 'important');
          node.style.setProperty('margin', '0', 'important');
          node.style.setProperty('padding', '0', 'important');
          node.style.setProperty('border-radius', '0', 'important');
          node = node.parentElement;
        }
        for (const element of [document.documentElement, document.body]) {
          element.style.setProperty('width', '100%', 'important');
          element.style.setProperty('height', '100%', 'important');
          element.style.setProperty('min-height', '100%', 'important');
          element.style.setProperty('margin', '0', 'important');
          element.style.setProperty('padding', '0', 'important');
          element.style.setProperty('overflow', 'hidden', 'important');
          element.style.setProperty('background', '#080b10', 'important');
        }
        if (player.tagName === 'VIDEO') {
          player.style.setProperty('width', '100%', 'important');
          player.style.setProperty('height', '100%', 'important');
          player.style.setProperty('object-fit', 'contain', 'important');
        }
      };
      isolatePlayer();
    })();''');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VolcanoProvider>();
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

        final hasCctv =
            volcano.id == 'merapi_001' ||
            volcano.id == VolcanoModel.kMerapiUuid ||
            volcano.name.toLowerCase().contains('merapi');
        final volcanoKey = switch (volcano.name.toLowerCase()) {
          final name when name.contains('merapi') => 'merapi',
          final name when name.contains('agung') => 'agung',
          final name when name.contains('rinjani') => 'rinjani',
          _ => null,
        };

    return Scaffold(
          backgroundColor: provider.highContrast
              ? context.bgPrimary
              : hasCctv
                  ? const Color(0xFF080B10)
                  : Colors.white,
          appBar: AppBar(
            title: Text(
              hasCctv ? 'Pantauan Gunung' : 'Detail ${volcano.name}',
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: provider.highContrast || hasCctv
                    ? Colors.white
                    : const Color(0xFF1E1E2C),
              ),
            ),
            backgroundColor: provider.highContrast
                ? context.bgPrimary
                : hasCctv
                    ? const Color(0xFF080B10)
                    : Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(
              color: provider.highContrast || hasCctv
                  ? Colors.white
                  : const Color(0xFF1E1E2C),
            ),
            centerTitle: true,
            actions:
                hasCctv
                    ? [
                      IconButton(
                        onPressed: _reloadCamera,
                        tooltip: context.tr('try_again'),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      const SizedBox(width: 4),
                    ]
                    : null,
          ),
          body:
              hasCctv
                  ? _buildCctvPage(provider, volcano, volcanoKey)
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                          width: 1,
                                        ),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  volcano.name,
                                                  style:
                                                      AppFonts.plusJakartaSans(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade900,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  context.trText(
                                                    'Belum memiliki sistem CCTV. Silakan lihat informasi detail di bawah.',
                                                  ),
                                                  style:
                                                      AppFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade700,
                                                        height: 1.4,
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
                              ],

                              _buildVolcanoInfoSection(volcano, volcanoKey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
    );
  }

  Widget _buildCctvPage(
    VolcanoProvider provider,
    VolcanoModel volcano,
    String? volcanoKey,
  ) {
    final camera = _merapiCameras[_selectedCameraIndex];
    final isHC = provider.highContrast;
    final selectionAccent = context.accentPrimary;
    final playerHeight =
        (MediaQuery.sizeOf(context).height * 0.56)
            .clamp(320.0, 560.0)
            .toDouble();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: playerHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!_isPlatformSupported)
                  _buildUnsupportedView()
                else if (_hasWebViewError)
                  _buildErrorView()
                else if (_webViewController != null)
                  WebViewWidget(controller: _webViewController!),
                if (_isWebViewLoading && _isPlatformSupported)
                  Container(
                    color: const Color(0xFF080B10),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: selectionAccent,
                        ),
                      ),
                    ),
                  ),
                if (!_hasWebViewError && _isPlatformSupported)
                  Positioned(
                    left: 16,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xD910141B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: selectionAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'LIVE  ·  ${camera.label.toUpperCase()}',
                            style: AppFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
            decoration: BoxDecoration(
              color: isHC ? context.bgSurface : const Color(0xFF11151D),
              border: Border(
                top: BorderSide(
                  color: isHC ? context.borderColor : const Color(0xFF252B35),
                  width: isHC ? context.borderWidth : 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PILIH LOKASI CCTV',
                  style: AppFonts.plusJakartaSans(
                    color: isHC ? context.textPrimary : const Color(0xFF929BA9),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _merapiCameras.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 9),
                    itemBuilder: (context, index) {
                      final option = _merapiCameras[index];
                      final selected = index == _selectedCameraIndex;
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: option.location,
                        child: Material(
                          color:
                              selected
                                  ? selectionAccent
                                  : isHC
                                      ? context.bgPrimary
                                      : const Color(0xFF1B212B),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _switchCamera(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    option.icon,
                                    size: 16,
                                    color:
                                        selected && isHC
                                            ? context.bgPrimary
                                            : selected || isHC
                                                ? Colors.white
                                                : const Color(0xFFADB5C0),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    option.label,
                                    style: AppFonts.plusJakartaSans(
                                          color: selected && isHC
                                              ? context.bgPrimary
                                              : selected || isHC
                                                  ? Colors.white
                                                  : const Color(0xFFADB5C0),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: isHC ? context.bgPrimary : const Color(0xFFF6F7F9),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: _buildVolcanoInfoSection(volcano, volcanoKey),
          ),
        ],
      ),
    );
  }

  Widget _buildVolcanoInfoSection(VolcanoModel volcano, String? volcanoKey) {
    final isHC = context.isHighContrast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.trText('Informasi Terkini'),
          style: AppFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isHC ? context.textPrimary : const Color(0xFF1E1E2C),
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
                  title: context.tr('crater_temp'),
                  value: '${volcano.temperature ?? '-'}°C',
                  color: Colors.orange,
                ),
                _buildInfoGridCard(
                  icon: Icons.air_rounded,
                  title: context.tr('wind_direction'),
                  value: volcano.windDirection ?? '-',
                  color: Colors.blue,
                ),
                _buildInfoGridCard(
                  icon: Icons.speed_rounded,
                  title: context.tr('wind_speed'),
                  value: '${volcano.windSpeed ?? '-'} km/h',
                  color: Colors.teal,
                ),
                _buildInfoGridCard(
                  icon: Icons.height_rounded,
                  title: context.tr('elevation'),
                  value: '${volcano.elevation} mdpl',
                  color: Colors.indigo,
                ),
              ],
            )
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms)
            .slideY(begin: 0.05, end: 0),
        const SizedBox(height: 32),
        if (volcanoKey != null)
          VolcanoLatestSummaryWithHistoryButton(
            volcanoKey: volcanoKey,
            limit: 30,
            title: context.tr('activity_report'),
          ),
        if (volcanoKey != null) const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUnsupportedView() {
    return Container(
      color: const Color(0xFF080B10),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.devices_other_rounded,
              color: Color(0xFFE34B4B),
              size: 34,
            ),
            const SizedBox(height: 14),
            Text(
              context.trText('CCTV Tidak Tersedia'),
              style: AppFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.trText(
                'Siaran CCTV hanya dapat dibuka pada perangkat Android, iOS, atau macOS.',
              ),
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF929BA9),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: const Color(0xFF080B10),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFE34B4B),
              size: 34,
            ),
            const SizedBox(height: 14),
            Text(
              context.trText('Gagal memuat siaran'),
              style: AppFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.trText('Periksa koneksi internet kamu'),
              style: AppFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF929BA9),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _reloadCamera,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(context.tr('try_again')),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE34B4B),
              ),
            ),
          ],
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
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
        boxShadow: context.cardShadow,
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
                    color: context.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E2C),
            ),
          ),
        ],
      ),
    );
  }
}
