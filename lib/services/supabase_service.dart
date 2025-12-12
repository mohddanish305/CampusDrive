import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  // Client getter
  SupabaseClient get client => Supabase.instance.client;

  // Test connection
  Future<bool> testConnection() async {
    try {
      final response = await client.from('items').select().limit(1);
      debugPrint('Supabase connection successful: $response');
      return true;
    } catch (e) {
      debugPrint('Supabase connection failed: $e');
      return false;
    }
  }

  // Insert data
  Future<void> insertData(String table, Map<String, dynamic> data) async {
    try {
      await client.from(table).insert(data);
    } catch (e) {
      debugPrint('Error inserting data: $e');
      rethrow;
    }
  }

  // Fetch data
  Future<List<Map<String, dynamic>>> fetchData(String table) async {
    try {
      final response = await client.from(table).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching data: $e');
      rethrow;
    }
  }

  // Upload file
  Future<String?> uploadFile(File file, String remotePath) async {
    try {
      await client.storage
          .from('files') // Bucket named "files" as requested
          .upload(
            remotePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return client.storage.from('files').getPublicUrl(remotePath);
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Download file URL (helper to get public URL)
  String getFileUrl(String remotePath) {
    return client.storage.from('files').getPublicUrl(remotePath);
  }

  // Download file content
  Future<void> downloadFile(String remotePath, String localPath) async {
    try {
      final bytes = await client.storage.from('files').download(remotePath);
      final file = File(localPath);
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      rethrow;
    }
  }
}
