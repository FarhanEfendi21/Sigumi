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
  });

  final double latitude;
  final double longitude;
  final String? cacheRegion;
  final bool canFetch;

  @override
  State<HikingWeatherCard> createState() => _HikingWeatherCardState();
}

class _HikingWeatherCardState extends State<HikingWeatherCard> {
  final HikingWeatherService _service = HikingWeatherService();
  HikingWeatherForecast? _weather;
  bool _loading = true;
  bool _failed = false;
  Timer? _refreshTimer;
  int _requestGeneration = 0;
  String? _loadedRegion;

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
        (!oldWidget.canFetch && widget.canFetch)) {
      if (oldWidget.cacheRegion != widget.cacheRegion) {
        _weather = null;
        _loadedRegion = null;
      }
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final generation = ++_requestGeneration;
    final region = widget.cacheRegion;
    if (region == null) {
      if (mounted) {
        setState(() {
          _weather = null;
          _loadedRegion = null;
          _loading = false;
          _failed = false;
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
        _failed = false;
      });
      return;
    }

    setState(() {
      _loading = _weather == null || _loadedRegion != region;
      _failed = false;
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
        _failed = false;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loading = false;
        _failed = true;
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
    final today = DateTime.now().toUtc().add(Duration(hours: utcOffsetHours));
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

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    final cardColor = context.bgSurface;
    final borderColor = context.borderColor;
    final textColor = context.textPrimary;
    final muted = context.textSecondary;
    final nextSlots = weather?.forecasts.take(3).toList() ?? const [];
    final current = nextSlots.isEmpty ? null : nextSlots.first;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      weather?.areaName ??
                          context.trText('Untuk wilayah prakiraan BMKG'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: muted),
                    ),
                  ],
                ),
              ),
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
                        : Icon(Icons.refresh_rounded, size: 19, color: muted),
              ),
            ],
          ),
          if (weather?.warnings.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            for (final warning in weather!.warnings.take(2))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.errorColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.errorColor.withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.errorColor,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warning.headline,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.errorColor,
                            ),
                          ),
                          if (warning.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              warning.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: textColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                    : _failed
                    ? context.trText(
                      'Cuaca belum tersedia. Periksa koneksi lalu coba lagi.',
                    )
                    : context.trText('Menunggu lokasi GPS terbaru.'),
                style: TextStyle(fontSize: 11.5, color: muted),
              ),
            )
          else ...[
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
            if (nextSlots.length > 1) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: borderColor),
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
                                  style: TextStyle(fontSize: 10, color: muted),
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
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${context.trText('Data BMKG diperbarui')} ${_weatherTime(weather.analysisDate ?? weather.fetchedAt, context, weather, includeTimezone: true)} · ${weather.isStale ? context.trText('data tersimpan') : context.trText('prakiraan berkala')} · ${context.trText('Cuaca di ketinggian dapat berbeda.')}',
              style: TextStyle(fontSize: 9.5, color: muted),
            ),
          ],
          const SizedBox(height: 6),
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
