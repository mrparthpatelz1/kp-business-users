import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../../core/constants/api_constants.dart';
import '../providers/api_provider.dart';
import 'storage_service.dart';

class AuthService extends GetxService {
  final ApiProvider _api = Get.find<ApiProvider>();
  final StorageService _storage = Get.find<StorageService>();

  // Observable user state
  final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    isLoggedIn.value = _storage.isLoggedIn;
    currentUser.value = _storage.user;
  }

  // Register new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.register, data: data);
      return {
        'success': true,
        'message': response.data['message'],
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Register with file upload
  Future<Map<String, dynamic>> registerWithFile(FormData formData) async {
    try {
      final response = await _api.postFormData(ApiConstants.register, formData);
      return {
        'success': true,
        'message': response.data['message'],
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String loginId, String password) async {
    try {
      final response = await _api.post(
        ApiConstants.login,
        data: {'login': loginId, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Save tokens
        _storage.saveTokens(
          data['tokens']['access_token'],
          data['tokens']['refresh_token'],
        );

        // Save user data
        _storage.user = data['user'];
        currentUser.value = data['user'];
        isLoggedIn.value = true;

        return {
          'success': true,
          'message': response.data['message'],
          'data': data['user'],
        };
      }

      return {'success': false, 'message': 'Login failed'};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {}

    _storage.clearAll();
    currentUser.value = null;
    isLoggedIn.value = false;
  }

  // Check username availability
  Future<bool> checkUsername(String username) async {
    try {
      final response = await _api.get(
        '${ApiConstants.checkUsername}/$username',
      );
      return response.data['data']['available'] ?? false;
    } catch (_) {
      return true; // Allow registration if check fails
    }
  }

  // Check email availability
  Future<bool> checkEmail(String email) async {
    try {
      debugPrint('AuthService: Checking email availability: $email');
      final response = await _api.get('${ApiConstants.checkEmail}/$email');
      final available = response.data['data']['available'] ?? false;
      debugPrint('AuthService: Email $email available: $available');
      return available;
    } catch (e) {
      debugPrint('AuthService: Error checking email: $e');
      return true; // Allow registration if check fails
    }
  }

  // Check phone availability
  Future<bool> checkPhone(String phone) async {
    try {
      debugPrint('AuthService: Checking phone availability: $phone');
      final response = await _api.get(
        '${ApiConstants.checkPhone}/${Uri.encodeComponent(phone)}',
      );
      final available = response.data['data']['available'] ?? false;
      debugPrint('AuthService: Phone $phone available: $available');
      return available;
    } catch (e) {
      debugPrint('AuthService: Error checking phone: $e');
      return true; // Allow registration if check fails
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _api.get(ApiConstants.profile);
      currentUser.value = response.data['data'];
      _storage.user = response.data['data'];
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await _api.put(
        ApiConstants.changePassword,
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
      return {'success': true, 'message': response.data['message']};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Map<String, dynamic> _handleError(DioException e) {
    String message = 'An error occurred';
    String? code;

    debugPrint('AuthService Error: ${e.type} - ${e.message}');
    debugPrint('AuthService Error URL: ${e.requestOptions.uri}');

    if (e.response != null) {
      message = e.response?.data['message'] ?? message;
      code = e.response?.data['code'];
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please try again.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Server took too long to respond.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Cannot connect to server. Check your network.';
    }

    return {
      'success': false,
      'message': message,
      'code': code,
      'errors': e.response?.data['errors'],
      'data': e.response?.data['data'],
      'reason': e.response?.data['reason'],
    };
  }
}
