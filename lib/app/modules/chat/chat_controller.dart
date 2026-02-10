import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';
import '../../data/services/socket_service.dart';
import '../../data/services/storage_service.dart';

class ChatController extends GetxController with WidgetsBindingObserver {
  final ApiProvider _api = Get.find<ApiProvider>();
  final SocketService _socketService = Get.put(
    SocketService(),
  ); // Ensure initialized

  final StorageService _storage = Get.find<StorageService>();

  final RxList<Map<String, dynamic>> conversations =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingConversations = false.obs;
  final RxBool isLoadingMessages = false.obs;

  /// Total unread message count across all conversations
  final RxInt totalUnreadCount = 0.obs;

  /// Whether a file is currently being uploaded
  final RxBool isUploading = false.obs;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String? currentConversationId;
  int? currentReceiverId;

  // Computed property for current user ID
  int get currentUserId {
    // Try to get from token first (Numeric ID) - This is the most reliable source for Socket/DB ID
    final tokenUserId = _storage.getUserIdFromToken();
    if (tokenUserId > 0) {
      return tokenUserId;
    }

    // Fallback to storage object (which might have UUID as ID due to transformer)
    final user = _storage.user;
    if (user == null) return 0;

    final id = user['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadConversations();
    loadUnreadCount();

    // Initialize socket if not already
    if (!_socketService.isConnected.value) {
      _socketService.initSocket();
    }

    // React to connection status
    ever(_socketService.isConnected, (connected) {
      if (connected) {
        _listenToSocket();
        // Re-join conversation if active
        if (currentConversationId != null) {
          _socketService.joinConversation(currentConversationId!);
        }
      }
    });

    // Listen immediately if already connected
    if (_socketService.isConnected.value) {
      _listenToSocket();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_socketService.isConnected.value) {
        _socketService.initSocket();
      } else if (currentConversationId != null) {
        _socketService.joinConversation(currentConversationId!);
      }
      // Refresh unread count when app resumes
      loadUnreadCount();
    }
  }

  void _listenToSocket() {
    // Avoid multiple listeners
    _socketService.socket.off('receive_message');
    _socketService.socket.off('message_read');
    _socketService.socket.off('message_deleted');
    _socketService.socket.off('message_edited');

    _socketService.socket.on('receive_message', (data) {
      if (data['conversation_id'].toString() == currentConversationId) {
        // Check if we already have this message (deduplication for optimistic UI)
        final existingIndex = messages.indexWhere(
          (m) =>
              m['uuid'] == data['uuid'] ||
              (m['content'] == data['content'] &&
                  m['sender_id'].toString() == data['sender_id'].toString() &&
                  m['is_local'] == true),
        );

        if (existingIndex != -1) {
          var newMessage = Map<String, dynamic>.from(data);
          if (messages[existingIndex]['is_read'] == 1 ||
              messages[existingIndex]['is_read'] == true) {
            newMessage['is_read'] = 1;
          }
          messages[existingIndex] = newMessage;
        } else {
          messages.insert(0, data);

          // Mark as read immediately if we are looking at this conversation
          if (data['sender_id'].toString() != currentUserId.toString()) {
            markAsRead(data['id'], data['sender_id']);
          }
        }
      } else {
        // Message for another conversation - refresh conversations and unread count
        loadConversations();
        loadUnreadCount();
      }
    });

    _socketService.socket.on('message_read', (data) {
      final readConversationId = data['conversationId'].toString();

      if (readConversationId == currentConversationId) {
        // Mark all my messages as read in the current view
        bool changed = false;

        for (var i = 0; i < messages.length; i++) {
          final msgSender = messages[i]['sender_id'];
          final isRead = messages[i]['is_read'];

          bool isMe = msgSender.toString() == currentUserId.toString();
          bool isUnread =
              isRead == 0 ||
              isRead == false ||
              isRead == '0' ||
              isRead == 'false';

          if (isMe && isUnread) {
            messages[i] = {...messages[i], 'is_read': 1};
            changed = true;
          }
        }

        if (changed) {
          messages.refresh();
        }
      }
      // Also update unread counts (someone read our messages or we read theirs)
      loadUnreadCount();
      loadConversations();
    });

    _socketService.socket.on('message_deleted', (data) {
      final uuid = data['uuid'];
      final index = messages.indexWhere((m) => m['uuid'] == uuid);
      if (index != -1) {
        messages[index] = {...messages[index], 'is_deleted': true};
        messages.refresh();
      }
    });

    _socketService.socket.on('message_edited', (data) {
      final uuid = data['uuid'];
      final newContent = data['newContent'];
      final index = messages.indexWhere((m) => m['uuid'] == uuid);
      if (index != -1) {
        messages[index] = {
          ...messages[index],
          'content': newContent,
          'is_edited': true,
        };
        messages.refresh();
      }
    });

    _socketService.socket.on('error', (err) {
      // silent
    });
  }

  /// Load total unread message count from server
  Future<void> loadUnreadCount() async {
    try {
      final response = await _api.get(
        '${ApiConstants.baseUrl}/chat/unread-count',
      );
      if (response.statusCode == 200) {
        final count = response.data['data']?['unread_count'] ?? 0;
        totalUnreadCount.value = count is int
            ? count
            : int.tryParse(count.toString()) ?? 0;
      }
    } catch (e) {
      // silent
    }
  }

  Future<void> loadConversations() async {
    isLoadingConversations.value = true;
    try {
      final response = await _api.get(
        '${ApiConstants.baseUrl}/chat/conversations',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        conversations.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // silent
    }
    isLoadingConversations.value = false;
  }

  Future<void> loadMessages(String conversationId, int receiverId) async {
    currentConversationId = conversationId;
    currentReceiverId = receiverId;

    isLoadingMessages.value = true;
    messages.clear();

    // Join socket room
    _socketService.joinConversation(conversationId);

    // Re-register socket listeners to ensure they fire for this conversation
    _listenToSocket();

    try {
      final response = await _api.get(
        '${ApiConstants.baseUrl}/chat/$conversationId/messages',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        messages.value = data.cast<Map<String, dynamic>>();

        if (messages.isNotEmpty) {
          _markConversationAsRead(conversationId, receiverId);
        }
      }
    } catch (e) {
      // silent
    }
    isLoadingMessages.value = false;
  }

  Future<void> _markConversationAsRead(
    String conversationId,
    int receiverId,
  ) async {
    try {
      _socketService.socket.emit('mark_read', {
        'conversationId': conversationId,
        'senderId': currentUserId,
      });
      // Refresh unread count after marking as read
      loadUnreadCount();
    } catch (e) {
      // silent
    }
  }

  void markAsRead(int messageId, int senderId) {
    if (currentConversationId != null) {
      _socketService.socket.emit('mark_read', {
        'conversationId': currentConversationId,
        'senderId': currentUserId,
      });
      loadUnreadCount();
    }
  }

  void deleteMessage(String uuid) {
    _socketService.socket.emit('delete_message', {
      'uuid': uuid,
      'conversationId': currentConversationId,
    });
    final index = messages.indexWhere((m) => m['uuid'] == uuid);
    if (index != -1) {
      messages[index] = {...messages[index], 'is_deleted': true};
      messages.refresh();
    }
  }

  void editMessage(String uuid, String newContent) {
    _socketService.socket.emit('edit_message', {
      'uuid': uuid,
      'conversationId': currentConversationId,
      'newContent': newContent,
    });
    final index = messages.indexWhere((m) => m['uuid'] == uuid);
    if (index != -1) {
      messages[index] = {
        ...messages[index],
        'content': newContent,
        'is_edited': true,
      };
      messages.refresh();
    }
  }

  Future<void> startConversation(int targetUserId) async {
    try {
      final response = await _api.post(
        '${ApiConstants.baseUrl}/chat/conversation',
        data: {'targetUserId': targetUserId},
      );

      if (response.statusCode == 200) {
        final conversation = response.data['data'];
        final conversationId = conversation['id'].toString();

        Get.toNamed(
          '/chat-detail',
          arguments: {
            'conversationId': conversationId,
            'receiverId': targetUserId,
            'receiverName': 'Chat',
          },
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not start conversation');
    }
  }

  void sendMessage({String? attachmentUrl, String? attachmentName}) {
    final content = messageController.text.trim();
    // Allow sending if there's content OR an attachment
    if (content.isEmpty && attachmentUrl == null) return;
    if (currentConversationId == null) return;

    final String uuid =
        '${DateTime.now().millisecondsSinceEpoch}-${(1000 + (DateTime.now().microsecond % 9000))}';

    final tempMessage = {
      'id': -1,
      'conversation_id':
          int.tryParse(currentConversationId!) ?? currentConversationId,
      'sender_id': currentUserId,
      'content': content.isNotEmpty ? content : '📎 Attachment',
      'created_at': DateTime.now().toIso8601String(),
      'is_local': true,
      'uuid': uuid,
      'is_read': 0,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (attachmentName != null) 'attachment_name': attachmentName,
    };

    messages.insert(0, tempMessage);
    messageController.clear();

    _socketService.socket.emit('send_message', {
      'conversationId': currentConversationId,
      'content': content.isNotEmpty ? content : '📎 Attachment',
      'receiverId': currentReceiverId,
      'uuid': uuid,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentName != null) 'attachmentName': attachmentName,
    });

    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Upload a file and send it as a chat attachment
  Future<void> uploadAndSendFile(File file) async {
    if (currentConversationId == null) return;

    isUploading.value = true;
    try {
      final formData = dio.FormData.fromMap({
        'attachment': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await _api.post(
        '${ApiConstants.baseUrl}/chat/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        sendMessage(
          attachmentUrl: data['attachment_url'],
          attachmentName: data['attachment_name'],
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload file');
    }
    isUploading.value = false;
  }

  /// Download an attachment to the device
  Future<void> downloadAttachment(String url, String fileName) async {
    try {
      // 1. Check Permissions
      // On Android 13+ (SDK 33+), storage permissions are granular (Photos, Videos, Audio)
      // or not needed for public downloads directory if using specific APIs.
      // But for simplicity with permission_handler:
      // - Android < 13: Request storage
      // - Android 13+: Request specific or just try (Manage External Storage is too broad)
      // - iOS: Not needed for app sandbox, but needed for Photos.
      // Let's assume standard external storage for now.

      /*
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.snackbar(
            'Permission Denied',
            'Storage permission is required to download files',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }
      */
      // Note: On Android 13, Permission.storage always returns denied.
      // We should use check logic based on OS version or try-catch the download.
      // For this implementation plan, we will try to get the directory and download.

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        // Fallback or verify exists
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        Get.snackbar('Error', 'Could not find storage directory');
        return;
      }

      final savePath = '${directory.path}/$fileName';

      // Show Progress Dialog
      Get.dialog(
        Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Downloading $fileName...'),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final fullUrl = ApiConstants.getFullUrl(url);

      await _api.download(
        fullUrl,
        savePath,
        onReceiveProgress: (received, total) {
          // Optional: Update progress
        },
      );

      // Close Progress Dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Show Success Dialog
      Get.dialog(
        Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Download Complete',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('File saved to:\n$savePath'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        OpenFile.open(savePath);
                      },
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Download Error: $e');
      // Close Progress Dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to download file',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
