import 'package:flutter/material.dart';
import '../../utils/constants.dart';

import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Permissions',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPermissionItem(
            icon: Icons.storage,
            title: 'Storage',
            description: 'Required to save and access your study materials.',
            permission: Permission
                .storage, // Or Permission.manageExternalStorage for Android 11+
          ),
          const SizedBox(height: 16),
          _buildPermissionItem(
            icon: Icons.camera_alt,
            title: 'Camera',
            description: 'Required to scan documents.',
            permission: Permission.camera,
          ),
          const SizedBox(height: 16),
          _buildPermissionItem(
            icon: Icons.notifications,
            title: 'Notifications',
            description: 'Required to receive updates and reminders.',
            permission: Permission.notification,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Permission permission,
  }) {
    return FutureBuilder<PermissionStatus>(
      future: permission.status,
      builder: (builderContext, snapshot) {
        final status = snapshot.data ?? PermissionStatus.denied;
        final isGranted = status.isGranted;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (isGranted)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                if (!isGranted)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (status.isPermanentlyDenied) {
                          await openAppSettings();
                        } else {
                          final result = await permission.request();
                          if (mounted) {
                            setState(() {}); // Rebuild to update status
                            if (result.isGranted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$title permission granted'),
                                ),
                              );
                            } else if (result.isPermanentlyDenied) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$title permission permanently denied. Please enable in settings.',
                                  ),
                                  action: SnackBarAction(
                                    label: 'Settings',
                                    onPressed: () => openAppSettings(),
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Text(
                        status.isPermanentlyDenied ? 'Open Settings' : 'Allow',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
