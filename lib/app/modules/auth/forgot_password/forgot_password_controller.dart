import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/providers/api_provider.dart';

class ForgotPasswordController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Text Controllers
  final emailOrPhoneController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Loading states
  var isLoading = false.obs;
  
  // Current step: 0 = Request OTP, 1 = Verify OTP, 2 = Reset Password
  var currentStep = 0.obs;

  // Password visibility states
  var obscureNewPassword = true.obs;
  var obscureConfirmPassword = true.obs;

  void toggleNewPasswordVisibility() => obscureNewPassword.value = !obscureNewPassword.value;
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.value = !obscureConfirmPassword.value;

  // Stored values
  String _resetToken = '';

  @override
  void onClose() {
    emailOrPhoneController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Step 1: Send OTP
  Future<void> sendOtp() async {
    final value = emailOrPhoneController.text.trim();
    if (value.isEmpty) {
      Get.snackbar('Error', 'Please enter your email or phone number',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.forgotPassword,
        data: {'emailOrPhone': value},
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', response.data['message'] ?? 'OTP Sent successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white);
        currentStep.value = 1; // Move to verification step
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to send OTP',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred. Please check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: Verify OTP
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    final emailOrPhone = emailOrPhoneController.text.trim();

    if (otp.length != 6) {
      Get.snackbar('Error', 'OTP must be exactly 6 digits',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.verifyOtp,
        data: {'emailOrPhone': emailOrPhone, 'otp': otp},
      );

      if (response.statusCode == 200 && response.data['success']) {
        _resetToken = response.data['data']['reset_token'];
        Get.snackbar('Success', 'OTP verified successfully.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white);
        currentStep.value = 2; // Move to password reset step
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Invalid or expired OTP',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Invalid verification code.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 3: Reset Password
  Future<void> resetPassword() async {
    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;

    if (newPass.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters long',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
      return;
    }

    if (newPass != confirmPass) {
      Get.snackbar('Error', 'Passwords do not match',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.resetPassword,
        data: {
          'resetToken': _resetToken,
          'newPassword': newPass,
        },
      );

      if (response.statusCode == 200 && response.data['success']) {
        Get.snackbar('Success', 'Password reset successfully. You can now login.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white);
        Get.offAllNamed('/login'); // Redirect to login page
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to reset password',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to reset password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
