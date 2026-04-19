import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sigumi/config/fonts.dart';
import '../../config/theme.dart';
import '../../models/emergency_contact.dart';
import '../../providers/volcano_provider.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolcanoProvider>().fetchEmergencyContacts();
    });
  }

  Future<void> _makeCall(EmergencyContact contact) async {
    HapticFeedback.lightImpact();

    final bool confirm =
        await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _CallConfirmationSheet(contact: contact),
        ) ??
        false;

    if (confirm) {
      HapticFeedback.heavyImpact();
      final uri = Uri.parse('tel:${contact.phone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final allContacts = provider.emergencyContacts;
        final isLoading = provider.isLoadingContacts;
        final region = provider.selectedRegion;

        // Hitung total halaman
        final int totalItems = allContacts.length;
        final int totalPages = max(1, (totalItems / _itemsPerPage).ceil());

        // Pastikan _currentPage tidak melebihi total halaman (jika data berubah)
        if (_currentPage > totalPages) {
          _currentPage = totalPages;
        }

        // Ambil data sesuai pagination
        final int startIndex = (_currentPage - 1) * _itemsPerPage;
        int endIndex = startIndex + _itemsPerPage;
        if (endIndex > totalItems) {
          endIndex = totalItems;
        }
        
        final pagedContacts = isLoading || allContacts.isEmpty 
            ? <EmergencyContact>[] 
            : allContacts.sublist(startIndex, endIndex);

        return Scaffold(
          backgroundColor: Colors.white, // CLean white background
          appBar: AppBar(
            title: Text(
              'Nomor Darurat',
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF1E1E2C),
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1E1E2C),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: Colors.grey.shade100, height: 1),
            ),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header Info Region ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Menampilkan data darurat untuk area ',
                            ),
                            TextSpan(
                              text: region,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: SigumiTheme.primaryBlue,
                              ),
                            ),
                            const TextSpan(
                              text: ' dan Nasional.',
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                    ],
                  ),
                ),
              ),

              // ── Loading State ──
              if (isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _LoadingCard(index: i),
                      childCount: 5,
                    ),
                  ),
                )

              // ── Empty State ──
              else if (allContacts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    onRetry: () => provider.fetchEmergencyContacts(),
                  ),
                )

              // ── List Kontak (Paged) ──
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final contact = pagedContacts[index];
                        return _EmergencyCard(
                          contact: contact,
                          index: index,
                          onCall: () => _makeCall(contact),
                        );
                      },
                      childCount: pagedContacts.length,
                    ),
                  ),
                ),

                // ── Pagination Controls ──
                if (!isLoading && allContacts.isNotEmpty && totalPages > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Btn Prev
                          _PaginationButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            label: 'Seb',
                            isActive: _currentPage > 1,
                            onTap: () {
                              if (_currentPage > 1) {
                                setState(() => _currentPage--);
                              }
                            },
                          ),
                          // Indicator
                          Text(
                            'Halaman $_currentPage dari $totalPages',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          // Btn Next
                          _PaginationButton(
                            icon: Icons.arrow_forward_ios_rounded,
                            label: 'Sel',
                            isIconRight: true,
                            isActive: _currentPage < totalPages,
                            onTap: () {
                              if (_currentPage < totalPages) {
                                setState(() => _currentPage++);
                              }
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────
// KOMPONEN PAGINATION BUTTON
// ────────────────────────────────────────────────────────────────
class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isIconRight;

  const _PaginationButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isIconRight = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = isActive ? const Color(0xFF1E1E2C) : Colors.grey.shade400;
    Color bgColor = isActive ? Colors.grey.shade100 : Colors.transparent;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.black.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isIconRight) ...[
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              if (isIconRight) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 14, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// ────────────────────────────────────────────────────────────────
// CARD KONTAK YANG CLEAN & MINIMALIS
// ────────────────────────────────────────────────────────────────
class _EmergencyCard extends StatelessWidget {
  final EmergencyContact contact;
  final int index;
  final VoidCallback onCall;

  const _EmergencyCard({
    required this.contact,
    required this.index,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = contact.accentColor;
    final serviceIcon = contact.serviceIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCall,
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: contact.phone));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nomor ter-copy: ${contact.phone}'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ── Teks Utama ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _CategoryBadge(contact: contact),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                contact.name,
                                style: AppFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: const Color(0xFF1A1A1A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          contact.description,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined, 
                              size: 14, 
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              contact.phone,
                              style: AppFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Tombol Action (Icon Base) ──
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      serviceIcon,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        // Animasi reset key agar jalan ulang saat next page diklik
        .animate(key: ValueKey('${contact.id}_$index'))
        .fadeIn(delay: Duration(milliseconds: 30 * (index % 5)), duration: 400.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

// ────────────────────────────────────────────────────────────────
// BADGE KATEGORI SIMPLE
// ────────────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final EmergencyContact contact;
  const _CategoryBadge({required this.contact});

  @override
  Widget build(BuildContext context) {
    final color = contact.categoryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        contact.categoryLabel,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// LOADING STATE (Shimmer)
// ────────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  final int index;
  const _LoadingCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 16,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          delay: Duration(milliseconds: 150 * index),
          duration: 1000.ms,
          color: Colors.grey.shade300,
        );
  }
}

// ────────────────────────────────────────────────────────────────
// EMPTY STATE
// ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.content_paste_off_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Data',
              style: AppFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data nomor darurat belum tersedia.',
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Muat Ulang',
                style: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: SigumiTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// KONFIRMASI PANGGILAN
// ────────────────────────────────────────────────────────────────
class _CallConfirmationSheet extends StatelessWidget {
  final EmergencyContact contact;
  const _CallConfirmationSheet({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Hubungi Layanan?',
              style: AppFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda akan membuat panggilan telepon biasa menuju kontak di bawah ini. Pastikan untuk menjelaskan situasi Anda dengan tenang.',
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: contact.accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call, color: contact.accentColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact.phone,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: contact.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.grey.shade600,
                    ),
                    child: Text(
                      'Batal',
                      style: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: contact.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Panggil',
                      style: AppFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
