import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import 'blocked_users_controller.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/user_avatar.dart';

class BlockedUsersView extends GetView<BlockedUsersController> {
  const BlockedUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    // We register it here or via AppPages
    if (!Get.isRegistered<BlockedUsersController>()) {
      Get.put(BlockedUsersController());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return ListView.builder(
            itemCount: 5,
            padding: EdgeInsets.all(4.w),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: const ShimmerDirectory(),
            ),
          );
        }

        if (controller.blockedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 20.w, color: Colors.grey),
                SizedBox(height: 2.h),
                Text(
                  'No blocked users',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(2.w),
          itemCount: controller.blockedUsers.length,
          itemBuilder: (context, index) {
            final user = controller.blockedUsers[index];
            return Card(
              margin: EdgeInsets.only(bottom: 2.h),
              elevation: 0,
              color: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                leading: UserAvatar(
                  radius: 25,
                  imageUrl: user['profile_picture'],
                  name: user['full_name'] ?? 'User',
                ),
                title: Text(
                  '${user['full_name'] ?? ''} ${user['surname'] ?? ''}'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: TextButton(
                  onPressed: () => controller.unblockUser(user['uuid'], user['full_name']),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Unblock', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
