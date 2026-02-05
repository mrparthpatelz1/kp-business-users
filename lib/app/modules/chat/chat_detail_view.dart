import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import 'chat_controller.dart';

class ChatDetailView extends StatefulWidget {
  const ChatDetailView({super.key});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final ChatController controller = Get.find<ChatController>();
  late String conversationId;
  late int receiverId;
  late String receiverName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    conversationId = args['conversationId'];
    receiverId = args['receiverId'];
    receiverName = args['receiverName'] ?? 'Chat';

    controller.loadMessages(conversationId, receiverId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                receiverName.isNotEmpty ? receiverName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(receiverName, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMessages.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.messages.isEmpty) {
                return Center(
                  child: Text(
                    'Say hello!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }

              return ListView.builder(
                reverse: true, // Messages from bottom up
                itemCount: controller.messages.length,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  // Determine alignment
                  // We need to know 'current user id'.
                  // Controller doesn't expose it directly yet, but we can infer or store it.
                  // Or checks 'sender_id' vs 'receiverId'.
                  // If sender_id == receiverId, it's incoming. Else outgoing.

                  final isMe = message['sender_id'] != receiverId;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: 1.h,
                        left: isMe ? 15.w : 0,
                        right: isMe ? 0 : 15.w,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primaryColor : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16),
                        ),
                      ),
                      child: Text(
                        message['content'] ?? '',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 2.w),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => controller.sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
