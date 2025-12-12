import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campusdrive/providers/settings_provider.dart';
import 'package:campusdrive/providers/user_provider.dart'; // Add import
import 'package:campusdrive/screens/settings/profile_screen.dart';
import 'package:campusdrive/screens/settings/permissions_screen.dart';
import 'package:campusdrive/screens/settings/privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer2<SettingsProvider, UserProvider>(
        builder: (context, settings, userProvider, _) {
          final profile = userProvider.userProfile;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Profile Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              image: profile.profileImagePath != null
                                  ? DecorationImage(
                                      image: FileImage(
                                        File(profile.profileImagePath!),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profile.profileImagePath == null
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF7C3AED),
                                    size: 30,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fullName.isNotEmpty
                                      ? profile.fullName
                                      : 'User Name',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  profile.email,
                                  style: const TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader(context, 'Notifications'),
                Card(
                  child: SwitchListTile(
                    title: const Text('Notifications'),
                    value: settings.areNotificationsEnabled,
                    activeTrackColor: const Color(0xFF7C3AED),
                    onChanged: (val) {
                      settings.toggleNotifications(val);
                    },
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, 'Appearance'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        value: settings.themeMode == ThemeMode.dark,
                        activeTrackColor: const Color(0xFF7C3AED),
                        onChanged: (val) {
                          settings.toggleTheme(val);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Primary Color'),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7C3AED),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: () {
                          // Show color picker
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, 'Storage'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Storage Used'),
                            Text(
                              '${(settings.storagePercentage * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: settings.storagePercentage,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF7C3AED),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${settings.storageUsedMB.toStringAsFixed(1)} MB of ${settings.totalStorageGB} GB used',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Divider(height: 24),
                        InkWell(
                          onTap: () async {
                            await settings.clearCache();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cache Cleared')),
                              );
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Clear Cache'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, 'Privacy & Security'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Permissions'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PermissionsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
