import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import 'chat_controller.dart';
import '../../routes/app_routes.dart';

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
  String? receiverPhoto;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    conversationId = args['conversationId'];
    receiverId = args['receiverId'];
    receiverName = args['receiverName'] ?? 'Chat';
    receiverPhoto = args['receiverPhoto'];

    controller.loadMessages(conversationId, receiverId);
  }

  @override
  void dispose() {
    controller.currentConversationId = null;
    controller.currentReceiverId = null;
    controller.loadConversations();
    controller.loadUnreadCount();
    super.dispose();
  }

  void _showMessageOptions(
    BuildContext context,
    Map<String, dynamic> message,
    bool isMe,
  ) {
    final isDeleted =
        message['is_deleted'] == true || message['is_deleted'] == 1;
    if (isDeleted) return;

    final hasAttachment =
        message['attachment_url'] != null &&
        message['attachment_url'].toString().isNotEmpty;

    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: Wrap(
          children: [
            if (!hasAttachment)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Get.back();
                  Clipboard.setData(
                    ClipboardData(text: message['content'] ?? ''),
                  );
                  Get.snackbar(
                    'Success',
                    'Message copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 1),
                  );
                },
              ),
            if (hasAttachment)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Get.back();
                  controller.downloadAttachment(
                    message['attachment_url'],
                    message['attachment_name'] ??
                        'file_${DateTime.now().millisecondsSinceEpoch}',
                  );
                },
              ),
            if (isMe) ...[
              if (!hasAttachment)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Get.back();
                    _showEditDialog(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Get.back();
                  _showDeleteConfirmDialog(message['uuid']);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> message) {
    final TextEditingController editController = TextEditingController(
      text: message['content'],
    );

    Get.defaultDialog(
      title: 'Edit Message',
      content: TextField(
        controller: editController,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        maxLines: 3,
        minLines: 1,
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (editController.text.trim().isNotEmpty) {
          controller.editMessage(message['uuid'], editController.text.trim());
          Get.back();
        }
      },
    );
  }

  void _showDeleteConfirmDialog(String uuid) {
    Get.defaultDialog(
      title: 'Delete Message',
      middleText: 'Are you sure you want to delete this message?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        controller.deleteMessage(uuid);
        Get.back();
      },
    );
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'pdf',
          'doc',
          'docx',
        ],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        controller.uploadAndSendFile(file);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not pick file');
    }
  }

  bool _isImageAttachment(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  Widget _buildAttachment(Map<String, dynamic> message, bool isMe) {
    final attachmentUrl = message['attachment_url']?.toString();
    final attachmentName = message['attachment_name']?.toString() ?? 'File';

    if (attachmentUrl == null) return const SizedBox.shrink();

    final fullUrl = ApiConstants.getFullUrl(attachmentUrl);

    if (_isImageAttachment(attachmentUrl)) {
      return GestureDetector(
        onTap: () => _showFullImage(fullUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fullUrl,
            width: 200,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                color: isMe ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  color: isMe ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Document attachment
    return GestureDetector(
      onTap: () {
        // Could open URL in browser
        Get.snackbar(
          'File',
          attachmentName,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isMe ? Colors.white24 : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(attachmentName),
              color: isMe ? Colors.white : AppTheme.primaryColor,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Flexible(
              child: Text(
                attachmentName,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 13.sp,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.doc') || lower.endsWith('.docx'))
      return Icons.description;
    return Icons.attach_file;
  }

  void _showFullImage(String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url)),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            // Navigate to profile
            Get.toNamed(
              Routes.OTHER_USER_PROFILE,
              arguments: {'userId': receiverId},
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: receiverPhoto != null
                    ? NetworkImage(ApiConstants.getFullUrl(receiverPhoto!))
                    : null,
                child: receiverPhoto == null
                    ? Text(
                        receiverName.isNotEmpty
                            ? receiverName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(receiverName, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
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
                    final isMe = message['sender_id'] != receiverId;
                    final isDeleted =
                        message['is_deleted'] == true ||
                        message['is_deleted'] == 1;
                    final isRead =
                        message['is_read'] == 1 ||
                        message['is_read'] == true ||
                        message['is_read'].toString() == '1' ||
                        message['is_read'].toString() == 'true';
                    final hasAttachment =
                        message['attachment_url'] != null &&
                        message['attachment_url'].toString().isNotEmpty;

                    return Align(
                      key: ValueKey(message['uuid'] ?? message['id']),
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          _showMessageOptions(context, message, isMe);
                        },
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 80.w),
                          margin: EdgeInsets.only(
                            bottom: 1.h,
                            left: isMe ? 15.w : 2.w,
                            right: isMe ? 2.w : 15.w,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.2.h,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppTheme.primaryColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Attachment (if any)
                              if (hasAttachment && !isDeleted) ...[
                                _buildAttachment(message, isMe),
                                SizedBox(height: 0.5.h),
                              ],
                              // Text Content
                              Container(
                                child: Text(
                                  isDeleted
                                      ? '🚫 This message was deleted'
                                      : (message['content'] ?? ''),
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: isDeleted
                                        ? (isMe
                                              ? Colors.white70
                                              : Colors.black54)
                                        : (isMe
                                              ? Colors.white
                                              : Colors.black87),
                                    fontSize: 15.sp,
                                    fontStyle: isDeleted
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (message['is_edited'] == true &&
                                      !isDeleted)
                                    Padding(
                                      padding: EdgeInsets.only(right: 1.w),
                                      child: Text(
                                        'Edited',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    DateTime.tryParse(
                                          message['created_at'].toString(),
                                        )?.toLocal().toString().substring(
                                          11,
                                          16,
                                        ) ??
                                        '',
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.grey[600],
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    SizedBox(width: 1.5.w),
                                    Icon(
                                      isRead ? Icons.done_all : Icons.check,
                                      size: 16.sp,
                                      color: isRead
                                          ? Colors.lightBlueAccent
                                          : Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // Upload indicator
            Obx(() {
              if (!controller.isUploading.value) return const SizedBox.shrink();
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Uploading file...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              );
            }),

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
                  // Attach button
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                    onPressed: _pickAndSendFile,
                  ),
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
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => controller.sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
