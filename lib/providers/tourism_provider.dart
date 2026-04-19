import 'package:flutter/material.dart';
import '../models/tourism_destination.dart';
import '../models/tourism_event.dart';
import '../repositories/tourism_repository.dart';

/// Provider untuk state management fitur Pariwisata.
///
/// Mengelola:
/// - Daftar destinasi wisata berdasarkan region
/// - Event/agenda mendatang
/// - Filter kategori yang dipilih
/// - Loading state
class TourismProvider extends ChangeNotifier {
  final TourismRepository _repo = TourismRepository();

  // ── State ────────────────────────────────────────────────
  List<TourismDestination> _destinations = [];
  List<TourismEvent> _events = [];
  String _selectedCategory = 'Semua';
  bool _isLoadingDestinations = false;
  bool _isLoadingEvents = false;
  String _currentRegion = '';

  // ── Getters ──────────────────────────────────────────────
  bool get isLoadingDestinations => _isLoadingDestinations;
  bool get isLoadingEvents => _isLoadingEvents;
  bool get isLoading => _isLoadingDestinations || _isLoadingEvents;
  String get selectedCategory => _selectedCategory;
  String get currentRegion => _currentRegion;
  List<TourismEvent> get upcomingEvents => _events;

  /// Kategori yang tersedia — sesuai data (tanpa Hiburan)
  static const List<String> categories = [
    'Semua',
    'Alam',
    'Budaya',
    'Pantai',
    'Kuliner',
  ];

  /// Destinasi yang difilter berdasarkan kategori yang dipilih
  List<TourismDestination> get filteredDestinations {
    if (_selectedCategory == 'Semua') return _destinations;
    return _destinations
        .where((d) => d.category == _selectedCategory)
        .toList();
  }

  // ── Actions ──────────────────────────────────────────────

  /// Muat data wisata untuk region yang dipilih.
  /// Dipanggil saat region berubah dari VolcanoProvider.
  Future<void> loadForRegion(String region) async {
    // Hindari reload jika region sama
    if (region == _currentRegion && _destinations.isNotEmpty) return;

    _currentRegion = region;
    _selectedCategory = 'Semua'; // Reset filter saat ganti daerah

    // Load destinations & events secara paralel
    await Future.wait([
      _loadDestinations(region),
      _loadEvents(region),
    ]);
  }

  Future<void> _loadDestinations(String region) async {
    _isLoadingDestinations = true;
    notifyListeners();

    try {
      _destinations = await _repo.getDestinationsByRegion(region);
    } catch (e) {
      debugPrint('[TourismProvider] Error load destinations: $e');
      _destinations = TourismDestination.byRegion(region);
    }

    _isLoadingDestinations = false;
    notifyListeners();
  }

  Future<void> _loadEvents(String region) async {
    _isLoadingEvents = true;
    notifyListeners();

    try {
      _events = await _repo.getUpcomingEvents(region);
    } catch (e) {
      debugPrint('[TourismProvider] Error load events: $e');
      _events = TourismEvent.byRegion(region);
    }

    _isLoadingEvents = false;
    notifyListeners();
  }

  /// Ubah filter kategori
  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  /// Refresh manual (pull-to-refresh)
  Future<void> refresh() async {
    _currentRegion = ''; // Reset agar loadForRegion tidak skip
    final region = _currentRegion.isEmpty ? 'Yogyakarta' : _currentRegion;
    await loadForRegion(region);
  }
}
