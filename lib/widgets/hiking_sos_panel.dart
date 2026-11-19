import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../config/fonts.dart';
import '../config/theme_extensions.dart';
import '../models/hiking_sos.dart';
import '../services/hiking_tracking_service.dart';
import '../services/localization_service.dart';

class HikingSosPanel extends StatefulWidget {
  const HikingSosPanel({super.key, required this.tracking});

  final HikingTrackingService tracking;

  @override
  State<HikingSosPanel> createState() => _HikingSosPanelState();
}

class _HikingSosPanelState extends State<HikingSosPanel> {
  bool _isSubmitting = true;
  bool _isRetrying = false;
  bool _isCheckingStatus = false;
  HikingSosResult? _result;
  late HikingSosLocation? _location;
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _location =
        widget.tracking.activeSosResult?.location ??
        widget.tracking.lastRecordedSosLocation;
    _submitSos();
    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_pollBackofficeStatus()),
    );
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  HikingSosResult? get _effectiveResult {
    final alertId = _result?.alertId ?? widget.tracking.activeSosAlertId;
    if (alertId != null) {
      final tracked = widget.tracking.getSosResult(alertId);
      if (tracked != null) return tracked;
    }
    return _result ?? widget.tracking.activeSosResult;
  }

  Future<void> _submitSos() async {
    final result = await widget.tracking.sendSos();
    if (!mounted) return;
    setState(() {
      _result = result;
      _location = result.location ?? _location;
      _isSubmitting = false;
    });
  }

  Future<void> _pollBackofficeStatus() async {
    if (!mounted || _isSubmitting || _isRetrying || _isCheckingStatus) return;
    final current = _effectiveResult;
    final alertId = current?.alertId;
    if (alertId == null) return;
    if (widget.tracking.isSosPending(alertId)) {
      await _retrySos();
      return;
    }
    if (current?.status == HikingSosStatus.resolved ||
        current?.status == HikingSosStatus.cancelled) {
      return;
    }
    final refreshed = await widget.tracking.refreshSosStatus(alertId: alertId);
    if (!mounted || refreshed == null) return;
    setState(() {
      _result = refreshed;
      _location = refreshed.location ?? _location;
    });
  }

  Future<void> _retrySos() async {
    final alertId = _effectiveResult?.alertId;
    if (alertId == null || _isRetrying) return;
    setState(() => _isRetrying = true);
    final uploaded = await widget.tracking.retryPendingSos(alertId);
    if (!mounted) return;
    final updated = widget.tracking.getSosResult(alertId);
    setState(() {
      _isRetrying = false;
      if (updated != null) {
        _result = updated;
        _location = updated.location ?? _location;
      } else if (uploaded && _result != null) {
        _result = HikingSosResult(
          status: HikingSosStatus.savedToServer,
          alertId: alertId,
          location: _location,
        );
      }
    });
  }

  Future<void> _refreshBackofficeStatusManual() async {
    final alertId = _effectiveResult?.alertId;
    if (alertId == null || _isSubmitting || _isRetrying || _isCheckingStatus) {
      return;
    }
    setState(() => _isCheckingStatus = true);
    final refreshed = await widget.tracking.refreshSosStatus(alertId: alertId);
    if (!mounted) return;
    setState(() {
      _isCheckingStatus = false;
      if (refreshed != null) {
        _result = refreshed;
        _location = refreshed.location ?? _location;
      }
    });
  }

  Future<void> _sendSosToBackoffice() async {
    if (_isSubmitting || _isRetrying || _isCheckingStatus) return;

    final current = _effectiveResult;
    final alertId = current?.alertId;
    if (alertId != null && widget.tracking.isSosPending(alertId)) {
      await _retrySos();
      return;
    }

    if (current != null && current.isServerStored) {
      await _refreshBackofficeStatusManual();
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await widget.tracking.sendSos();
    if (!mounted) return;
    setState(() {
      _result = result;
      _location = result.location ?? _location;
      _isSubmitting = false;
    });
  }

  Future<void> _copyCoordinates(HikingSosLocation location) async {
    final text =
        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showMessage(context.trTextSafe('Koordinat disalin'));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tracking,
      builder: (context, _) {
        final isHC = context.isHighContrast;
        final result = _effectiveResult;
        final wasUploaded =
            result?.alertId != null &&
            widget.tracking.wasSosUploaded(result!.alertId!);
        final status =
            result != null && result.isServerStored
                ? result.status
                : wasUploaded
                ? HikingSosStatus.savedToServer
                : result?.status;
        final isServerStored =
            (result?.isServerStored ?? false) || wasUploaded;
        final isBusy = _isSubmitting || _isRetrying || _isCheckingStatus;
        final statusColor = _resolveStatusColor(context, status);

        final headline = _headlineForStatus(context, status);
        final subtitle = _subtitleForStatus(context, status, result);
        final canCheckStatus =
            isServerStored &&
            status != HikingSosStatus.resolved &&
            status != HikingSosStatus.cancelled;

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border:
                    isHC
                        ? Border(
                          top: BorderSide(
                            color: context.borderColor,
                            width: 1.5,
                          ),
                        )
                        : null,
                boxShadow:
                    isHC
                        ? null
                        : [
                          BoxShadow(
                            color: Colors.black.withAlpha(32),
                            blurRadius: 24,
                            offset: const Offset(0, -6),
                          ),
                        ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.dividerColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header tunggal: micro-status + judul tegas + tombol tutup
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isSubmitting || _isRetrying)
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: statusColor,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusColor,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.trText('DARURAT SOS'),
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                headline,
                                style: AppFonts.plusJakartaSans(
                                  color: context.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: AppFonts.plusJakartaSans(
                                    color: context.textSecondary,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: context.trText('Tutup panel darurat'),
                          onPressed: () => Navigator.of(context).pop(),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.textSecondary,
                            size: 21,
                          ),
                        ),
                      ],
                    ),

                    // Progres 3 tahap ringkas (hanya saat sinyal tercatat di server)
                    if (isServerStored &&
                        status != HikingSosStatus.cancelled) ...[
                      const SizedBox(height: 16),
                      _buildProgressStepper(
                        context,
                        result: result,
                        status: status ?? HikingSosStatus.savedToServer,
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Kartu koordinat tunggal tanpa pengulangan waktu
                    _buildLocationCard(context, _location),

                    const SizedBox(height: 16),

                    // Hirarki aksi jelas (maks. 2 tombol, tanpa tombol duplikat)
                    if (isServerStored) ...[
                      FilledButton.icon(
                        onPressed: _shareLocation,
                        icon: const Icon(
                          Icons.share_location_rounded,
                          size: 19,
                        ),
                        label: Text(
                          context.trText('Bagikan Lokasi Darurat'),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.onAccentPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.accentPrimary,
                          foregroundColor: context.onAccentPrimary,
                          minimumSize: const Size.fromHeight(50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      if (canCheckStatus) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed:
                              isBusy ? null : _refreshBackofficeStatusManual,
                          icon:
                              _isCheckingStatus
                                  ? SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.textPrimary,
                                    ),
                                  )
                                  : const Icon(Icons.sync_rounded, size: 17),
                          label: Text(
                            context.trText(
                              _isCheckingStatus
                                  ? 'Memeriksa status...'
                                  : 'Perbarui Status',
                            ),
                            style: AppFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textPrimary,
                            minimumSize: const Size.fromHeight(46),
                            side: BorderSide(
                              color: context.borderColor,
                              width: context.borderWidth,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      FilledButton.icon(
                        onPressed: isBusy ? null : _sendSosToBackoffice,
                        icon:
                            isBusy
                                ? SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        isHC ? context.bgPrimary : Colors.white,
                                  ),
                                )
                                : Icon(
                                  status == HikingSosStatus.queuedOffline
                                      ? Icons.refresh_rounded
                                      : Icons.send_rounded,
                                  size: 18,
                                ),
                        label: Text(
                          context.trText(
                            isBusy
                                ? 'Mengirim SOS ke server...'
                                : 'Kirim Ulang SOS',
                          ),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isHC ? context.bgPrimary : Colors.white,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.errorColor,
                          foregroundColor:
                              isHC ? context.bgPrimary : Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _shareLocation,
                        icon: const Icon(
                          Icons.share_location_rounded,
                          size: 18,
                        ),
                        label: Text(
                          context.trText('Bagikan lokasi'),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.textPrimary,
                          minimumSize: const Size.fromHeight(46),
                          side: BorderSide(
                            color: context.borderColor,
                            width: context.borderWidth,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      context.trText(
                        'Tutup panel tidak menghentikan tracking atau membatalkan SOS.',
                      ),
                      textAlign: TextAlign.center,
                      style: AppFonts.plusJakartaSans(
                        color: context.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _resolveStatusColor(BuildContext context, HikingSosStatus? status) {
    if (_isSubmitting || _isRetrying) return context.errorColor;
    return switch (status) {
      HikingSosStatus.savedToServer => context.successColor,
      HikingSosStatus.acknowledged => context.warningColor,
      HikingSosStatus.resolved => context.successColor,
      HikingSosStatus.cancelled => context.textSecondary,
      HikingSosStatus.queuedOffline => context.warningColor,
      HikingSosStatus.failed => context.errorColor,
      null => context.errorColor,
    };
  }

  String _headlineForStatus(BuildContext context, HikingSosStatus? status) {
    if (_isSubmitting || _isRetrying) {
      return context.trText('Mengirim Sinyal SOS...');
    }
    return switch (status) {
      HikingSosStatus.savedToServer => context.trText('Sinyal SOS Tersimpan'),
      HikingSosStatus.acknowledged => context.trText('Petugas SAR Menangani'),
      HikingSosStatus.resolved => context.trText('Penanganan SOS Selesai'),
      HikingSosStatus.cancelled => context.trText('SOS Dibatalkan'),
      HikingSosStatus.queuedOffline => context.trText('SOS Antre di Perangkat'),
      HikingSosStatus.failed => context.trText('SOS Gagal Dikirim'),
      null => context.trText('Bantuan darurat'),
    };
  }

  String? _subtitleForStatus(
    BuildContext context,
    HikingSosStatus? status,
    HikingSosResult? result,
  ) {
    if (_isSubmitting || _isRetrying) return null;
    return switch (status) {
      HikingSosStatus.savedToServer => context.trText(
        'Menunggu konfirmasi petugas SAR (BPBD/MDMC)',
      ),
      HikingSosStatus.acknowledged => context.trText(
        'Tim SAR telah menerima sinyal Anda',
      ),
      HikingSosStatus.queuedOffline => context.trText(
        'Akan dikirim otomatis saat koneksi kembali',
      ),
      HikingSosStatus.failed => _failureMessage(context, result),
      HikingSosStatus.resolved || HikingSosStatus.cancelled || null => null,
    };
  }

  Widget _buildProgressStepper(
    BuildContext context, {
    required HikingSosResult? result,
    required HikingSosStatus status,
  }) {
    final fmt = DateFormat('HH:mm');
    final sentTime =
        result?.createdAt != null ? fmt.format(result!.createdAt!.toLocal()) : null;
    final ackTime =
        result?.acknowledgedAt != null
            ? fmt.format(result!.acknowledgedAt!.toLocal())
            : null;
    final resolvedTime =
        result?.resolvedAt != null
            ? fmt.format(result!.resolvedAt!.toLocal())
            : null;

    final stepIndex = switch (status) {
      HikingSosStatus.resolved => 2,
      HikingSosStatus.acknowledged => 1,
      _ => 0,
    };
    final activeColor =
        status == HikingSosStatus.acknowledged
            ? context.warningColor
            : context.successColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepNode(
            context,
            label: context.trText('Terkirim'),
            time: sentTime,
            reached: stepIndex >= 0,
            current: stepIndex == 0,
            activeColor: context.successColor,
          ),
          _buildStepConnector(
            context,
            active: stepIndex >= 1,
            color: activeColor,
          ),
          _buildStepNode(
            context,
            label: context.trText('Ditangani'),
            time: ackTime,
            reached: stepIndex >= 1,
            current: stepIndex == 1,
            activeColor: activeColor,
          ),
          _buildStepConnector(
            context,
            active: stepIndex >= 2,
            color: context.successColor,
          ),
          _buildStepNode(
            context,
            label: context.trText('Selesai'),
            time: resolvedTime,
            reached: stepIndex >= 2,
            current: stepIndex == 2,
            activeColor: context.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(
    BuildContext context, {
    required String label,
    required String? time,
    required bool reached,
    required bool current,
    required Color activeColor,
  }) {
    final isHC = context.isHighContrast;
    final dotColor = reached ? activeColor : context.dividerColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                reached
                    ? dotColor
                    : (isHC ? context.bgPrimary : context.bgSurface),
            border: Border.all(
              color: reached ? dotColor : context.borderColor,
              width: current ? 2 : 1.4,
            ),
          ),
          child:
              reached
                  ? Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: isHC ? context.bgPrimary : Colors.white,
                  )
                  : null,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
            color: reached ? context.textPrimary : context.textTertiary,
          ),
        ),
        if (time != null)
          Text(
            time,
            style: AppFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }

  Widget _buildStepConnector(
    BuildContext context, {
    required bool active,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 6, right: 6),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: active ? color : context.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  String _failureMessage(
    BuildContext context,
    HikingSosResult? result,
  ) => switch (result?.failure) {
    HikingSosFailure.signInRequired => context.trText(
      'Masuk diperlukan untuk menyimpan SOS. Anda tetap dapat menelepon bantuan.',
    ),
    HikingSosFailure.sessionInactive => context.trText(
      'Sesi tracking tidak aktif sehingga SOS tidak dapat dicatat.',
    ),
    HikingSosFailure.locationUnavailable => context.trText(
      'Lokasi GPS terakhir tidak tersedia. Hubungi bantuan dan jelaskan posisi Anda.',
    ),
    HikingSosFailure.localStorageUnavailable => context.trText(
      'SOS gagal disimpan di perangkat. Hubungi bantuan secara langsung.',
    ),
    HikingSosFailure.none || null => context.trText(
      'SOS belum dapat disimpan. Anda tetap dapat menelepon bantuan.',
    ),
  };

  Widget _buildLocationCard(
    BuildContext context,
    HikingSosLocation? location,
  ) {
    if (location == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.borderColor,
            width: context.borderWidth,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_off_rounded,
              color: context.errorColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.trText('Lokasi GPS belum tersedia.'),
                style: AppFonts.plusJakartaSans(
                  color: context.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final age = DateTime.now().difference(location.recordedAt.toLocal());
    final isStale = age > const Duration(minutes: 2);
    final timePart =
        isStale
            ? _formatAge(context, age)
            : DateFormat('HH:mm').format(location.recordedAt.toLocal());
    final metaLine =
        location.accuracyMeters == null
            ? timePart
            : '±${location.accuracyMeters!.round()} m · $timePart';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isStale
                          ? context.trText('Koordinat Terakhir')
                          : context.trText('Koordinat GPS'),
                      style: AppFonts.plusJakartaSans(
                        color:
                            isStale
                                ? context.warningColor
                                : context.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.plusJakartaSans(
                          color:
                              isStale
                                  ? context.warningColor
                                  : context.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  style: AppFonts.plusJakartaSans(
                    color: context.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.trText('Salin koordinat'),
            onPressed: () => unawaited(_copyCoordinates(location)),
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAge(BuildContext context, Duration age) {
    if (age.isNegative || age.inSeconds < 30) {
      return context.trTextSafe('Baru saja');
    }
    if (age.inMinutes < 1) {
      return '${age.inSeconds} ${context.trTextSafe('detik lalu')}';
    }
    if (age.inHours < 1) {
      return '${age.inMinutes} ${context.trTextSafe('menit lalu')}';
    }
    if (age.inDays < 1) {
      return '${age.inHours} ${context.trTextSafe('jam lalu')}';
    }
    return '${age.inDays} ${context.trTextSafe('hari lalu')}';
  }

  Future<void> _shareLocation() async {
    final location = _location;
    if (location == null) {
      _showMessage(
        context.trTextSafe('Lokasi GPS belum tersedia untuk dibagikan.'),
      );
      return;
    }
    final latitude = location.latitude.toStringAsFixed(6);
    final longitude = location.longitude.toStringAsFixed(6);
    final timestamp = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(location.recordedAt.toLocal());
    final mapLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final text = [
      'SOS SIGUMI - ${context.trTextSafe('Pendakian membutuhkan bantuan')}',
      '${context.trTextSafe('Koordinat')}: $latitude, $longitude',
      '${context.trTextSafe('Waktu lokasi')}: $timestamp (${_formatAge(context, DateTime.now().difference(location.recordedAt.toLocal()))})',
      '${context.trTextSafe('Status SOS')}: ${_shareStatus(context)}',
      mapLink,
    ].join('\n');
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: context.trTextSafe('Lokasi SOS SIGUMI'),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage(context.trTextSafe('Lokasi gagal dibagikan.'));
      }
    }
  }

  String _shareStatus(BuildContext context) {
    final result = _effectiveResult;
    if (_isSubmitting) return context.trTextSafe('Sedang dikirim');
    final status =
        result != null && result.isServerStored
            ? result.status
            : (result?.alertId != null &&
                widget.tracking.wasSosUploaded(result!.alertId!))
            ? HikingSosStatus.savedToServer
            : result?.status;
    return switch (status) {
      HikingSosStatus.savedToServer => context.trTextSafe(
        'Tersimpan di server; menunggu konfirmasi petugas SAR',
      ),
      HikingSosStatus.acknowledged => context.trTextSafe(
        'Sedang ditangani petugas SAR (BPBD/MDMC)',
      ),
      HikingSosStatus.resolved => context.trTextSafe(
        'Penanganan SOS telah selesai',
      ),
      HikingSosStatus.cancelled => context.trTextSafe('Dibatalkan'),
      HikingSosStatus.queuedOffline => context.trTextSafe('Menunggu koneksi'),
      HikingSosStatus.failed => context.trTextSafe('Belum dapat disimpan'),
      null => context.trTextSafe('Sedang dikirim'),
    };
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
