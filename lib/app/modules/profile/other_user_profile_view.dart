import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/user_profile_content.dart';
import 'other_user_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';

class OtherUserProfileView extends GetView<OtherUserProfileController> {
  const OtherUserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.userProfile.value;
        if (user == null) {
          return const Center(child: Text('Unable to load profile'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            // We need to know who we are viewing.
            // Ideally we should store userId in controller to refresh properly.
            // But for now, we rely on initial load. Refresh might need arguments.
            // Actually, controller has arguments from Get.arguments, better to store userId in controller.
            // Let's just rely on initial load for now or improve controller later.
            final args = Get.arguments;
            if (args != null && args['userId'] != null) {
              await controller.loadProfile(args['userId']);
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                // Reuse UserProfileContent
                // We need to slightly modify UserProfileContent to accept posts externally
                // OR we can just modify UserProfileContent to check for OtherUserProfileController too.
                // But for cleaner code, let's just custom build or wrap.
                // Actually UserProfileContent is big.
                // Let's modify UserProfileContent to be more flexible.

                // Wait, I can't easily modify UserProfileContent without checking it again.
                // It checks `if (isOwnProfile && controller != null)`.
                // If I pass `isOwnProfile: false`, it hides "My Posts".

                // I will add the profile header using UserProfileContent (or similar)
                // And then manually add the posts section here.
                UserProfileContent(user: user, isOwnProfile: false),

                SizedBox(height: 2.h),
                _buildPostsSection(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPostsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posts',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 2.h),
        Obx(() {
          if (controller.userPosts.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No posts yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }
          return ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: controller.userPosts.length,
            separatorBuilder: (c, i) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final post = controller.userPosts[index];
              return _buildPostItem(context, post);
            },
          );
        }),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildPostItem(BuildContext context, Map<String, dynamic> post) {
    // This looks similar to _buildMyPostItem in UserProfileContent
    // But without edit/delete buttons
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post['title'] ?? 'No Title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatPostType(post['post_type']),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              post['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 14.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              _formatDate(post['created_at']),
              style: TextStyle(color: Colors.grey, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    return AppDateUtils.formatDate(dateStr);
  }

  String _formatPostType(String? type) {
    if (type == null) return '';
    return type.split('_').map((word) => word.capitalizeFirst).join(' ');
  }
}
