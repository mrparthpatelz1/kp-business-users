import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

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
    loadAnnouncements().then((_) => checkAndShowAnnouncementPopup());
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

  /// Check if there's a new announcement and show a popup if it's the first time for this session/announcement
  Future<void> checkAndShowAnnouncementPopup() async {
    if (announcements.isEmpty) return;

    final latest = announcements.first;
    final String? announcementId = latest['uuid'] ?? latest['id']?.toString();

    if (announcementId == null) return;

    // Check if this specific announcement has already been shown as a popup
    final lastShownId = _storage.lastShownAnnouncementPopupId;

    if (lastShownId != announcementId) {
      // Show popup
      _showAnnouncementPopupDialog(latest);
      // Mark as shown
      _storage.lastShownAnnouncementPopupId = announcementId;
    }
  }

  void _showAnnouncementPopupDialog(Map<String, dynamic> announcement) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'New Announcement',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              if (announcement['image_url'] != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ApiConstants.getFullUrl(announcement['image_url']),
                    width: double.infinity,
                    height: 20.h,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                SizedBox(height: 2.h),
              ],
              Text(
                announcement['title'] ?? '',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                announcement['content'] ?? '',
                style: TextStyle(fontSize: 14.sp),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(Routes.ANNOUNCEMENTS);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('View All'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
