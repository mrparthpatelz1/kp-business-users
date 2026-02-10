import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackBarHelper {
  static void showError(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.red,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  static void showSuccess(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.green,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.done_all_rounded, color: Colors.white),
    );
  }

  static void showWarning(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.orange,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    );
  }
}
