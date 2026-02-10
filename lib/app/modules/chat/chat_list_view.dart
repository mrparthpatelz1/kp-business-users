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
    // Use Get.find to get the existing ChatController (already put by main_view)
    // Fallback to Get.put if not found
    final controller = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    // Refresh conversations every time this view is shown
    controller.loadConversations();
    controller.loadUnreadCount();

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingConversations.value &&
              controller.conversations.isEmpty) {
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

          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadConversations();
              await controller.loadUnreadCount();
            },
            child: ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: controller.conversations.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final conversation = controller.conversations[index];
                final otherUser = conversation['other_user'];
                final int unreadCount = conversation['unread_count'] is int
                    ? conversation['unread_count']
                    : int.tryParse(
                            conversation['unread_count']?.toString() ?? '0',
                          ) ??
                          0;
                final String? lastMessage = conversation['last_message'];
                final String? photoPath = otherUser['photo'];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage: photoPath != null
                        ? NetworkImage(ApiConstants.getFullUrl(photoPath))
                        : null,
                    child: photoPath == null
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
                    style: TextStyle(
                      fontWeight: unreadCount > 0
                          ? FontWeight.w800
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage ?? 'Start a conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? Colors.black87
                          : Colors.grey[600],
                      fontWeight: unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () async {
                    await Get.to(
                      () => const ChatDetailView(),
                      arguments: {
                        'conversationId': conversation['id'].toString(),
                        'receiverId': otherUser['id'],
                        'receiverName': otherUser['name'],
                        'receiverPhoto': photoPath,
                      },
                    );
                    // Refresh when returning from chat detail
                    controller.loadConversations();
                    controller.loadUnreadCount();
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
