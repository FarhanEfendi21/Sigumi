import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';

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
      print('📝 Creating report...');
      print('Data: {');
      print('  reporter_name: $reporterName');
      print('  category: $category');
      print('  title: $title');
      print('  description: $description');
      print('  location: $location');
      print('  image_url: $imageUrl');
      print('  lokasi: $lokasi');
      print('}');

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

      print('✅ Report created successfully: ${response['id']}');
      print('   By: ${response['reporter_name']}');
      print('   Lokasi: ${response['lokasi']}');
      return response;
    } on PostgrestException catch (e) {
      print('❌ Database error: ${e.message}');
      print('Error code: ${e.code}');
      print('Error details: ${e.details}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('❌ Error creating report: $e');
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
      print('📸 Image size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      print('📸 Uploading image to: $fileName');

      // Upload langsung ke Supabase storage
      final response = await _supabase.storage
          .from('reports')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print('📸 Upload response: $response');

      // Dapatkan public URL
      final publicUrl = _supabase.storage
          .from('reports')
          .getPublicUrl(fileName);

      print('✅ Image uploaded successfully!');
      print('   URL: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      print('❌ Storage error: ${e.message}');
      print('   Error code: ${e.statusCode}');
      print('⚠️ Continuing without image...');
      return null;
    } catch (e) {
      print('❌ Image upload failed: $e');
      print('⚠️ Continuing without image...');
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
