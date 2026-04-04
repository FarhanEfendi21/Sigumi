import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../models/report_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _descController = TextEditingController();
  final Set<String> _selectedCategories = {};
  bool _isSubmitting = false;
  bool _isWithinRadius = true;
  double _userDistance = 0;

  // Image handling
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  void _checkLocation() {
    final loc = context.read<LocationService>();
    _userDistance = loc.distanceFromVolcano;
    _isWithinRadius = AiService.isWithinReportRadius(
      loc.userLat,
      loc.userLng,
      AppConstants.reportMaxRadius,
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
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
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
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

  void _submitReport() {
    if (_selectedCategories.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua field sebelum mengirim laporan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isWithinRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda berada ${_userDistance.toStringAsFixed(1)} km dari Merapi. Laporan hanya dapat dikirim dalam radius ${AppConstants.reportMaxRadius.toInt()} km.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedImage = null; // Clear active image
        });
        _descController.clear();
        _selectedCategories.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Laporan berhasil dikirim! Terima kasih.'),
            backgroundColor: SigumiTheme.statusNormal,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Kejadian')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          100,
        ), // Extra bottom padding for BottomNav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI radius info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    _isWithinRadius
                        ? SigumiTheme.statusNormal.withValues(alpha: 0.08)
                        : SigumiTheme.statusAwas.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _isWithinRadius
                          ? SigumiTheme.statusNormal.withValues(alpha: 0.3)
                          : SigumiTheme.statusAwas.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isWithinRadius ? Icons.check_circle : Icons.warning_amber,
                    color:
                        _isWithinRadius
                            ? SigumiTheme.statusNormal
                            : SigumiTheme.statusAwas,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isWithinRadius
                              ? 'Lokasi terverifikasi'
                              : 'Di luar radius laporan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color:
                                _isWithinRadius
                                    ? SigumiTheme.statusNormal
                                    : SigumiTheme.statusAwas,
                          ),
                        ),
                        Text(
                          'Jarak Anda: ${_userDistance.toStringAsFixed(1)} km dari Merapi (maks ${AppConstants.reportMaxRadius.toInt()} km)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 12),
            // AI filter explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.smart_toy,
                    color: SigumiTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI memfilter laporan berdasarkan lokasi GPS Anda. Hanya laporan dalam radius ${AppConstants.reportMaxRadius.toInt()} km dari gunung berapi yang diterima.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SigumiTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Kategori Kejadian',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  ReportModel.categories.map((cat) {
                    final isSelected = _selectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(cat);
                          } else {
                            _selectedCategories.remove(cat);
                          }
                        });
                      },
                      selectedColor: SigumiTheme.primaryBlue.withAlpha(40),
                      checkmarkColor: SigumiTheme.primaryBlue,
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? SigumiTheme.primaryBlue
                                : SigumiTheme.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 24),
            Text(
              'Foto Kondisi Saat Ini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: SigumiTheme.primaryBlue.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SigumiTheme.primaryBlue.withValues(alpha: 0.3),
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
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SigumiTheme.primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: SigumiTheme.primaryBlue,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Ketuk untuk memilih foto',
                              style: TextStyle(
                                color: SigumiTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Kondisi lapangan / abu vulkanik',
                              style: TextStyle(
                                color: SigumiTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),
            Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ceritakan apa yang Anda lihat atau alami...',
              ),
            ),

            const SizedBox(height: 16),
            // Location info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SigumiTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: SigumiTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lokasi: ${context.read<LocationService>().userLat.toStringAsFixed(4)}, ${context.read<LocationService>().userLng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Text(
                    'GPS Auto',
                    style: TextStyle(
                      fontSize: 11,
                      color: SigumiTheme.statusNormal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed:
                    _isWithinRadius && !_isSubmitting ? _submitReport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SigumiTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: SigumiTheme.primaryBlue.withValues(
                    alpha: 0.5,
                  ),
                  disabledForegroundColor: Colors.white70,
                  elevation: 6, // Adding shadow for prominent button
                  shadowColor: SigumiTheme.primaryBlue.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                icon:
                    _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.send_rounded, size: 22),
                label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Laporan'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
