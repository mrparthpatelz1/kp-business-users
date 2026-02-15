import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';
import '../../data/services/auth_service.dart';
import '../posts/posts_controller.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> profile = Rx<Map<String, dynamic>?>(null);
  final RxList<Map<String, dynamic>> userPosts = <Map<String, dynamic>>[].obs;
  final RxBool showFullDetails = false.obs;

  Map<String, dynamic>? get currentUser => _authService.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    // Sync profile with AuthService
    ever(_authService.currentUser, (user) {
      if (user != null) {
        profile.value = user;
      }
    });

    loadProfile();
    loadMyPosts();
  }

  Future<void> loadProfile({bool refresh = false}) async {
    if (!refresh) isLoading.value = true;
    try {
      final result = await _authService.getProfile();
      if (result['success'] == true) {
        profile.value = result['data'];
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    isLoading.value = false;
  }

  Future<void> refreshProfile() async {
    await Future.wait([loadProfile(refresh: true), loadMyPosts()]);
  }

  Future<void> loadMyPosts() async {
    try {
      final response = await _api.get(ApiConstants.myPosts);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        userPosts.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading my posts: $e');
    }
  }

  Future<void> deletePost(dynamic postId) async {
    try {
      final response = await _api.delete('${ApiConstants.posts}/$postId');
      if (response.statusCode == 200) {
        userPosts.removeWhere((post) => post['id'] == postId);

        // Refresh posts in other controllers
        if (Get.isRegistered<PostsController>()) {
          final postsController = Get.find<PostsController>();
          postsController.loadHomeScreenPosts(refresh: true);
          postsController.loadPosts(refresh: true);
          postsController.loadAds();
        }

        Get.snackbar(
          'Success',
          'Post deleted successfully',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete post',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      Get.snackbar(
        'Error',
        'Failed to delete post',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> editPost(Map<String, dynamic> post) async {
    // We need to import CreatePostView, but since it's a separate module, we might route to it or open it directly
    // For now, let's assume we can navigate to the route or import the view.
    // Since routes are best, we can pass the post object via arguments.
    // But wait, the standard way in this app seems to be named routes.
    // Let's modify CreatePostView to accept arguments.
    // We need to import CreatePostView, but since it's a separate module, we might route to it or open it directly
    // For now, let's assume we can navigate to the route or import the view.
    // Since routes are best, we can pass the post object via arguments.
    // But wait, the standard way in this app seems to be named routes.
    // Let's modify CreatePostView to accept arguments.
    await Get.toNamed(Routes.CREATE_POST, arguments: {'post': post});
    loadMyPosts(); // Refresh list after returning from edit
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.put(ApiConstants.profile, data: data);
      if (response.statusCode == 200) {
        await loadProfile();
        return {'success': true, 'message': 'Profile updated successfully'};
      }
      return {'success': false, 'message': 'Failed to update profile'};
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    return await _authService.changePassword(oldPassword, newPassword);
  }

  Future<void> logout() async {
    await _authService.logout();
    Get.offAllNamed('/login');
  }
}
