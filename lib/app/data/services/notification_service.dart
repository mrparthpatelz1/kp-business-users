import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../providers/api_provider.dart';
import '../../core/constants/api_constants.dart';

/// Handle background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final RxString fcmToken = ''.obs;
  int _fcmTokenRetryCount = 0;
  static const int _maxFcmRetries = 3;

  // Notification channel for Android (HIGH importance for heads-up)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kp_business_notifications', // id
    'KP Business Notifications', // name
    description: 'Notifications for KP Business app',
    importance: Importance.max, // HIGH/MAX for heads-up display
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<NotificationService> init() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permission
    await requestPermission();

    // Get FCM token (but don't upload yet - will upload after login/register)
    await getToken();

    // Handle foreground messages - show heads-up notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle message when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Handle token refresh - only store, don't auto-upload
    _messaging.onTokenRefresh.listen((newToken) {
      fcmToken.value = newToken;
      debugPrint('FCM token refreshed: ${newToken.substring(0, 20)}...');
      // Don't auto-upload on refresh - user will upload on next login
    });

    return this;
  }

  Future<void> _initializeLocalNotifications() async {
    // Android initialization - use app icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization with foreground presentation options
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android 8.0+
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate based on payload
    final payload = response.payload;
    // For local notifications, we might not have the full data map easily available
    // unless we serialized it into the payload string or used a separate field.
    // If payload is just 'chat_message', we can't nav without ID.
    // However, _showHeadsUpNotification currently takes only payload string.
    // Real fix: _showHeadsUpNotification should serialize data into payload
    // OR we just navigate to chat list if data missing.
    if (payload != null) {
      // Check if payload is JSON-like or just type
      // For now, simple handling:
      _handleNotificationNavigation(payload);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
    // message.data contains the key-values sent from server
    final type = message.data['type'];
    if (type != null) {
      _handleNotificationNavigation(type, data: message.data);
    }
  }

  void _handleNotificationNavigation(
    String type, {
    Map<String, dynamic>? data,
  }) {
    switch (type) {
      case 'user_approved':
        Get.offAllNamed('/home');
        break;
      case 'user_rejected':
        Get.offAllNamed('/login');
        break;
      case 'announcement':
        Get.toNamed('/announcements');
        break;
      case 'chat_message':
        if (data != null) {
          final conversationId = data['conversationId'];
          final senderId = data['senderId'];
          if (conversationId != null) {
            Get.toNamed(
              '/chat-detail',
              arguments: {
                'conversationId': conversationId,
                'receiverId': int.tryParse(senderId.toString()) ?? 0,
                'receiverName': 'Chat', // Placeholder, will fetch in view
              },
            );
          }
        }
        break;
      default:
        break;
    }
  }

  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // iOS: Set foreground presentation options to show banner/alert
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, // Show banner/alert
        badge: true,
        sound: true,
      );
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        fcmToken.value = token;
        debugPrint('FCM Token: ${token.substring(0, 20)}...');
        // Don't upload here - will be called explicitly after login/register
      }
      return token;
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Public method to upload FCM token to server (call after login/register)
  Future<void> uploadTokenToServer() async {
    if (fcmToken.value.isEmpty) {
      debugPrint('No FCM token available to upload');
      return;
    }
    debugPrint('Uploading FCM token to server after authentication...');
    _fcmTokenRetryCount = 0; // Reset retry count
    await _sendTokenToServer(fcmToken.value);
  }

  Future<void> _sendTokenToServer(String token) async {
    // Stop retrying if max attempts reached
    if (_fcmTokenRetryCount >= _maxFcmRetries) {
      debugPrint('Max FCM token upload attempts reached, stopping retries');
      return;
    }

    try {
      // Check if ApiProvider is initialized before using it
      if (Get.isRegistered<ApiProvider>()) {
        final api = Get.find<ApiProvider>();
        await api.put(ApiConstants.updateFcmToken, data: {'fcm_token': token});
        debugPrint('FCM token sent to server');
        _fcmTokenRetryCount = 0; // Reset on success
      } else {
        debugPrint('ApiProvider not yet available, will retry in 2 seconds...');
        _fcmTokenRetryCount++;
        // Retry after a delay
        Future.delayed(const Duration(seconds: 2), () {
          _sendTokenToServer(token);
        });
      }
    } catch (e) {
      final errorString = e.toString();
      // Stop retrying on auth errors (401) - user not logged in yet
      if (errorString.contains('401')) {
        debugPrint(
          'FCM token upload failed: Not authenticated (user not logged in yet)',
        );
        _fcmTokenRetryCount = _maxFcmRetries; // Stop retrying
        return;
      }

      debugPrint('Failed to send FCM token to server: $e');
      _fcmTokenRetryCount++;

      // Retry once more after 3 seconds on error (if not max retries)
      if (_fcmTokenRetryCount < _maxFcmRetries) {
        Future.delayed(const Duration(seconds: 3), () {
          _sendTokenToServer(token);
        });
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    // Show heads-up notification using flutter_local_notifications
    if (message.notification != null) {
      _showHeadsUpNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data['type'],
      );
    }
  }

  /// Show a heads-up/banner notification
  Future<void> _showHeadsUpNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Android notification details
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'kp_business_notifications', // Same as channel ID
      'KP Business Notifications',
      channelDescription: 'Notifications for KP Business app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      // usage: NotificationIcon (small) must be a drawable resource.
      // We use ic_launcher (App Icon) or a specific notification icon if available.
      icon: '@mipmap/launcher_icon',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      // Heads-up notification settings
      fullScreenIntent: false,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, // Show banner
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      details,
      payload: payload,
    );
  }
}
