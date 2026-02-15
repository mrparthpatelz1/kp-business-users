import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';
import '../../data/services/storage_service.dart';

class AnnouncementsController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> announcements =
      <Map<String, dynamic>>[].obs;

  /// Unread announcement count
  final RxInt unreadCount = 0.obs;

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
        _calculateUnreadCount();
      }
    } catch (e) {
      debugPrint('Error loading announcements: $e');
    }
    isLoading.value = false;
  }

  /// Calculate how many announcements are unread based on last viewed time
  void _calculateUnreadCount() {
    final lastViewedTime = _storage.getLastViewedAnnouncementsTime();

    // If first time (lastViewedTime is 0), don't show badges.
    // Just mark current time and consider all as "seen" for notification purposes.
    if (lastViewedTime == 0) {
      unreadCount.value = 0;
      markAllAsSeen(); // Initialize timestamp
      return;
    }

    int count = 0;
    // We assume announcements are sorted by date or have created_at
    // But since API returns list, let's iterate.
    // We need to parse 'created_at' string to timestamp.
    for (final a in announcements) {
      if (a['created_at'] != null) {
        try {
          final createdTime = DateTime.parse(
            a['created_at'],
          ).millisecondsSinceEpoch;
          if (createdTime > lastViewedTime) {
            count++;
          }
        } catch (e) {
          // ignore parsing error
        }
      }
    }
    unreadCount.value = count;
  }

  /// Mark all announcements as seen (store latest timestamp)
  void markAllAsSeen() {
    _storage.setLastViewedAnnouncementsTime(
      DateTime.now().millisecondsSinceEpoch,
    );
    unreadCount.value = 0;
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
