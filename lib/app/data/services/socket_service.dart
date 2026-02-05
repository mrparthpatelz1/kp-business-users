import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/api_constants.dart';
import 'storage_service.dart';

class SocketService extends GetxService {
  late IO.Socket socket;
  final StorageService _storage = Get.find<StorageService>();
  final RxBool isConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize lazily or immediately?
    // Usually good to init if logged in.
    if (_storage.accessToken != null) {
      initSocket();
    }
  }

  void initSocket() {
    final token = _storage.accessToken;
    if (token == null) return;

    final uri = Uri.parse(ApiConstants.baseUrl);
    final socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Socket connected');
      isConnected.value = true;
    });

    socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
      isConnected.value = false;
    });

    socket.onConnectError((err) {
      debugPrint('Socket connect error: $err');
    });

    socket.onError((err) {
      debugPrint('Socket error: $err');
    });
  }

  void joinConversation(String conversationId) {
    if (isConnected.value) {
      socket.emit('join_conversation', conversationId);
    }
  }

  void sendMessage(String conversationId, String content, int? receiverId) {
    if (isConnected.value) {
      socket.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'receiverId': receiverId,
      });
    }
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
    }
  }
}
