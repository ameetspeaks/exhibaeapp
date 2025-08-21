import 'package:flutter/material.dart';

class ProfilePictureDisplay extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const ProfilePictureDisplay({
    super.key,
    this.avatarUrl,
    this.size = 80,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Icon(
              Icons.person,
              size: size * 0.6,
              color: iconColor ?? Colors.grey.shade600,
            )
          : null,
    );
  }
}
