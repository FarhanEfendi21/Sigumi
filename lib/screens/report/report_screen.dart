import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme_extensions.dart';
import '../../config/constants.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../models/report_model.dart';
import '../../repositories/report_repository.dart';
import '../../utils/logger.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _descController = TextEditingController();
  final Set<String> _selectedCategories = {};
  bool _isSubmitting = false;

  // Image handling
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Mapping nama gunung ke lokasi
  static const Map<String, String> volcanoToLokasi = {
    'Gunung Merapi': 'Yogyakarta',
    'Gunung Agung': 'Bali',
    'Gunung Rinjani': 'Lombok',
  };

  /// Convert nama gunung ke lokasi (Yogyakarta/Bali/Lombok)
  String? _getLokasiFromVolcano(String volcaneName) {
    return volcanoToLokasi[volcaneName];
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuka kamera: $e',
              style: AppFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    // Validasi awal
    if (_selectedCategories.isEmpty || _descController.text.isEmpty) {
      if (!mounted) return;
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pilih kategori dan isi deskripsi terlebih dahulu',
              style: AppFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        // Ignore if context is invalid
      }
      return;
    }

    final locationService = context.read<LocationService>();
    final isWithinReqRadius = AiService.isWithinReportRadius(
      locationService.userLat,
      locationService.userLng,
      AppConstants.reportMaxRadius,
    );

    if (!isWithinReqRadius) {
      if (!mounted) return;
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Laporan hanya dapat dikirim dari dalam radius ${AppConstants.reportMaxRadius.toInt()} km.',
              style: AppFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        // Ignore if context is invalid
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reportRepository = ReportRepository();

      // Upload gambar ke Supabase jika ada (optional, continue jika gagal)
      String? imageUrl;
      if (_selectedImage != null) {
        Logger.info('Image selected: ${_selectedImage!.name}', tag: 'ReportScreen');
        // Generate temporary report ID untuk folder
        final tempReportId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        try {
          imageUrl = await reportRepository.uploadReportImage(
            _selectedImage!,
            tempReportId,
          );
          Logger.info('Image URL after upload: $imageUrl', tag: 'ReportScreen');
        } catch (e) {
          Logger.log('Skipping image upload: $e', tag: 'ReportScreen');
          // Continue tanpa gambar
        }
      } else {
        Logger.info('No image selected', tag: 'ReportScreen');
      }

      // Siapkan data laporan
      // Ambil nama reporter dari user yang login
      final currentUser = Supabase.instance.client.auth.currentUser;
      final reporterName =
          (currentUser?.userMetadata?['full_name'] as String?) ??
          currentUser?.email ??
          'Pengguna Sigumi';

      final reportData = {
        'reporterName': reporterName,
        'phone': null,
        'category': _selectedCategories.join(', '),
        'title':
            '${_selectedCategories.first} - ${DateTime.now().toLocal().toString().split('.')[0]}',
        'description': _descController.text,
        'location':
            'Lat: ${locationService.userLat.toStringAsFixed(4)}, Lng: ${locationService.userLng.toStringAsFixed(4)}',
        'imageUrl': imageUrl,
      };

      Logger.info('Submitting report data...', tag: 'ReportScreen');
      Logger.log('reporterName: $reporterName', tag: 'ReportScreen');
      Logger.log('category: ${reportData['category']}', tag: 'ReportScreen');
      Logger.log('imageUrl: $imageUrl', tag: 'ReportScreen');

      // Ambil lokasi dari nama gunung aktif
      final lokasiFromVolcano = _getLokasiFromVolcano(
        locationService.activeVolcanoName,
      );

      // Simpan laporan ke Supabase
      await reportRepository.createReport(
        reporterName: reportData['reporterName']!,
        phone: reportData['phone'],
        category: reportData['category']!,
        title: reportData['title']!,
        description: reportData['description']!,
        location: reportData['location'],
        imageUrl: reportData['imageUrl'],
        lokasi: lokasiFromVolcano,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _selectedImage = null;
      });
      _descController.clear();
      _selectedCategories.clear();

      if (!mounted) return;

      try {
        Logger.success('Showing success notification...', tag: 'ReportScreen');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.bgPrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.borderColor,
                    width: context.borderWidth,
                  ),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.successColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: context.successColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Laporan Berhasil!',
                      textAlign: TextAlign.center,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Terima kasih telah melaporkan.\nLaporan Anda akan kami verifikasi.',
                      textAlign: TextAlign.center,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.successColor,
                          foregroundColor: context.isHighContrast ? context.bgPrimary : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Tutup',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } catch (e) {
        Logger.log('Error showing dialog: $e', tag: 'ReportScreen');
      }
    } catch (e) {
      if (!mounted) return;

      Logger.error('Error submitting report', tag: 'ReportScreen', error: e);

      setState(() => _isSubmitting = false);

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gagal mengirim laporan: ${e.toString()}',
                    style: AppFonts.plusJakartaSans(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        // Ignore if context is invalid
        Logger.error('Error showing snackbar', tag: 'ReportScreen', error: e);
      }
    }
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.plusJakartaSans(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationService>();
    final userDistance = loc.distanceFromVolcano;
    final isWithinRadius = AiService.isWithinReportRadius(
      loc.userLat,
      loc.userLng,
      AppConstants.reportMaxRadius,
    );

    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: AppBar(
        title: Text(
          'Lapor Kejadian',
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: context.textPrimary,
          ),
        ),
        backgroundColor: context.bgPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Location & AI Status Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isWithinRadius
                        ? context.successColor.withValues(alpha: 0.1)
                        : context.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isWithinRadius
                          ? context.successColor
                          : context.errorColor,
                  width: context.borderWidth,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isWithinRadius
                              ? context.successColor.withValues(alpha: 0.2)
                              : context.errorColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWithinRadius
                          ? Icons.my_location_rounded
                          : Icons.location_off_rounded,
                      color: isWithinRadius ? context.successColor : context.errorColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWithinRadius
                              ? 'Lokasi Laporan Valid'
                              : 'Di Luar Radius Pelaporan',
                          style: AppFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Jarak Anda: ${userDistance.toStringAsFixed(1)} km dari ${loc.nearestVolcanoName}',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 32),

            // ── Kategori Kejadian ──
            _buildSectionTitle(
              'Kategori Kejadian',
              subtitle: 'Pilih satu atau lebih kejadian yang terjadi',
            ),
            const SizedBox(height: 14),
            Opacity(
                  opacity: isWithinRadius ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !isWithinRadius,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children:
                          ReportModel.categories.map((cat) {
                            final isSelected = _selectedCategories.contains(
                              cat,
                            );
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCategories.remove(cat);
                                  } else {
                                    _selectedCategories.add(cat);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? context.accentPrimary
                                          : context.bgSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? context.accentPrimary
                                            : context.borderColor,
                                    width: context.borderWidth,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? (context.isHighContrast ? context.bgPrimary : Colors.white)
                                            : context.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 32),

            // ── Foto Lampiran ──
            _buildSectionTitle(
              'Foto Kondisi Saat Ini',
              subtitle: 'Bantu tim verifikasi dengan bukti visual',
            ),
            const SizedBox(height: 14),
            Opacity(
                  opacity: isWithinRadius ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !isWithinRadius,
                    child: GestureDetector(
                      onTap: isWithinRadius ? _pickImage : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: context.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _selectedImage != null
                                    ? Colors.transparent
                                    : context.borderColor,
                            width: context.borderWidth,
                          ),
                        ),
                        child:
                            _selectedImage != null
                                ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child:
                                          kIsWeb
                                              ? Image.network(
                                                _selectedImage!.path,
                                                fit: BoxFit.cover,
                                              )
                                              : Image.file(
                                                File(_selectedImage!.path),
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImage = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: context.bgPrimary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.borderColor,
                                          width: context.borderWidth,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_a_photo_rounded,
                                        color: context.textTertiary,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Ambil foto dari kamera',
                                      style: AppFonts.plusJakartaSans(
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Foto langsung dari kamera untuk verifikasi',
                                      style: AppFonts.plusJakartaSans(
                                        color: context.textTertiary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 32),

            // ── Deskripsi ──
            _buildSectionTitle(
              'Deskripsi Laporan',
              subtitle: 'Ceritakan detail kejadian dengan singkat dan jelas',
            ),
            const SizedBox(height: 14),
            Opacity(
                  opacity: isWithinRadius ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !isWithinRadius,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.borderColor,
                          width: context.borderWidth,
                        ),
                      ),
                      child: TextField(
                        enabled: isWithinRadius,
                        controller: _descController,
                        maxLines: 5,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Misal: Terdapat hujan abu tipis di desa...',
                          hintStyle: AppFonts.plusJakartaSans(
                            color: context.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 40),

            // ── Submit Button ──
            SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        isWithinRadius && !_isSubmitting ? _submitReport : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentPrimary,
                      foregroundColor: context.isHighContrast ? context.bgPrimary : Colors.white,
                      disabledBackgroundColor: context.bgSurface,
                      disabledForegroundColor: context.textTertiary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: context.borderColor,
                          width: context.borderWidth,
                        ),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Kirim Laporan',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
          ],
        ),
      ),
    );
  }
}
