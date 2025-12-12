import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:campusdrive/providers/user_provider.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const ProfileAvatarWidget({super.key, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final profile = userProvider.userProfile;
          final imagePath = profile.profileImagePath;

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
              image: imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == null
                ? Center(
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                      size: size * 0.6,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}
