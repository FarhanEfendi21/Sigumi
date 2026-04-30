import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

class ReportRepository {
  final _supabase = Supabase.instance.client;

  /// Buat laporan baru
  Future<Map<String, dynamic>> createReport({
    required String reporterName,
    required String category,
    required String title,
    required String description,
    String? phone,
    String? location,
    String? imageUrl,
    String? lokasi,
  }) async {
    try {
      Logger.info('Creating report...', tag: 'ReportRepository');
      Logger.log('Data: {', tag: 'ReportRepository');
      Logger.log('  reporter_name: $reporterName', tag: 'ReportRepository');
      Logger.log('  category: $category', tag: 'ReportRepository');
      Logger.log('  title: $title', tag: 'ReportRepository');
      Logger.log('  description: $description', tag: 'ReportRepository');
      Logger.log('  location: $location', tag: 'ReportRepository');
      Logger.log('  image_url: $imageUrl', tag: 'ReportRepository');
      Logger.log('  lokasi: $lokasi', tag: 'ReportRepository');
      Logger.log('}', tag: 'ReportRepository');

      final response =
          await _supabase
              .from('reports')
              .insert({
                'reporter_name': reporterName,
                'phone': phone,
                'category': category,
                'title': title,
                'description': description,
                'location': location,
                'image_url': imageUrl,
                'status': 'pending',
                'lokasi': lokasi,
              })
              .select()
              .single();

      Logger.success('Report created successfully: ${response['id']}', tag: 'ReportRepository');
      Logger.log('By: ${response['reporter_name']}', tag: 'ReportRepository');
      Logger.log('Lokasi: ${response['lokasi']}', tag: 'ReportRepository');
      return response;
    } on PostgrestException catch (e) {
      Logger.error('Database error: ${e.message}', tag: 'ReportRepository');
      Logger.log('Error code: ${e.code}', tag: 'ReportRepository');
      Logger.log('Error details: ${e.details}', tag: 'ReportRepository');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      Logger.error('Error creating report', tag: 'ReportRepository', error: e);
      throw Exception('Error creating report: $e');
    }
  }

  /// Ambil semua laporan (untuk admin/dashboard)
  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  /// Ambil laporan berdasarkan ID
  Future<Map<String, dynamic>> getReportById(String id) async {
    try {
      final response =
          await _supabase.from('reports').select().eq('id', id).single();

      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('Report tidak ditemukan');
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching report: $e');
    }
  }

  /// Update status laporan
  Future<Map<String, dynamic>> updateReportStatus(
    String id,
    String status,
  ) async {
    try {
      final response =
          await _supabase
              .from('reports')
              .update({
                'status': status,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', id)
              .select()
              .single();

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating report: $e');
    }
  }

  /// Upload gambar laporan ke Supabase storage
  Future<String?> uploadReportImage(XFile image, String reportId) async {
    try {
      // Generate nama file
      final fileName =
          'reports/$reportId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Baca file sebagai bytes
      final bytes = await image.readAsBytes();
      Logger.info('Image size: ${(bytes.length / 1024).toStringAsFixed(2)} KB', tag: 'ReportRepository');
      Logger.info('Uploading image to: $fileName', tag: 'ReportRepository');

      // Upload langsung ke Supabase storage
      final response = await _supabase.storage
          .from('reports')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      Logger.log('Upload response: $response', tag: 'ReportRepository');

      // Dapatkan public URL
      final publicUrl = _supabase.storage
          .from('reports')
          .getPublicUrl(fileName);

      Logger.success('Image uploaded successfully!', tag: 'ReportRepository');
      Logger.log('URL: $publicUrl', tag: 'ReportRepository');
      return publicUrl;
    } on StorageException catch (e) {
      Logger.error('Storage error: ${e.message}', tag: 'ReportRepository');
      Logger.log('Error code: ${e.statusCode}', tag: 'ReportRepository');
      Logger.log('Continuing without image...', tag: 'ReportRepository');
      return null;
    } catch (e) {
      Logger.error('Image upload failed', tag: 'ReportRepository', error: e);
      Logger.log('Continuing without image...', tag: 'ReportRepository');
      // Return null jika gagal, tapi jangan throw - laporan tetap bisa submit
      return null;
    }
  }

  /// Ambil laporan berdasarkan kategori
  Future<List<Map<String, dynamic>>> getReportsByCategory(
    String category,
  ) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  /// Ambil laporan berdasarkan status
  Future<List<Map<String, dynamic>>> getReportsByStatus(String status) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }
}
