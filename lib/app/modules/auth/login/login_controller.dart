import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/notification_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final formKey = GlobalKey<FormState>();
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxString errorMessage = ''.obs;

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    // Don't clear error message - keep it visible
    // Don't clear text fields - user may want to correct input
    isLoading.value = true;

    try {
      final result = await _authService.login(
        loginController.text.trim(),
        passwordController.text,
      );

      // Check if controller is still mounted before updating state
      if (isClosed) return;

      // The isLoading.value = false; is moved to a finally block below.

      if (result['success']) {
        // Clear fields only on successful login
        loginController.clear();
        passwordController.clear();
        errorMessage.value = '';

        // Upload FCM token after successful login
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.uploadTokenToServer();
        } catch (e) {
          debugPrint('Failed to upload FCM token after login: $e');
          // Don't block navigation if FCM upload fails
        }

        Get.offAllNamed(Routes.HOME);
      } else {
        // Check for specific error codes
        if (result['code'] == 'ACCOUNT_PENDING') {
          // Save user data if available (so we can show village admin info)
          if (result['data'] != null && result['data']['user'] != null) {
            Get.find<StorageService>().user = result['data']['user'];
          }
          Get.offAllNamed(Routes.PENDING_APPROVAL);
          return;
        }

        if (result['code'] == 'ACCOUNT_REJECTED') {
          // Save user data if available
          if (result['data'] != null && result['data']['user'] != null) {
            Get.find<StorageService>().user = result['data']['user'];
          }
          Get.toNamed(Routes.REJECTED, arguments: {'reason': result['reason']});
          return;
        }

        // Set error message for display in UI
        String displayMessage = result['message'] ?? 'Login failed';

        // Customize message based on error code
        if (result['code'] == 'INVALID_CREDENTIALS') {
          displayMessage = 'Invalid email/phone or password';
        } else if (result['code'] == 'ACCOUNT_PENDING') {
          displayMessage = 'Your account is pending approval';
        } else if (result['code'] == 'ACCOUNT_REJECTED') {
          displayMessage = 'Your account has been rejected';
        }

        errorMessage.value = displayMessage;

        // Show snackbar for immediate feedback (only if still mounted)
        if (!isClosed && Get.context != null) {
          Get.snackbar(
            'Login Failed',
            displayMessage,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error_outline, color: Colors.white),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        }

        // Handle specific error codes
        if (result['code'] == 'ACCOUNT_PENDING') {
          Future.delayed(const Duration(seconds: 2), () {
            if (!isClosed) {
              Get.offAllNamed(Routes.PENDING_APPROVAL);
            }
          });
        }
      }
    } catch (e) {
      if (!isClosed) {
        isLoading.value = false;
        errorMessage.value = 'An error occurred. Please try again.';

        if (Get.context != null) {
          Get.snackbar(
            'Error',
            'An error occurred. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  void goToRegister() {
    Get.toNamed(Routes.REGISTER);
  }

  @override
  void onClose() {
    loginController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
