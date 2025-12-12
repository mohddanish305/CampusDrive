import 'package:flutter/material.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../services/database_service.dart';
import '../models/study_item.dart';

class SyncProvider with ChangeNotifier {
  final SupabaseService _supabaseService =
      SupabaseService(); // Will fail if not init
  final DatabaseService _databaseService = DatabaseService();

  bool _isSyncing = false;
  bool _isBackupEnabled = false;

  bool get isSyncing => _isSyncing;
  bool get isBackupEnabled => _isBackupEnabled;

  void toggleBackup(bool value) {
    _isBackupEnabled = value;
    notifyListeners();
    if (value) {
      syncNow();
    }
  }

  Future<void> syncNow() async {
    if (!_isBackupEnabled || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Fetch all items that are not synced
      // This is a simplified sync logic
      final items = await _databaseService.getAllItems();
      for (final item in items) {
        if (!item.isSynced && item.type != FileType.folder) {
          // Upload
          final remotePath = '${item.parentId ?? "root"}/${item.name}';
          final url = await _supabaseService.uploadFile(
            File(item.path),
            remotePath,
          );

          if (url != null) {
            final updatedItem = item.copyWith(
              isSynced: true,
              supabasePath: remotePath,
              supabaseUrl: url,
            );
            await _databaseService.updateItem(updatedItem);
          }
        }
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
