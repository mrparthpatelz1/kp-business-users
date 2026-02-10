import 'package:get/get.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import '../../data/providers/api_provider.dart';
import '../../core/constants/api_constants.dart';

class OtherUserProfileController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();

  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> userProfile = Rx<Map<String, dynamic>?>(null);
  final RxList<Map<String, dynamic>> userPosts = <Map<String, dynamic>>[].obs;

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
        // Load posts using numeric_id from profile
        final numericId = userProfile.value?['numeric_id'];
        if (numericId != null) {
          await loadUserPosts(numericId);
        }
      }
    } catch (e) {
      debugPrint('Error loading other user profile: $e');
    }
    isLoading.value = false;
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
