import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusdrive/models/user_profile.dart';
import 'package:campusdrive/services/database_service.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _userProfile = UserProfile.empty();
  bool _isLoading = true;

  UserProfile get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  UserProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await DatabaseService().getUserProfile();
      if (profile != null) {
        _userProfile = profile;

        // Sync with Firebase Auth if needed
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          bool needsUpdate = false;
          // If local name is default 'User Name' but Auth has a name, update local.
          if ((_userProfile.fullName == 'User Name' ||
                  _userProfile.fullName.isEmpty) &&
              user.displayName != null &&
              user.displayName!.isNotEmpty) {
            _userProfile.fullName = user.displayName!;
            needsUpdate = true;
          }
          // If local email is empty but Auth has email, update local.
          if (_userProfile.email.isEmpty && user.email != null) {
            _userProfile.email = user.email!;
            needsUpdate = true;
          }

          if (needsUpdate) {
            await DatabaseService().saveUserProfile(_userProfile);
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    _userProfile = newProfile;
    notifyListeners();
    await DatabaseService().saveUserProfile(newProfile);
  }

  Future<void> updateProfileImage(String? imagePath) async {
    _userProfile.profileImagePath = imagePath;
    notifyListeners();
    // Save whole object or just update field if we had granular update
    await DatabaseService().saveUserProfile(_userProfile);
  }

  // Helper to refresh if needed externally
  Future<void> refreshProfile() async {
    await _loadProfile();
  }
}
