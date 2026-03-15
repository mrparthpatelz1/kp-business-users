import 'package:get/get.dart';
import '../../data/providers/api_provider.dart';
import 'package:flutter/foundation.dart';
import '../directory/directory_controller.dart';
import '../posts/posts_controller.dart';

class BlockedUsersController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();
  
  final RxList<Map<String, dynamic>> blockedUsers = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadBlockedUsers();
  }

  Future<void> loadBlockedUsers() async {
    isLoading.value = true;
    try {
      final response = await _api.get('/users/blocked');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        blockedUsers.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
    }
    isLoading.value = false;
  }

  Future<void> unblockUser(String userId, String? userName) async {
    try {
      final response = await _api.post('/users/unblock', data: {'blocked_user_id': userId});
      
      if (response.statusCode == 200) {
        // Remove from local list
        blockedUsers.removeWhere((user) => user['uuid'] == userId);
        Get.snackbar('Unblocked', 'You have unblocked ${userName ?? 'User'}.');

        // Refresh Directory and Posts so the unblocked user reappears
        if (Get.isRegistered<DirectoryController>()) {
          Get.find<DirectoryController>().loadUsers(refresh: true);
        }
        if (Get.isRegistered<PostsController>()) {
          Get.find<PostsController>().loadHomeScreenPosts(refresh: true);
          Get.find<PostsController>().loadPosts(refresh: true);
        }
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      Get.snackbar('Error', 'Failed to unblock user. Please try again.');
    }
  }
}
