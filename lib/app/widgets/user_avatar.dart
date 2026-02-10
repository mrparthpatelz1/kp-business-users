import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? name; // For initial fallback
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isBusiness;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.name,
    this.backgroundColor,
    this.iconColor,
    this.isBusiness = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ??
        (isBusiness
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.accentColor.withOpacity(0.1));

    final effectiveIconColor =
        iconColor ??
        (isBusiness ? AppTheme.primaryColor : AppTheme.accentColor);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: ApiConstants.getFullUrl(imageUrl),
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: effectiveBackgroundColor,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: effectiveBackgroundColor,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: effectiveIconColor,
          ),
        ),
        errorWidget: (context, url, error) =>
            _buildFallback(effectiveBackgroundColor, effectiveIconColor),
      );
    }

    return _buildFallback(effectiveBackgroundColor, effectiveIconColor);
  }

  Widget _buildFallback(Color bgColor, Color iconColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: name != null && name!.isNotEmpty
          ? Text(
              name![0].toUpperCase(),
              style: TextStyle(
                fontSize: radius, // simplistic scaling
                color: iconColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : Icon(
              isBusiness ? Icons.business : Icons.person,
              color: iconColor,
              size: radius * 1.2,
            ),
    );
  }
}
