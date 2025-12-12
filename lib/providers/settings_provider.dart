import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

import 'dart:io';
import 'package:campusdrive/services/database_service.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _primaryColor = AppColors.primary;
  bool _hasSeenOnboarding = false;
  bool _showPerformanceOverlay = false;

  // Storage
  double _storageUsedMB = 0.0;
  final double _totalStorageGB = 5.0; // Mock limit

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get showPerformanceOverlay => _showPerformanceOverlay;

  double get storageUsedMB => _storageUsedMB;
  double get totalStorageGB => _totalStorageGB;
  double get storagePercentage =>
      (_storageUsedMB / (_totalStorageGB * 1024)).clamp(0.0, 1.0);

  // App Lock (Disabled/Removed)

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    _primaryColor = Color(
      prefs.getInt('primaryColor') ?? AppColors.primary.toARGB32(),
    );

    _areNotificationsEnabled = prefs.getBool('areNotificationsEnabled') ?? true;
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    _showPerformanceOverlay = prefs.getBool('showPerformanceOverlay') ?? false;

    await calculateStorageUsage();
    notifyListeners();
  }

  Future<void> calculateStorageUsage() async {
    try {
      final items = await DatabaseService().getAllItems();
      int totalBytes = 0;
      for (var item in items) {
        if (item.path.isNotEmpty) {
          final file = File(item.path);
          if (file.existsSync()) {
            totalBytes += await file.length();
          }
        }
      }
      _storageUsedMB = totalBytes / (1024 * 1024);
      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating storage: $e');
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    notifyListeners();
  }

  Future<void> updatePrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.toARGB32());
    notifyListeners();
  }

  bool _areNotificationsEnabled = true;
  bool get areNotificationsEnabled => _areNotificationsEnabled;

  // Feature Removed: App Lock
  Future<void> setAppLock(bool enabled) async {}

  Future<void> toggleNotifications(bool enabled) async {
    _areNotificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('areNotificationsEnabled', enabled);
    notifyListeners();
  }

  Future<void> clearCache() async {
    // Simulate clearing cache or clear SharedPreferences except essential ones
    // For now, just a delay to simulate work
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Cache cleared');
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    notifyListeners();
  }

  Future<void> togglePerformanceOverlay(bool enabled) async {
    _showPerformanceOverlay = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPerformanceOverlay', enabled);
    notifyListeners();
  }

  bool verifyPin(String pin) {
    return false;
  }
}
