import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:path/path.dart' as path_lib;
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Extended Profile Data
  String? _college;
  String? _branch;
  String? _course;

  String? get college => _college;
  String? get branch => _branch;
  String? get course => _course;

  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _college = prefs.getString('college');
    _branch = prefs.getString('branch');
    _course = prefs.getString('course');
    notifyListeners();
  }

  Future<void> updateProfileData({
    String? college,
    String? branch,
    String? course,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (college != null) {
      _college = college;
      await prefs.setString('college', college);
    }
    if (branch != null) {
      _branch = branch;
      await prefs.setString('branch', branch);
    }
    if (course != null) {
      _course = course;
      await prefs.setString('course', course);
    }
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(name);
        await _user!.reload();
        _user = _authService.currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating name: $e');
      rethrow;
    }
  }

  Future<void> updateProfileImage(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        debugPrint('File does not exist: $path');
        return;
      }

      final supabase = Supabase.instance.client;
      final fileName =
          'profiles/${_user!.uid}_${DateTime.now().millisecondsSinceEpoch}${path_lib.extension(path)}';

      // Upload to Supabase Storage
      await supabase.storage.from('files').upload(fileName, file);

      // Get Public URL
      final publicUrl = supabase.storage.from('files').getPublicUrl(fileName);

      // Update Firebase User Profile
      await _user!.updatePhotoURL(publicUrl);
      await _user!.reload();
      _user = _authService.currentUser;

      // Also save locally for offline/caching if needed, but rely on URL primarily
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_profile_image', path);

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      // Fallback to local only if upload fails?
      // For now, we just log error.
    }
  }

  Future<String?> getLocalProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('local_profile_image');
  }

  // ... existing auth methods ...

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email, password);
      await loadProfileData(); // Load profile after sign in
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _setLoading(true);
    try {
      await _authService.signUpWithEmail(email, password, name);
      await loadProfileData();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
      await loadProfileData();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    // Optimistic Logout: Clear state immediately for instant UI feedback
    _user = null;
    _college = null;
    _branch = null;
    _course = null;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Error during background sign out: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
    } finally {
      _setLoading(false);
    }
  }
}
