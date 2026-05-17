import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../repositories/news_repository.dart';
import '../utils/logger.dart';

class NewsProvider extends ChangeNotifier {
  final NewsRepository _repository = NewsRepository();

  List<NewsModel> _newsList = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NewsModel> get newsList => _newsList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch berita terbaru (dengan filter lokasi)
  Future<void> fetchLatestNews({int limit = 5, String? lokasi}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _newsList = await _repository.getLatestNews(limit: limit, lokasi: lokasi);
      Logger.success('${_newsList.length} news loaded', tag: 'NewsProvider');
    } catch (e) {
      _error = e.toString();
      Logger.error('Provider error', tag: 'NewsProvider', error: _error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch semua berita (untuk admin)
  Future<void> fetchAllNews() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _newsList = await _repository.getAllNews();
      Logger.success('${_newsList.length} news loaded', tag: 'NewsProvider');
    } catch (e) {
      _error = e.toString();
      Logger.error('Provider error', tag: 'NewsProvider', error: _error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch berita berdasarkan ID
  Future<NewsModel?> fetchNewsById(String id) async {
    try {
      final news = await _repository.getNewsById(id);
      return news;
    } catch (e) {
      _error = e.toString();
      Logger.error('Provider error', tag: 'NewsProvider', error: _error);
      return null;
    }
  }

  /// Refresh berita terbaru
  Future<void> refreshLatestNews({int limit = 5, String? lokasi}) async {
    await fetchLatestNews(limit: limit, lokasi: lokasi);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
