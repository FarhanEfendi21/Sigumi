import 'package:flutter/material.dart';
import '../repositories/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository = ReportRepository();

  // State management
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic>? _currentReport;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get reports => _reports;
  Map<String, dynamic>? get currentReport => _currentReport;

  /// Submit laporan baru
  Future<bool> submitReport({
    required String reporterName,
    required String category,
    required String title,
    required String description,
    String? phone,
    String? location,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _repository.createReport(
        reporterName: reporterName,
        category: category,
        title: title,
        description: description,
        phone: phone,
        location: location,
        imageUrl: imageUrl,
      );

      _currentReport = response;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Ambil semua laporan
  Future<void> fetchAllReports() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _reports = await _repository.getAllReports();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil laporan berdasarkan ID
  Future<void> fetchReportById(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentReport = await _repository.getReportById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update status laporan
  Future<bool> updateReportStatus(String id, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _repository.updateReportStatus(id, status);

      // Update local state
      final index = _reports.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        _reports[index] = response;
      }

      if (_currentReport?['id'] == id) {
        _currentReport = response;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Ambil laporan berdasarkan kategori
  Future<void> fetchReportsByCategory(String category) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _reports = await _repository.getReportsByCategory(category);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil laporan berdasarkan status
  Future<void> fetchReportsByStatus(String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _reports = await _repository.getReportsByStatus(status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _isLoading = false;
    _error = null;
    _reports = [];
    _currentReport = null;
    notifyListeners();
  }
}
