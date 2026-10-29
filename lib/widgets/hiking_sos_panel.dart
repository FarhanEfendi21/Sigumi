import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/fonts.dart';
import '../config/theme_extensions.dart';
import '../models/emergency_contact.dart';
import '../models/hiking_sos.dart';
import '../providers/volcano_provider.dart';
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
  HikingSosResult? _result;
  late HikingSosLocation? _location;

  @override
  void initState() {
    super.initState();
    _location = widget.tracking.lastRecordedSosLocation;
    _submitSos();
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

  Future<void> _retrySos() async {
    final alertId = _result?.alertId;
    if (alertId == null || _isRetrying) return;
    setState(() => _isRetrying = true);
    final uploaded = await widget.tracking.retryPendingSos(alertId);
    if (!mounted) return;
    setState(() {
      _isRetrying = false;
      if (uploaded && _result != null) {
        _result = HikingSosResult(
          status: HikingSosStatus.savedToServer,
          alertId: alertId,
          location: _location,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tracking,
      builder: (context, _) {
        final result = _result;
        final wasUploaded =
            result?.alertId != null &&
            widget.tracking.wasSosUploaded(result!.alertId!);
        final status =
            wasUploaded ? HikingSosStatus.savedToServer : result?.status;
        final background = context.bgSurface;
        final foreground = context.textPrimary;
        final muted = context.textSecondary;
        final statusColor = switch (status) {
          HikingSosStatus.savedToServer => context.successColor,
          HikingSosStatus.queuedOffline => const Color(0xFFB45309),
          HikingSosStatus.failed => context.errorColor,
          null => context.accentPrimary,
        };

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: context.borderColor),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: muted.withAlpha(90),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.errorColor.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sos_rounded,
                            color: context.errorColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.trText('Bantuan darurat'),
                            style: AppFonts.plusJakartaSans(
                              color: foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.trText('Tutup panel darurat'),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close_rounded, color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildStatusCard(context, status, result, statusColor),
                    const SizedBox(height: 12),
                    _buildLocationCard(context, _location, foreground, muted),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _chooseEmergencyContact,
                        icon: const Icon(Icons.call_rounded),
                        label: Text(context.trText('Kirim sinyal ke backoffice')),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.errorColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _shareLocation,
                        icon: const Icon(Icons.share_location_rounded),
                        label: Text(context.trText('Bagikan lokasi')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.accentPrimary,
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(color: context.borderColor),
                        ),
                      ),
                    ),
                    if (!_isSubmitting &&
                        result?.status == HikingSosStatus.queuedOffline &&
                        result?.alertId != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _isRetrying ? null : _retrySos,
                        icon:
                            _isRetrying
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.refresh_rounded),
                        label: Text(context.trText('Coba kirim lagi')),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      context.trText(
                        'Tutup panel tidak menghentikan tracking atau membatalkan SOS.',
                      ),
                      textAlign: TextAlign.center,
                      style: AppFonts.plusJakartaSans(
                        color: muted,
                        fontSize: 10.5,
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

  Widget _buildStatusCard(
    BuildContext context,
    HikingSosStatus? status,
    HikingSosResult? result,
    Color statusColor,
  ) {
    final statusText =
        _isSubmitting
            ? context.trText('Mengirim SOS ke server...')
            : switch (status) {
              HikingSosStatus.savedToServer => context.trText(
                'SOS tersimpan di server. Penerimaan oleh petugas belum dikonfirmasi.',
              ),
              HikingSosStatus.queuedOffline => context.trText(
                'SOS tersimpan di perangkat. Pengiriman ke server tertunda.',
              ),
              HikingSosStatus.failed => _failureMessage(context, result),
              null => context.trText('Menyiapkan informasi SOS...'),
            };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isSubmitting)
            SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else
            Icon(
              status == HikingSosStatus.savedToServer
                  ? Icons.cloud_done_rounded
                  : status == HikingSosStatus.queuedOffline
                  ? Icons.cloud_off_rounded
                  : Icons.info_outline_rounded,
              color: statusColor,
              size: 20,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              statusText,
              style: AppFonts.plusJakartaSans(
                color: context.textPrimary,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
    Color foreground,
    Color muted,
  ) {
    if (location == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off_rounded, color: context.errorColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.trText('Lokasi GPS belum tersedia.'),
                style: TextStyle(color: foreground, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final age = DateTime.now().difference(location.recordedAt.toLocal());
    final isStale = age > const Duration(minutes: 2);
    final ageLabel = _formatAge(context, age);
    final timeLabel = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(location.recordedAt.toLocal());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: isStale ? const Color(0xFFB45309) : context.successColor,
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  isStale
                      ? context.trText('Lokasi GPS terakhir')
                      : context.trText('Lokasi GPS'),
                  style: AppFonts.plusJakartaSans(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                ageLabel,
                style: AppFonts.plusJakartaSans(
                  color: isStale ? const Color(0xFFB45309) : muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            style: AppFonts.plusJakartaSans(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            location.accuracyMeters == null
                ? '${context.trText('Waktu lokasi')}: $timeLabel'
                : '${context.trText('Waktu lokasi')}: $timeLabel · ±${location.accuracyMeters!.round()} m',
            style: AppFonts.plusJakartaSans(color: muted, fontSize: 10),
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

  Future<void> _chooseEmergencyContact() async {
    final provider = context.read<VolcanoProvider>();
    if (provider.emergencyContacts.isEmpty) {
      await provider.fetchEmergencyContacts();
    }
    if (!mounted) return;
    final region = switch (widget.tracking.trackingRegion) {
      'bali' => 'Bali',
      'lombok' => 'Lombok',
      _ => provider.selectedRegion,
    };
    final contacts =
        provider.emergencyContacts.where((contact) {
          final contactRegion = contact.region.trim().toLowerCase();
          return contact.isActive &&
              (contactRegion == 'nasional' ||
                  contactRegion == region.toLowerCase());
        }).toList();
    if (contacts.isEmpty) {
      _showMessage(context.trTextSafe('Kontak darurat belum tersedia.'));
      return;
    }

    final contact = await showModalBottomSheet<EmergencyContact>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.bgSurface,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.65;
        return SizedBox(
          height: maxHeight,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        sheetContext.trText('Pilih kontak darurat'),
                        style: AppFonts.plusJakartaSans(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.borderColor),
              Expanded(
                child: ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder:
                      (_, _) => Divider(
                        height: 1,
                        indent: 58,
                        color: context.borderColor,
                      ),
                  itemBuilder: (context, index) {
                    final item = contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.accentColor.withAlpha(20),
                        child: Icon(item.serviceIcon, color: item.accentColor),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${item.phone} · ${item.region}',
                        style: TextStyle(color: context.textSecondary),
                      ),
                      trailing: const Icon(Icons.call_rounded),
                      onTap: () => Navigator.pop(sheetContext, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || contact == null) return;

    final phone = contact.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: phone);
    final callUnavailableMessage = context.trTextSafe(
      'Panggilan tidak dapat dibuka di perangkat ini.',
    );
    try {
      if (!await canLaunchUrl(uri) || !await launchUrl(uri)) {
        _showMessage(callUnavailableMessage);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(callUnavailableMessage);
      }
    }
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
    final result = _result;
    if (_isSubmitting) return context.trTextSafe('Sedang dikirim');
    if (result?.alertId != null &&
        widget.tracking.wasSosUploaded(result!.alertId!)) {
      return context.trTextSafe(
        'Tersimpan di server; penerimaan belum terkonfirmasi',
      );
    }
    return switch (result?.status) {
      HikingSosStatus.savedToServer => context.trTextSafe(
        'Tersimpan di server; penerimaan belum terkonfirmasi',
      ),
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
