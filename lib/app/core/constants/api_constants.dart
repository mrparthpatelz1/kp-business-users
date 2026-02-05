class ApiConstants {
  // Use localhost for Chrome/web, use your machine IP for mobi  // static const String baseUrl = 'http://localhost:3000/api/v1'; // For Chrome
  // static const String baseUrl = 'https://api.48kadavapatidarparivar.cloud/api/v1'; // Production URL
  static const String baseUrl = 'https://staging.48kadavapatidarparivar.cloud/api/v1'; // Staging URL

  static String get assetBaseUrl => baseUrl.replaceAll('/api/v1', '');

  /// Helper to get full image URL dynamicallly
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return '$assetBaseUrl$path';
    return '$assetBaseUrl/$path';
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String checkUsername = '/auth/check-username';
  static const String checkEmail = '/auth/check-email';
  static const String checkPhone = '/auth/check-phone';
  static const String changePassword = '/auth/change-password';
  static const String profile = '/auth/profile';

  // Master data endpoints
  static const String villages = '/master/villages';
  static const String businessTypes = '/master/business-types';
  static const String businessCategories = '/master/business-categories';
  static const String businessSubcategories = '/master/business-subcategories';
  static const String jobTypes = '/master/job-types';
  static const String jobCategories = '/master/job-categories';
  static const String jobSubcategories = '/master/job-subcategories';
  static const String searchBusiness = '/master/search-business';

  // Location endpoints
  static const String countries = '/master/countries';
  static const String states = '/master/states';
  static const String cities = '/master/cities';

  // User Directory endpoints
  static const String directory = '/directory';
  static const String directorySearch = '/directory/search';

  // Announcements endpoints
  static const String announcements = '/announcements';

  // Posts endpoints
  static const String posts = '/posts';
  static const String myPosts = '/posts/my';

  // User settings endpoints
  static const String updateFcmToken = '/fcm-token';
  static const String userProfile = '/profile';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String user = 'user';
  static const String isLoggedIn = 'is_logged_in';
  static const String onboardingComplete = 'onboarding_complete';
}
