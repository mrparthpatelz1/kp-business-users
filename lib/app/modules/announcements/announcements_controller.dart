import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';

class AnnouncementsController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();

  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> announcements =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    isLoading.value = true;
    try {
      final response = await _api.get(ApiConstants.announcements);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        announcements.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading announcements: $e');
    }
    isLoading.value = false;
  }

  Future<Map<String, dynamic>?> getAnnouncementDetail(String id) async {
    try {
      final response = await _api.get('${ApiConstants.announcements}/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('Error loading announcement detail: $e');
    }
    return null;
  }
}
