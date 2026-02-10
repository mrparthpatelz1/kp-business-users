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

  /// Calculate how many announcements are unread based on last seen ID
  void _calculateUnreadCount() {
    final lastSeenId = _storage.getLastSeenAnnouncementId();
    if (lastSeenId == 0) {
      // Never opened announcements - all are unread
      unreadCount.value = announcements.length;
    } else {
      int count = 0;
      for (final a in announcements) {
        final aid = a['id'] is int
            ? a['id']
            : int.tryParse(a['id'].toString()) ?? 0;
        if (aid > lastSeenId) {
          count++;
        }
      }
      unreadCount.value = count;
    }
  }

  /// Mark all announcements as seen (store latest ID)
  void markAllAsSeen() {
    if (announcements.isNotEmpty) {
      int maxId = 0;
      for (final a in announcements) {
        final aid = a['id'] is int
            ? a['id']
            : int.tryParse(a['id'].toString()) ?? 0;
        if (aid > maxId) maxId = aid;
      }
      _storage.setLastSeenAnnouncementId(maxId);
      unreadCount.value = 0;
    }
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
