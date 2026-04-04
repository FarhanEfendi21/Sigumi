import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../config/theme.dart';
import '../../providers/volcano_provider.dart';
import '../../services/location_service.dart';

class EvacuationScreen extends StatefulWidget {
  const EvacuationScreen({super.key});

  @override
  State<EvacuationScreen> createState() => _EvacuationScreenState();
}

class _EvacuationScreenState extends State<EvacuationScreen> {
  @override
  void initState() {
    super.initState();
    // Memastikan lokasi diperbarui saat layar ini dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().refreshLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
        title: const Text(
          'Titik Aman Evakuasi',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1E1E2C),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E1E2C), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),
      body: Consumer2<VolcanoProvider, LocationService>(
        builder: (context, volcanoProvider, locService, _) {
          final volcano = volcanoProvider.volcano;
          final distance = locService.distanceFromVolcano;
          final zoneLevel = locService.zoneLevel;
          final zoneLabel = locService.zoneLabel;
          final statusColor = SigumiTheme.getStatusColor(zoneLevel);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Realtime Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.radar_rounded,
                              color: statusColor,
                              size: 18,
                            ).animate(onPlay: (c) => c.repeat()).shimmer(
                              duration: 2000.ms,
                              color: statusColor.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor.withAlpha(50)),
                                  ),
                                  child: Text(
                                    zoneLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Jarak dari ${volcano.name}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: SigumiTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            distance.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: SigumiTheme.textPrimary,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'KM',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: SigumiTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, end: 0).fadeIn(),

                const SizedBox(height: 32),

                // Panduan Evakuasi
                const Text(
                  'Panduan Keselamatan Darurat',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SigumiTheme.textPrimary,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),

                _buildGuidelineCard(
                  icon: Icons.directions_run_rounded,
                  title: 'Tetap Tenang & Waspada',
                  description:
                      'Ikuti arahan dari petugas berwenang (BPBD/Basarnas). Jangan panik agar bisa berpikir jernih.',
                  color: const Color(0xFF3B82F6),
                  delay: 200,
                ),
                _buildGuidelineCard(
                  icon: Icons.masks_rounded,
                  title: 'Gunakan Masker & Pelindung',
                  description:
                      'Jika terjadi hujan abu, segera pakai masker medis/kain basah dan kacamata pelindung.',
                  color: const Color(0xFFF97316),
                  delay: 300,
                ),
                _buildGuidelineCard(
                  icon: Icons.landscape_rounded,
                  title: 'Jauhi Bantaran Sungai',
                  description:
                      'Hindari lembah dan sungai yang berhulu di gunung untuk menghindari bahaya lahar dingin.',
                  color: const Color(0xFFA16207),
                  delay: 400,
                ),
                _buildGuidelineCard(
                  icon: Icons.local_hospital_rounded,
                  title: 'Pusat Evakuasi',
                  description:
                      'Gunakan menu Posko & Faskes di halaman utama untuk mencari lokasi aman yang terverifikasi dan mendapat bantuan prioritas.',
                  color: const Color(0xFFEF4444),
                  delay: 500,
                ),

                const SizedBox(height: 32),
                
                // Refresh Button
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: () {
                      context.read<LocationService>().refreshLocation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Memperbarui lokasi...', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text('Perbarui Lokasi Terkini', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600)),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuidelineCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: SigumiTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: SigumiTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }
}
