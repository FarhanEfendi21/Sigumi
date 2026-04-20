import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/news_model.dart';

class NewsRepository {
  final _supabase = Supabase.instance.client;

  /// Ambil 5 berita terbaru
  Future<List<NewsModel>> getLatestNews({int limit = 5}) async {
    try {
      print('📰 Fetching latest $limit news...');

      final response = await _supabase
          .from('news')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      print('✅ News fetched successfully: ${response.length} items');
      for (var i = 0; i < response.length; i++) {
        print(
          '   [$i] ${response[i]['title']} - Status: ${response[i]['status']}',
        );
      }

      return (response as List)
          .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      print('❌ Database error: ${e.message}');
      print('   Error code: ${e.code}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('❌ Error fetching news: $e');
      throw Exception('Error fetching news: $e');
    }
  }

  /// Ambil semua berita (untuk admin)
  Future<List<NewsModel>> getAllNews() async {
    try {
      print('📰 Fetching all news...');

      final response = await _supabase
          .from('news')
          .select()
          .order('created_at', ascending: false);

      print('✅ All news fetched: ${response.length} items');

      return (response as List)
          .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      print('❌ Database error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('❌ Error fetching news: $e');
      throw Exception('Error fetching news: $e');
    }
  }

  /// Ambil berita berdasarkan ID
  Future<NewsModel> getNewsById(String id) async {
    try {
      print('📰 Fetching news with ID: $id');

      final response =
          await _supabase.from('news').select().eq('id', id).single();

      print('✅ News found: ${response['title']}');

      return NewsModel.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('Berita tidak ditemukan');
      }
      print('❌ Database error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('❌ Error fetching news: $e');
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
      print('📝 Creating news...');

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

      print('✅ News created: ${response['id']}');

      return NewsModel.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('❌ Database error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('❌ Error creating news: $e');
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
      print('📝 Updating news: $id');

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

      print('✅ News updated: $id');

      return NewsModel.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('❌ Database error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('❌ Error updating news: $e');
      throw Exception('Error updating news: $e');
    }
  }

  /// Hapus berita (untuk admin)
  Future<void> deleteNews(String id) async {
    try {
      print('📝 Deleting news: $id');

      await _supabase.from('news').delete().eq('id', id);

      print('✅ News deleted: $id');
    } on PostgrestException catch (e) {
      print('❌ Database error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('❌ Error deleting news: $e');
      throw Exception('Error deleting news: $e');
    }
  }
}
