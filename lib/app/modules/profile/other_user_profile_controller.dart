import 'package:get/get.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import '../../data/providers/api_provider.dart';
import '../../core/constants/api_constants.dart';
import '../directory/directory_controller.dart';
import '../posts/posts_controller.dart';

class OtherUserProfileController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();

  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> userProfile = Rx<Map<String, dynamic>?>(null);
  final RxList<Map<String, dynamic>> userPosts = <Map<String, dynamic>>[].obs;
  final RxBool isBlocked = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args['userId'] != null) {
      loadProfile(args['userId']);
    }
  }

  Future<void> loadProfile(dynamic userId) async {
    isLoading.value = true;
    try {
      // Use directory endpoint to get profile (supports both UUID and numeric ID)
      final response = await _api.get('${ApiConstants.directory}/${userId}');
      if (response.statusCode == 200) {
        userProfile.value = response.data['data'];
        
        final numericId = userProfile.value?['numeric_id'];
        final uuid = userProfile.value?['uuid'];
        
        if (numericId != null) {
          await loadUserPosts(numericId);
        }
        
        if (uuid != null) {
          await checkBlockStatus(uuid);
        }
      }
    } catch (e) {
      debugPrint('Error loading other user profile: $e');
    }
    isLoading.value = false;
  }

  Future<void> checkBlockStatus(String userId) async {
    try {
      final response = await _api.get('/users/block-status/$userId');
      if (response.statusCode == 200) {
        isBlocked.value = response.data['data']['is_blocked'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking block status: $e');
    }
  }

  Future<void> toggleBlockStatus() async {
    final user = userProfile.value;
    if (user == null || user['uuid'] == null) return;

    final userId = user['uuid'];
    final userName = user['full_name'] ?? 'User';

    try {
      if (isBlocked.value) {
        // Unblock
        final response = await _api.post('/users/unblock', data: {'blocked_user_id': userId});
        if (response.statusCode == 200) {
          isBlocked.value = false;
          Get.snackbar('Unblocked', 'You have unblocked $userName.');
          
          if (Get.isRegistered<DirectoryController>()) {
            Get.find<DirectoryController>().loadUsers(refresh: true);
          }
          if (Get.isRegistered<PostsController>()) {
            Get.find<PostsController>().loadHomeScreenPosts(refresh: true);
            Get.find<PostsController>().loadPosts(refresh: true);
          }
        }
      } else {
        // Block
        final response = await _api.post('/users/block', data: {'blocked_user_id': userId});
        if (response.statusCode == 200) {
          isBlocked.value = true;
          Get.snackbar('Blocked', 'You have blocked $userName. Their posts will no longer appear.');
          
          if (Get.isRegistered<DirectoryController>()) {
            Get.find<DirectoryController>().loadUsers(refresh: true);
          }
          if (Get.isRegistered<PostsController>()) {
            Get.find<PostsController>().loadHomeScreenPosts(refresh: true);
            Get.find<PostsController>().loadPosts(refresh: true);
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while updating the block status.', 
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError
      );
    }
  }

  Future<void> loadUserPosts(dynamic userId) async {
    try {
      final response = await _api.get('${ApiConstants.userPosts}/${userId}');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        userPosts.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading other user posts: $e');
    }
  }
}
