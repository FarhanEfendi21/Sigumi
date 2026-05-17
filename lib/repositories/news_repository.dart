import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/news_model.dart';
import '../utils/logger.dart';

class NewsRepository {
  final _supabase = Supabase.instance.client;

  /// Ambil 5 berita terbaru (filter by lokasi jika diberikan)
  Future<List<NewsModel>> getLatestNews({int limit = 5, String? lokasi}) async {
    try {
      Logger.info(
        'Fetching latest $limit news${lokasi != null ? ' for $lokasi' : ''}...',
        tag: 'NewsRepository',
      );

      final response =
          lokasi != null
              ? await _supabase
                  .from('news')
                  .select()
                  .eq('lokasi', lokasi)
                  .order('created_at', ascending: false)
                  .limit(limit)
              : await _supabase
                  .from('news')
                  .select()
                  .order('created_at', ascending: false)
                  .limit(limit);

      Logger.success(
        'News fetched successfully: ${response.length} items',
        tag: 'NewsRepository',
      );
      for (var i = 0; i < response.length; i++) {
        Logger.log(
          '[$i] ${response[i]['title']} - Status: ${response[i]['status']}',
          tag: 'NewsRepository',
        );
      }

      return (response as List)
          .map((json) => NewsModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      Logger.error('Database error: ${e.message}', tag: 'NewsRepository');
      Logger.log('Error code: ${e.code}', tag: 'NewsRepository');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      Logger.error('Error fetching news', tag: 'NewsRepository', error: e);
      throw Exception('Error fetching news: $e');
    }
  }

  /// Ambil semua berita (untuk admin)
  Future<List<NewsModel>> getAllNews() async {
    try {
      Logger.info('Fetching all news...', tag: 'NewsRepository');

      final response = await _supabase
          .from('news')
          .select()
          .order('created_at', ascending: false);

      Logger.success(
        'All news fetched: ${response.length} items',
        tag: 'NewsRepository',
      );

      return (response as List)
          .map((json) => NewsModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      Logger.error('Database error', tag: 'NewsRepository', error: e.message);
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      Logger.error('Error fetching news', tag: 'NewsRepository', error: e);
      throw Exception('Error fetching news: $e');
    }
  }

  /// Ambil berita berdasarkan ID
  Future<NewsModel> getNewsById(String id) async {
    try {
      Logger.info('Fetching news with ID: $id', tag: 'NewsRepository');

      final response =
          await _supabase.from('news').select().eq('id', id).single();

      Logger.success('News found: ${response['title']}', tag: 'NewsRepository');

      return NewsModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('Berita tidak ditemukan');
      }
      Logger.error('Database error', tag: 'NewsRepository', error: e.message);
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      Logger.error('Error fetching news', tag: 'NewsRepository', error: e);
      throw Exception('Error fetching news: $e');
    }
  }

  /// Buat berita baru (untuk admin)
  Future<NewsModel> createNews({
    required String title,
    String? content,
    String? imageUrl,
    String? status,
  }) async {
    try {
      Logger.info('Creating news...', tag: 'NewsRepository');

      final response =
          await _supabase
              .from('news')
              .insert({
                'title': title,
                'content': content,
                'image_url': imageUrl,
                'status': status ?? 'draft',
              })
              .select()
              .single();

      Logger.success('News created: ${response['id']}', tag: 'NewsRepository');

      return NewsModel.fromJson(response);
    } on PostgrestException catch (e) {
      Logger.error('Database error', tag: 'NewsRepository', error: e.message);
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      Logger.error('Error creating news', tag: 'NewsRepository', error: e);
      throw Exception('Error creating news: $e');
    }
  }

  /// Update berita (untuk admin)
  Future<NewsModel> updateNews(
    String id, {
    String? title,
    String? content,
    String? imageUrl,
    String? status,
  }) async {
    try {
      Logger.info('Updating news: $id', tag: 'NewsRepository');

      final Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (status != null) updateData['status'] = status;

      final response =
          await _supabase
              .from('news')
              .update(updateData)
              .eq('id', id)
              .select()
              .single();

      Logger.success('News updated: $id', tag: 'NewsRepository');

      return NewsModel.fromJson(response);
    } on PostgrestException catch (e) {
      Logger.error('Database error', tag: 'NewsRepository', error: e.message);
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      Logger.error('Error updating news', tag: 'NewsRepository', error: e);
      throw Exception('Error updating news: $e');
    }
  }

  /// Hapus berita (untuk admin)
  Future<void> deleteNews(String id) async {
    try {
      Logger.info('Deleting news: $id', tag: 'NewsRepository');

      await _supabase.from('news').delete().eq('id', id);

      Logger.success('News deleted: $id', tag: 'NewsRepository');
    } on PostgrestException catch (e) {
      Logger.error('Database error', tag: 'NewsRepository', error: e.message);
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      Logger.error('Error deleting news', tag: 'NewsRepository', error: e);
      throw Exception('Error deleting news: $e');
    }
  }
}
