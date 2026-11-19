import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme_extensions.dart';
import '../models/hiking_weather.dart';
import '../services/hiking_weather_service.dart';
import '../services/localization_service.dart';

/// Reusable BMKG forecast card for hiking and volcano monitoring screens.
class HikingWeatherCard extends StatefulWidget {
  const HikingWeatherCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.cacheRegion,
    required this.canFetch,
    this.refreshVersion = 0,
    this.showRefreshButton = true,
    this.clock,
  });

  final double latitude;
  final double longitude;
  final String? cacheRegion;
  final bool canFetch;
  final int refreshVersion;
  final bool showRefreshButton;

  /// Sumber waktu untuk memilih slot prakiraan yang masih berlaku.
  /// Default [DateTime.now]; diisi di test agar deterministik.
  @visibleForTesting
  final DateTime Function()? clock;

  @override
  State<HikingWeatherCard> createState() => HikingWeatherCardState();
}

class HikingWeatherCardState extends State<HikingWeatherCard> {
  final HikingWeatherService _service = HikingWeatherService();
  HikingWeatherForecast? _weather;
  bool _loading = true;
  HikingWeatherFailure? _failure;
  bool _isCardVisible = true;
  bool _isHistoryExpanded = false;
  final Set<String> _expandedWarningIds = <String>{};
  Timer? _refreshTimer;
  int _requestGeneration = 0;
  String? _loadedRegion;
  Future<void>? _inFlight;
  String? _inFlightKey;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_refresh()),
    );
  }

  @override
  void didUpdateWidget(covariant HikingWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheRegion != widget.cacheRegion ||
        (!oldWidget.canFetch && widget.canFetch) ||
        oldWidget.refreshVersion != widget.refreshVersion) {
      if (oldWidget.cacheRegion != widget.cacheRegion) {
        _weather = null;
        _loadedRegion = null;
      }
      unawaited(_refresh());
    }
  }

  /// Memuat ulang data prakiraan cuaca BMKG secara langsung (mis. dari tombol refresh header).
  Future<void> refresh() => _refresh();

  /// Menggabungkan pemicu refresh yang datang bersamaan (timer, perubahan
  /// widget, pull-to-refresh) dengan parameter sama menjadi satu request.
  /// Perubahan region / izin fetch tetap memulai request baru.
  Future<void> _refresh() {
    final key = '${widget.cacheRegion}|${widget.canFetch}';
    final pending = _inFlight;
    if (pending != null && _inFlightKey == key) return pending;

    late final Future<void> future;
    future = _performRefresh().whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
        _inFlightKey = null;
      }
    });
    _inFlight = future;
    _inFlightKey = key;
    return future;
  }

  Future<void> _performRefresh() async {
    final generation = ++_requestGeneration;
    final region = widget.cacheRegion;
    if (region == null) {
      if (mounted) {
        setState(() {
          _weather = null;
          _loadedRegion = null;
          _loading = false;
          _failure = null;
        });
      }
      return;
    }
    if (!widget.canFetch) {
      final cached = await _service.loadCached(region);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _weather = cached;
        _loadedRegion = region;
        _loading = false;
        _failure = null;
      });
      return;
    }

    setState(() {
      _loading = _weather == null || _loadedRegion != region;
    });
    try {
      final result = await _service.load(
        latitude: widget.latitude,
        longitude: widget.longitude,
        cacheRegion: region,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _weather = result;
        _loadedRegion = region;
        _loading = false;
        _failure = null;
      });
    } on HikingWeatherException catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        final previous = _loadedRegion == region ? _weather : null;
        _weather = error.fallback ?? previous?.withStale(true);
        _loadedRegion = _weather == null ? null : region;
        _loading = false;
        _failure = error.failure;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loading = false;
        _failure = HikingWeatherFailure.unavailable;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _requestGeneration++;
    super.dispose();
  }

  String _time(DateTime? value, int utcOffsetHours) {
    if (value == null) return '--:--';
    final localTime = _toForecastTime(value, utcOffsetHours);
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }

  DateTime _toForecastTime(DateTime value, int utcOffsetHours) =>
      value.isUtc ? value.add(Duration(hours: utcOffsetHours)) : value;

  String _weatherDate(
    DateTime value,
    BuildContext context,
    int utcOffsetHours,
  ) {
    final localTime = _toForecastTime(value, utcOffsetHours);
    const months = [
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
    return '${localTime.day} ${context.trText(months[localTime.month - 1])} ${localTime.year}';
  }

  bool _isTodayInRegion(DateTime value, int utcOffsetHours) {
    final date = _toForecastTime(value, utcOffsetHours);
    final today = (widget.clock ?? DateTime.now)().toUtc().add(
      Duration(hours: utcOffsetHours),
    );
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  String _weatherTime(
    DateTime? value,
    BuildContext context,
    HikingWeatherForecast? weather, {
    bool includeTimezone = false,
  }) {
    if (value == null) return '--:--';
    final utcOffsetHours = weather?.utcOffsetHours ?? 8;
    final timezoneLabel = weather?.timezoneLabel ?? 'WITA';
    final time =
        '${_time(value, utcOffsetHours)}${includeTimezone ? ' $timezoneLabel' : ''}';
    return _isTodayInRegion(value, utcOffsetHours)
        ? time
        : '$time · ${_weatherDate(value, context, utcOffsetHours)}';
  }

  String _windValue(BuildContext context, HikingWeatherSlot slot) {
    final speed = slot.windKmh?.toStringAsFixed(0) ?? '--';
    final value = '$speed ${context.trText('km/j')}';
    final direction = _windDirectionName(context, slot.windDirection);
    return direction.isEmpty
        ? value
        : '$value ${context.trText('dari')} $direction';
  }

  String _windDirectionName(BuildContext context, String direction) {
    const directions = {
      'N': 'Utara',
      'NNE': 'Utara-timur laut',
      'NE': 'Timur laut',
      'ENE': 'Timur-timur laut',
      'E': 'Timur',
      'ESE': 'Timur-tenggara',
      'SE': 'Tenggara',
      'SSE': 'Selatan-tenggara',
      'S': 'Selatan',
      'SSW': 'Selatan-barat daya',
      'SW': 'Barat daya',
      'WSW': 'Barat-barat daya',
      'W': 'Barat',
      'WNW': 'Barat-barat laut',
      'NW': 'Barat laut',
      'NNW': 'Utara-barat laut',
    };
    final label = directions[direction.trim().toUpperCase()];
    return label == null ? '' : context.trText(label);
  }

  IconData _weatherIcon(String condition) {
    final value = condition.toLowerCase();
    if (value.contains('petir') ||
        value.contains('kilat') ||
        value.contains('badai') ||
        value.contains('thunder') ||
        value.contains('hujan lebat') ||
        value.contains('heavy rain')) {
      return Icons.thunderstorm_rounded;
    }
    if (value.contains('hujan') || value.contains('rain')) {
      return Icons.water_drop_rounded;
    }
    if (value.contains('kabut') || value.contains('fog')) {
      return Icons.cloud_queue_rounded;
    }
    if (value.contains('cerah') || value.contains('sun')) {
      return Icons.wb_sunny_rounded;
    }
    return Icons.cloud_rounded;
  }

  String _cleanBmkgText(String raw) {
    // Merapikan deretan nama kecamatan berhuruf kapital penuh dari BMKG CAP XML
    // agar mudah dibaca (Title Case) dan merapikan spasi berlebih.
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.replaceAllMapped(
      RegExp(r'\b[A-Z]{3,}(?:\s+[A-Z]{2,})*\b'),
      (match) {
        final phrase = match.group(0)!;
        if (const {'WIB', 'WITA', 'WIT', 'BMKG', 'NTB', 'NTT', 'DIY', 'SAR'}
            .contains(phrase)) {
          return phrase;
        }
        return phrase
            .split(' ')
            .map((word) {
              if (const {'DI', 'IV', 'II', 'III'}.contains(word)) return word;
              if (word.length <= 1) return word;
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            })
            .join(' ');
      },
    );
  }

  Widget _buildWarningCard(
    BuildContext context,
    HikingWeatherWarning warning,
    HikingWeatherForecast weather,
    Color textColor,
    Color muted,
  ) {
    final warningKey =
        warning.identifier.isNotEmpty ? warning.identifier : warning.headline;
    final isWarningExpanded = _expandedWarningIds.contains(warningKey);
    final isModerate = warning.severity.trim().toLowerCase() == 'moderate';
    final bannerColor = isModerate ? context.warningColor : context.errorColor;
    final badgeText = context.trText(
      isModerate ? 'IMBAUAN CUACA PENDAKIAN' : 'PERINGATAN DINI CUACA',
    );
    final cleanedDesc = _cleanBmkgText(context.trText(warning.description));

    // Pisahkan kalimat deskripsi BMKG menjadi poin-poin terstruktur
    final sentences =
        cleanedDesc
            .split(RegExp(r'(?<=\.)\s+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    // Tetap UTC: `_weatherTime` menggeser ke zona wilayah (WIB/WITA) sendiri.
    // Jangan `.toLocal()` — itu memakai zona perangkat, bukan zona gunung.
    final expiryText =
        warning.expiresAt != null
            ? _weatherTime(
              warning.expiresAt!.toUtc(),
              context,
              weather,
              includeTimezone: true,
            )
            : null;

    return InkWell(
      onTap: () {
        setState(() {
          if (isWarningExpanded) {
            _expandedWarningIds.remove(warningKey);
          } else {
            _expandedWarningIds.add(warningKey);
          }
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bannerColor.withAlpha(14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bannerColor.withAlpha(90)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: bannerColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isModerate
                        ? Icons.wb_cloudy_rounded
                        : Icons.thunderstorm_rounded,
                    color: bannerColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: bannerColor.withAlpha(24),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: bannerColor,
                              ),
                            ),
                          ),
                          if (expiryText != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${context.trText('Hingga')} $expiryText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.trText(warning.headline),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isWarningExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: bannerColor,
                ),
              ],
            ),
            if (sentences.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (!isWarningExpanded)
                Text(
                  sentences.first,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: textColor,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < sentences.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == sentences.length - 1 ? 0 : 6,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: bannerColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sentences[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.45,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    final cardColor = context.bgSurface;
    final borderColor = context.borderColor;
    final textColor = context.textPrimary;
    final muted = context.textSecondary;
    final now = (widget.clock ?? DateTime.now)();
    final allSlots = weather?.activeForecasts(now) ?? const <HikingWeatherSlot>[];
    final nextSlots = allSlots.take(3).toList();
    final current = allSlots.isEmpty ? null : allSlots.first;
    final activeWarnings =
        weather?.activeWarnings(now) ?? const <HikingWeatherWarning>[];
    final displayedWarnings =
        _isHistoryExpanded ? activeWarnings : activeWarnings.take(2).toList();

    final areaLabel =
        (weather?.areaName.trim().isNotEmpty ?? false)
            ? weather!.areaName.trim()
            : context.trText('Untuk wilayah prakiraan BMKG');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _isCardVisible = !_isCardVisible),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: context.accentPrimary.withAlpha(22),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.cloud_outlined,
                          size: 19,
                          color: context.accentPrimary,
                        ),
                      ),
                      if (!_isCardVisible && activeWarnings.isNotEmpty)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: context.errorColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardColor, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.trText('Prakiraan cuaca'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          !_isCardVisible && current != null
                              ? '$areaLabel · ${current.temperatureC == null ? '--°' : '${current.temperatureC!.round()}°'} ${current.condition}'
                              : areaLabel,
                          maxLines:
                              _isHistoryExpanded && _isCardVisible ? null : 1,
                          overflow:
                              _isHistoryExpanded && _isCardVisible
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: muted),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showRefreshButton)
                    IconButton(
                      tooltip: context.trText('Perbarui cuaca'),
                      visualDensity: VisualDensity.compact,
                      onPressed: _loading ? null : () => unawaited(_refresh()),
                      icon:
                          _loading && weather == null
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.accentPrimary,
                                ),
                              )
                              : Icon(
                                Icons.refresh_rounded,
                                size: 19,
                                color: muted,
                              ),
                    ),
                  IconButton(
                    key: const Key('weather_card_visibility_toggle'),
                    tooltip: context.trText(
                      _isCardVisible
                          ? 'Sembunyikan kartu prakiraan cuaca'
                          : 'Tampilkan kartu prakiraan cuaca',
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        () => setState(() => _isCardVisible = !_isCardVisible),
                    icon: AnimatedRotation(
                      turns: _isCardVisible ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isCardVisible) ...[
              if (weather != null && displayedWarnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final warning in displayedWarnings)
                  _buildWarningCard(context, warning, weather, textColor, muted),
              ],
              const SizedBox(height: 7),
              if (_loading && weather == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    context.trText('Memuat prakiraan BMKG...'),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                )
              else if (weather == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Text(
                    widget.cacheRegion == null
                        ? context.trText(
                          'Lokasi GPS belum menunjukkan area pendakian yang didukung.',
                        )
                        : _failure == HikingWeatherFailure.outsideArea
                        ? context.trText(
                          'Posisi Anda di luar radius 15 km area prakiraan pendakian. Kembali ke area pendakian untuk memuat cuaca.',
                        )
                        : _failure != null
                        ? context.trText(
                          'Cuaca belum tersedia. Periksa koneksi lalu coba lagi.',
                        )
                        : context.trText('Menunggu lokasi GPS terbaru.'),
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                )
              else ...[
                if (_failure != null)
                  _buildStatusNotice(
                    context,
                    _failure == HikingWeatherFailure.outsideArea
                        ? 'Posisi Anda di luar radius 15 km area prakiraan. Menampilkan data tersimpan.'
                        : 'Gagal memperbarui cuaca. Menampilkan data tersimpan.',
                  ),
                if (current == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Text(
                      context.trText(
                        'Prakiraan tersimpan sudah kedaluwarsa. Perbarui saat ada koneksi.',
                      ),
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ),
                if (current != null)
                  Row(
                    children: [
                      Icon(
                        _weatherIcon(current.condition),
                        size: 32,
                        color: context.accentPrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        current.temperatureC == null
                            ? '--°'
                            : '${current.temperatureC!.round()}°',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          current.condition,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (current != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _weatherMetric(
                        context,
                        Icons.water_drop_outlined,
                        '${current.humidityPercent?.round() ?? '--'}%',
                        context.trText('Kelembapan'),
                      ),
                      _weatherMetric(
                        context,
                        Icons.air_rounded,
                        _windValue(context, current),
                        context.trText('Angin'),
                        labelFirst: true,
                      ),
                      _weatherMetric(
                        context,
                        Icons.schedule_rounded,
                        _weatherTime(
                          current.localDateTime,
                          context,
                          weather,
                          includeTimezone: true,
                        ),
                        context.trText('Prakiraan'),
                      ),
                    ],
                  ),
                ],
                if (allSlots.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 8),
                  InkWell(
                    key: const Key('weather_history_dropdown_toggle'),
                    onTap:
                        () => setState(
                          () => _isHistoryExpanded = !_isHistoryExpanded,
                        ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: context.accentPrimary.withAlpha(14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _isHistoryExpanded
                                  ? '${context.trText('Sembunyikan riwayat cuaca')} (${allSlots.length} ${context.trText('jadwal')})'
                                  : '${context.trText('Lihat seluruh riwayat cuaca')} (${allSlots.length} ${context.trText('jadwal')})',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: context.accentPrimary,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isHistoryExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 17,
                              color: context.accentPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!_isHistoryExpanded && nextSlots.length > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    children:
                        nextSlots
                            .skip(1)
                            .map(
                              (slot) => Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      _weatherTime(
                                        slot.localDateTime,
                                        context,
                                        weather,
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: muted,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Icon(
                                      _weatherIcon(slot.condition),
                                      size: 15,
                                      color: context.accentPrimary,
                                    ),
                                    Text(
                                      slot.temperatureC == null
                                          ? '--°'
                                          : '${slot.temperatureC!.round()}°',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      slot.condition,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
                if (_isHistoryExpanded && allSlots.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (var i = 0; i < allSlots.length; i++)
                    _buildForecastSlotCard(
                      context,
                      allSlots[i],
                      weather,
                      textColor,
                      muted,
                      borderColor,
                      isCurrent: i == 0,
                    ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${context.trText('Data BMKG diperbarui')} ${_weatherTime(weather.analysisDate ?? weather.fetchedAt, context, weather, includeTimezone: true)} · ${weather.isStale ? context.trText('data tersimpan') : context.trText('prakiraan berkala')} · ${context.trText('Cuaca di ketinggian dapat berbeda.')}',
                  style: TextStyle(fontSize: 9.5, color: muted),
                ),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  link: true,
                  label: context.trText('Buka sumber data cuaca BMKG'),
                  child: Tooltip(
                    message: context.trText('Buka sumber data cuaca BMKG'),
                    child: InkWell(
                      onTap: () => unawaited(_openBmkgSource()),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 12,
                              color: context.accentPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.trText('Sumber: BMKG'),
                              style: TextStyle(
                                color: context.accentPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: context.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSlotCard(
    BuildContext context,
    HikingWeatherSlot slot,
    HikingWeatherForecast weather,
    Color textColor,
    Color muted,
    Color borderColor, {
    bool isCurrent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isCurrent
                  ? context.accentPrimary.withAlpha(110)
                  : borderColor.withAlpha(120),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _weatherIcon(slot.condition),
                size: 17,
                color: context.accentPrimary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        slot.condition.isEmpty ? '-' : slot.condition,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: context.accentPrimary.withAlpha(24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.trText('Terkini'),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: context.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                slot.temperatureC == null
                    ? '--°C'
                    : '${slot.temperatureC!.round()}°C',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _weatherMetric(
                context,
                Icons.schedule_rounded,
                _weatherTime(
                  slot.localDateTime,
                  context,
                  weather,
                  includeTimezone: true,
                ),
                context.trText('Waktu'),
                labelFirst: true,
              ),
              _weatherMetric(
                context,
                Icons.water_drop_outlined,
                '${slot.humidityPercent?.round() ?? '--'}%',
                context.trText('Kelembapan'),
              ),
              _weatherMetric(
                context,
                Icons.air_rounded,
                _windValue(context, slot),
                context.trText('Angin'),
                labelFirst: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBmkgSource() async {
    final uri = Uri.parse('https://data.bmkg.go.id/prakiraan-cuaca/');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Forecast data remains available in the card if an external browser
      // cannot be opened on this device.
    }
  }

  Widget _buildStatusNotice(BuildContext context, String message) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: context.warningColor.withAlpha(16),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: context.warningColor.withAlpha(70)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: context.warningColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.trText(message),
            style: TextStyle(fontSize: 10.5, color: context.textPrimary),
          ),
        ),
      ],
    ),
  );

  Widget _weatherMetric(
    BuildContext context,
    IconData icon,
    String value,
    String label, {
    bool labelFirst = false,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: context.textSecondary),
      const SizedBox(width: 4),
      Text(
        labelFirst ? '$label $value' : '$value ${label.toLowerCase()}',
        style: TextStyle(fontSize: 10, color: context.textSecondary),
      ),
    ],
  );
}
