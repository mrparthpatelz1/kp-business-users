import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';
import '../../data/services/socket_service.dart';
import '../../data/services/storage_service.dart';

class ChatController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();
  final SocketService _socketService = Get.put(
    SocketService(),
  ); // Ensure initialized

  final RxList<Map<String, dynamic>> conversations =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingConversations = false.obs;
  final RxBool isLoadingMessages = false.obs;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String? currentConversationId;
  int? currentReceiverId;

  @override
  void onInit() {
    super.onInit();
    loadConversations();

    // Listen to socket messages
    if (_socketService.isConnected.value) {
      _listenToSocket();
    } else {
      ever(_socketService.isConnected, (connected) {
        if (connected) _listenToSocket();
      });
      // Try init if not already
      _socketService.initSocket();
    }
  }

  void _listenToSocket() {
    _socketService.socket.on('receive_message', (data) {
      if (data['conversation_id'].toString() == currentConversationId) {
        messages.insert(0, data); // Prepend new message
      } else {
        // Maybe update conversation last message or show notification badge
        loadConversations();
      }
    });
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
      debugPrint('Error loading conversations: $e');
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

    try {
      final response = await _api.get(
        '${ApiConstants.baseUrl}/chat/$conversationId/messages',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        messages.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
    isLoadingMessages.value = false;
  }

  Future<void> startConversation(int targetUserId) async {
    try {
      final response = await _api.post(
        '${ApiConstants.baseUrl}/chat/conversation',
        data: {'targetUserId': targetUserId},
      );

      if (response.statusCode == 200) {
        final conversation = response.data['data'];
        // Navigate to chat detail
        final conversationId = conversation['id'].toString();
        // Find receiver ID (the other user)
        // conversation object structure: {id, user1_id, user2_id ...}
        // We know targetUserId is the other user.

        Get.toNamed(
          '/chat-detail',
          arguments: {
            'conversationId': conversationId,
            'receiverId': targetUserId,
            'receiverName': 'Chat', // Ideally pass name
          },
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not start conversation');
    }
  }

  void sendMessage() {
    final content = messageController.text.trim();
    if (content.isEmpty || currentConversationId == null) return;

    _socketService.sendMessage(
      currentConversationId!,
      content,
      currentReceiverId,
    );
    messageController.clear();

    // Optimistically add message or wait for socket?
    // Socket usually echoes back 'receive_message', so waiting is safer strictly speaking,
    // but optimistic UI is better.
    // However, our socket implementation in backend emits 'receive_message' to everyone in room including sender.
    // So if we add here AND listen to socket, we might duplicate.
    // Let's rely on socket event for now to be simple and accurate.
  }
}
