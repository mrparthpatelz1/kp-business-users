import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/notification_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      // Ensure StorageService is available
      final storage = Get.find<StorageService>();
      debugPrint('StorageService found, isLoggedIn: ${storage.isLoggedIn}');

      if (storage.isLoggedIn) {
        // Upload FCM token for logged-in user on app start
        try {
          if (Get.isRegistered<NotificationService>()) {
            final notificationService = Get.find<NotificationService>();
            await notificationService.uploadTokenToServer();
            debugPrint('FCM token uploaded on app start');
          }
        } catch (e) {
          debugPrint('Failed to upload FCM token on app start: $e');
          // Don't block navigation if FCM upload fails
        }

        debugPrint('Navigating to HOME');
        Get.offAllNamed(Routes.HOME);
      } else {
        debugPrint('Navigating to LOGIN');
        Get.offAllNamed(Routes.LOGIN);
      }
    } catch (e) {
      debugPrint('Error in splash navigation: $e');
      // Fallback to login on error
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
