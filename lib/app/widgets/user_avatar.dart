import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? name; // For initial fallback
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isBusiness;
  final bool enablePopup;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.name,
    this.backgroundColor,
    this.iconColor,
    this.isBusiness = false,
    this.enablePopup = false,
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

    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
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
    } else {
      avatar = _buildFallback(effectiveBackgroundColor, effectiveIconColor);
    }

    if (enablePopup && imageUrl != null && imageUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showImagePopup(context),
        child: avatar,
      );
    }

    return avatar;
  }

  void _showImagePopup(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen background
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
              ),
            ),
            // Zoomable Image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: ApiConstants.getFullUrl(imageUrl),
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white, size: 50),
                ),
              ),
            ),
            // Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
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
