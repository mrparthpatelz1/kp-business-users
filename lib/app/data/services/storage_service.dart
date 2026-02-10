import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';

class StorageService extends GetxService {
  final GetStorage _storage = GetStorage();

  // Token management
  String? get accessToken => _storage.read(StorageKeys.accessToken);
  set accessToken(String? value) =>
      _storage.write(StorageKeys.accessToken, value);

  String? get refreshToken => _storage.read(StorageKeys.refreshToken);
  set refreshToken(String? value) =>
      _storage.write(StorageKeys.refreshToken, value);

  // User data
  Map<String, dynamic>? get user => _storage.read(StorageKeys.user);
  set user(Map<String, dynamic>? value) =>
      _storage.write(StorageKeys.user, value);

  // Login state
  bool get isLoggedIn => _storage.read(StorageKeys.isLoggedIn) ?? false;
  set isLoggedIn(bool value) => _storage.write(StorageKeys.isLoggedIn, value);

  // Onboarding
  bool get onboardingComplete =>
      _storage.read(StorageKeys.onboardingComplete) ?? false;
  set onboardingComplete(bool value) =>
      _storage.write(StorageKeys.onboardingComplete, value);

  // Clear all data (logout)
  void clearAll() {
    _storage.remove(StorageKeys.accessToken);
    _storage.remove(StorageKeys.refreshToken);
    _storage.remove(StorageKeys.user);
    _storage.write(StorageKeys.isLoggedIn, false);
  }

  // Save tokens
  void saveTokens(String access, String refresh) {
    accessToken = access;
    refreshToken = refresh;
    isLoggedIn = true;
  }

  // Announcement seen tracking
  int getLastSeenAnnouncementId() {
    return _storage.read('last_seen_announcement_id') ?? 0;
  }

  void setLastSeenAnnouncementId(int id) {
    _storage.write('last_seen_announcement_id', id);
  }

  // Helper to extract numeric User ID from JWT token
  // This bypasses the issue where API returns UUID as 'id' in user object
  int getUserIdFromToken() {
    final token = accessToken;
    if (token == null) return 0;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 0;
      final payload = parts[1];
      // Fix base64 padding
      String normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(resp);
      if (payloadMap is Map<String, dynamic>) {
        final userId = payloadMap['userId'];
        if (userId is int) return userId;
        if (userId is String) return int.tryParse(userId) ?? 0;
      }
    } catch (e) {
      print('Error parsing token: $e');
    }
    return 0;
  }
}
