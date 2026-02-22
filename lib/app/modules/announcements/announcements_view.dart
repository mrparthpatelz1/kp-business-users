import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import 'announcements_controller.dart';
import '../../core/utils/date_utils.dart';

class AnnouncementsView extends GetView<AnnouncementsController> {
  const AnnouncementsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 60.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No announcements yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadAnnouncements(),
            child: ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: controller.announcements.length,
              itemBuilder: (context, index) {
                return _buildAnnouncementCard(
                  context,
                  controller.announcements[index],
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _showAnnouncementDetail(context, announcement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.campaign, color: AppTheme.primaryColor),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement['title'] ?? '',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _formatDate(announcement['created_at']),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              if (announcement['content'] != null) ...[
                SizedBox(height: 1.5.h),
                Text(
                  announcement['content'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (announcement['image_url'] != null) ...[
                SizedBox(height: 1.5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ApiConstants.getFullUrl(announcement['image_url']),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetail(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        announcement['title'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  _formatDate(announcement['created_at']),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                if (announcement['image_url'] != null) ...[
                  SizedBox(height: 2.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      ApiConstants.getFullUrl(announcement['image_url']),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                SizedBox(height: 2.h),
                Text(
                  announcement['content'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    return AppDateUtils.formatDate(dateString);
  }
}
