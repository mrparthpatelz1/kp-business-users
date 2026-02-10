import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../core/utils/snackbar_helper.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  Future<void> login() async {
    isLoading(true);

    try {
      final result = await _authService.login(
        loginController.text.trim(),
        passwordController.text,
      );

      debugPrint('Login result: $result');

      if (result['success']) {
        // Upload FCM token after successful login
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.uploadTokenToServer();
        } catch (e) {
          debugPrint('Failed to upload FCM token after login: $e');
        }

        Get.offAllNamed(Routes.HOME);
        isLoading(false);
        SnackBarHelper.showSuccess('Login successful!');
        return;
      }

      // Handle account status codes
      if (result['code'] == 'ACCOUNT_PENDING') {
        if (result['data'] != null && result['data']['user'] != null) {
          Get.find<StorageService>().user = result['data']['user'];
        }
        Get.offAllNamed(Routes.PENDING_APPROVAL);
        isLoading(false);
        return;
      }

      if (result['code'] == 'ACCOUNT_REJECTED') {
        if (result['data'] != null && result['data']['user'] != null) {
          Get.find<StorageService>().user = result['data']['user'];
        }
        Get.toNamed(Routes.REJECTED, arguments: {'reason': result['reason']});
        isLoading(false);
        return;
      }

      // Handle login failure
      isLoading(false);

      String displayMessage = result['message'] ?? 'Login failed';
      if (result['code'] == 'INVALID_CREDENTIALS') {
        displayMessage = 'Invalid email/phone or password';
      }

      SnackBarHelper.showError(displayMessage);
    } catch (e) {
      isLoading(false);
      SnackBarHelper.showError('An error occurred. Please try again.');
    }
  }

  void goToRegister() {
    Get.toNamed(Routes.REGISTER);
  }
}
