import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import 'chat_controller.dart';
import 'chat_detail_view.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Obx(() {
        if (controller.isLoadingConversations.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 2.h),
                Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(4.w),
          itemCount: controller.conversations.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final conversation = controller.conversations[index];
            final otherUser = conversation['other_user'];

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: otherUser['photo'] != null
                    ? NetworkImage(ApiConstants.getFullUrl(otherUser['photo']))
                    : null,
                child: otherUser['photo'] == null
                    ? Text(
                        (otherUser['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                otherUser['name'] ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Check new messages', // Ideally show last message preview if available
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              onTap: () {
                Get.to(
                  () => const ChatDetailView(),
                  arguments: {
                    'conversationId': conversation['id'].toString(),
                    'receiverId': otherUser['id'],
                    'receiverName': otherUser['name'],
                  },
                );
              },
            );
          },
        );
      }),
    );
  }
}
