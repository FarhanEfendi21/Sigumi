import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../models/report_model.dart';
import '../../repositories/report_repository.dart';

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
        print('📷 Image selected: ${_selectedImage!.name}');
        // Generate temporary report ID untuk folder
        final tempReportId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        try {
          imageUrl = await reportRepository.uploadReportImage(
            _selectedImage!,
            tempReportId,
          );
          print('📷 Image URL after upload: $imageUrl');
        } catch (e) {
          print('⚠️ Skipping image upload: $e');
          // Continue tanpa gambar
        }
      } else {
        print('📷 No image selected');
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

      print('📝 Submitting report data...');
      print('   reporterName: $reporterName');
      print('   category: ${reportData['category']}');
      print('   imageUrl: $imageUrl');

      // Simpan laporan ke Supabase
      final response = await reportRepository.createReport(
        reporterName: reportData['reporterName'] as String,
        phone: reportData['phone'] as String?,
        category: reportData['category'] as String,
        title: reportData['title'] as String,
        description: reportData['description'] as String,
        location: reportData['location'] as String?,
        imageUrl: reportData['imageUrl'] as String?,
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
        print('✅ Showing success notification...');
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.teal.shade500,
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
                        color: const Color(0xFF1E1E2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Terima kasih telah melaporkan.\nLaporan Anda akan kami verifikasi.',
                      textAlign: TextAlign.center,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF6B6B78),
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
                          backgroundColor: Colors.teal.shade500,
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
                            color: Colors.white,
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
        print('⚠️ Error showing dialog: $e');
      }
    } catch (e) {
      if (!mounted) return;

      print('❌ Error submitting report: $e');

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
        print('❌ Error showing snackbar: $e');
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
            color: const Color(0xFF1E1E2C),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B6B78),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Lapor Kejadian',
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1E1E2C),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
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
                        ? Colors.teal.withValues(alpha: 0.05)
                        : Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isWithinRadius
                          ? Colors.teal.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isWithinRadius
                              ? Colors.teal.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWithinRadius
                          ? Icons.my_location_rounded
                          : Icons.location_off_rounded,
                      color: isWithinRadius ? Colors.teal : Colors.red,
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
                            color: const Color(0xFF1E1E2C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Jarak Anda: ${userDistance.toStringAsFixed(1)} km dari ${loc.nearestVolcanoName}',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF6B6B78),
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
            Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children:
                      ReportModel.categories.map((cat) {
                        final isSelected = _selectedCategories.contains(cat);
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
                                      ? SigumiTheme.primaryBlue
                                      : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? SigumiTheme.primaryBlue
                                        : const Color(0xFFE5E7EB),
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
                                        ? Colors.white
                                        : const Color(0xFF4B4B5C),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
            GestureDetector(
                  onTap: _pickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _selectedImage != null
                                ? Colors.transparent
                                : const Color(0xFFE5E7EB),
                        width: 1.5,
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
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_rounded,
                                    color: Color(0xFF9E9EAE),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ambil foto dari kamera',
                                  style: AppFonts.plusJakartaSans(
                                    color: const Color(0xFF1E1E2C),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Foto langsung dari kamera untuk verifikasi',
                                  style: AppFonts.plusJakartaSans(
                                    color: const Color(0xFF9E9EAE),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
            Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: _descController,
                    maxLines: 5,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF1E1E2C),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Misal: Terdapat hujan abu tipis di desa...',
                      hintStyle: AppFonts.plusJakartaSans(
                        color: const Color(0xFF9E9EAE),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
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
                        isWithinRadius && !_isSubmitting
                            ? _submitReport
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SigumiTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
                      disabledForegroundColor: const Color(0xFF9E9EAE),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
