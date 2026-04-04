import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _makeCall(BuildContext context, Map<String, String> contact) async {
    // Memberikan feedback getaran sebelum melakukan aksi
    HapticFeedback.lightImpact();

    // Tampilkan konfirmasi agar tidak salah tekan
    final bool confirm = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _CallConfirmationSheet(contact: contact),
        ) ??
        false;

    if (confirm) {
      HapticFeedback.heavyImpact();
      final uri = Uri.parse('tel:${contact['phone']}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = AppConstants.emergencyContacts;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Nomor Darurat',
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Search / Filter info (Optional visual guide)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Ketuk kartu untuk detail atau tekan tombol telepon untuk segera menghubungi petugas.',
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
          ),

          // List of Emergency Cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final contact = contacts[index];
                  return _EmergencyCard(
                    contact: contact,
                    index: index,
                    onCall: () => _makeCall(context, contact),
                  );
                },
                childCount: contacts.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final Map<String, String> contact;
  final int index;
  final VoidCallback onCall;

  const _EmergencyCard({
    required this.contact,
    required this.index,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final String name = contact['name'] ?? '';
    final String phone = contact['phone'] ?? '';
    final String desc = contact['desc'] ?? '';

    // Color and Icon Logic based on service type
    Color accentColor = SigumiTheme.primaryBlue;
    IconData serviceIcon = Icons.emergency;

    if (name.contains('PMI') || name.contains('Ambulans')) {
      accentColor = Colors.red.shade600;
      serviceIcon = Icons.health_and_safety;
    } else if (name.contains('Polisi')) {
      accentColor = Colors.blue.shade800;
      serviceIcon = Icons.local_police;
    } else if (name.contains('Damkar')) {
      accentColor = Colors.orange.shade800;
      serviceIcon = Icons.fire_truck;
    } else if (name.contains('BNPB') || name.contains('BPBD') || name.contains('Posko')) {
      accentColor = Colors.deepOrange.shade800;
      serviceIcon = Icons.warning_amber_rounded;
    } else if (name.contains('PLN')) {
      accentColor = Colors.amber.shade900;
      serviceIcon = Icons.electric_bolt_rounded;
    } else if (name.contains('SAR')) {
      accentColor = Colors.teal.shade700;
      serviceIcon = Icons.waves;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCall,
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nomor $phone disalin ke papan klip'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Icon and side accent
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(serviceIcon, color: accentColor, size: 28),
                    ),
                    const SizedBox(width: 16),

                    // Text Content
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: AppFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            phone,
                            style: AppFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(width: 1, indent: 8, endIndent: 8),

                    // Large Side Button for Call
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Material(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: onCall,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            child: Icon(Icons.call, color: accentColor, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 500.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

class _CallConfirmationSheet extends StatelessWidget {
  final Map<String, String> contact;

  const _CallConfirmationSheet({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call, color: Colors.red, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Konfirmasi Panggilan',
            style: AppFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppFonts.plusJakartaSans(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Apakah Anda yakin ingin menghubungi\n'),
                TextSpan(
                  text: contact['name'],
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                TextSpan(text: ' di '),
                TextSpan(
                  text: contact['phone'],
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'HUBUNGI SEKARANG',
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

