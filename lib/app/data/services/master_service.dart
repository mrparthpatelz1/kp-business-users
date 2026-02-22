import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../../core/constants/api_constants.dart';
import '../providers/api_provider.dart';

class MasterService extends GetxService {
  final ApiProvider _api = Get.find<ApiProvider>();

  // Get all villages
  Future<List<Map<String, dynamic>>> getVillages() async {
    try {
      debugPrint(
        'MasterService: Fetching villages from ${ApiConstants.villages}',
      );
      final response = await _api.get(ApiConstants.villages);
      debugPrint('MasterService: Villages response: ${response.data}');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      debugPrint('MasterService: Error fetching villages: $e');
      return [];
    }
  }

  // Get business types
  Future<List<Map<String, dynamic>>> getBusinessTypes() async {
    try {
      final response = await _api.get(ApiConstants.businessTypes);
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  // Get business categories
  Future<List<Map<String, dynamic>>> getBusinessCategories() async {
    try {
      final response = await _api.get(ApiConstants.businessCategories);
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  // Get all business subcategories (unlinked from category)
  Future<List<Map<String, dynamic>>> getBusinessSubcategories() async {
    try {
      final response = await _api.get(ApiConstants.businessSubcategories);
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  // Get job types
  Future<List<Map<String, dynamic>>> getJobTypes() async {
    try {
      final response = await _api.get(ApiConstants.jobTypes);
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  // Get job categories
  Future<List<Map<String, dynamic>>> getJobCategories() async {
    try {
      final response = await _api.get(ApiConstants.jobCategories);
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  // Get all job subcategories (unlinked from category)
  Future<List<Map<String, dynamic>>> getJobSubcategories() async {
    try {
      final response = await _api.get(ApiConstants.jobSubcategories);
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  // Search business by name
  Future<List<Map<String, dynamic>>> searchBusiness(String name) async {
    try {
      final response = await _api.get('${ApiConstants.searchBusiness}/$name');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  // =================== Location APIs ===================

  // Get all countries
  Future<List<Map<String, dynamic>>> getCountries() async {
    try {
      debugPrint(
        'MasterService: Fetching countries from ${ApiConstants.countries}',
      );
      final response = await _api.get(ApiConstants.countries);
      debugPrint(
        'MasterService: Countries response length: ${response.data['data']?.length}',
      );
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      debugPrint('MasterService: Error fetching countries: $e');
      return [];
    }
  }

  // Get states by country code
  Future<List<Map<String, dynamic>>> getStates(String countryCode) async {
    try {
      debugPrint('MasterService: Fetching states for $countryCode');
      final response = await _api.get('${ApiConstants.states}/$countryCode');
      debugPrint(
        'MasterService: States response length: ${response.data['data']?.length}',
      );
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      debugPrint('MasterService: Error fetching states: $e');
      return [];
    }
  }

  // Get cities by country and state code
  Future<List<Map<String, dynamic>>> getCities(
    String countryCode,
    String stateCode,
  ) async {
    try {
      final response = await _api.get(
        '${ApiConstants.cities}/$countryCode/$stateCode',
      );
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  // Get country dial codes
  List<Map<String, String>> getCountryDialCodes() {
    return [
      {'code': '+91', 'country': 'IN', 'name': 'India'},
      {'code': '+1', 'country': 'US', 'name': 'USA'},
      {'code': '+44', 'country': 'GB', 'name': 'UK'},
      {'code': '+971', 'country': 'AE', 'name': 'UAE'},
      {'code': '+966', 'country': 'SA', 'name': 'Saudi Arabia'},
      {'code': '+974', 'country': 'QA', 'name': 'Qatar'},
      {'code': '+968', 'country': 'OM', 'name': 'Oman'},
      {'code': '+965', 'country': 'KW', 'name': 'Kuwait'},
      {'code': '+973', 'country': 'BH', 'name': 'Bahrain'},
      {'code': '+61', 'country': 'AU', 'name': 'Australia'},
      {'code': '+65', 'country': 'SG', 'name': 'Singapore'},
      {'code': '+60', 'country': 'MY', 'name': 'Malaysia'},
      {'code': '+49', 'country': 'DE', 'name': 'Germany'},
      {'code': '+33', 'country': 'FR', 'name': 'France'},
      {'code': '+39', 'country': 'IT', 'name': 'Italy'},
      {'code': '+81', 'country': 'JP', 'name': 'Japan'},
      {'code': '+86', 'country': 'CN', 'name': 'China'},
      {'code': '+82', 'country': 'KR', 'name': 'South Korea'},
      {'code': '+27', 'country': 'ZA', 'name': 'South Africa'},
      {'code': '+254', 'country': 'KE', 'name': 'Kenya'},
      {'code': '+234', 'country': 'NG', 'name': 'Nigeria'},
    ];
  }
}
