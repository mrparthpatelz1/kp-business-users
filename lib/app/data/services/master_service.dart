import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../../core/constants/api_constants.dart';
import '../providers/api_provider.dart';

class MasterService extends GetxService {
  final ApiProvider _api = Get.find<ApiProvider>();

  // Get all villages
  Future<List<Map<String, dynamic>>> getVillages() async {
    try {
      debugPrint('MasterService: Fetching villages from ${ApiConstants.villages}');
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

  // Get business subcategories
  Future<List<Map<String, dynamic>>> getBusinessSubcategories(int categoryId) async {
    try {
      final response = await _api.get('${ApiConstants.businessSubcategories}/$categoryId');
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

  // Get job subcategories
  Future<List<Map<String, dynamic>>> getJobSubcategories(int categoryId) async {
    try {
      final response = await _api.get('${ApiConstants.jobSubcategories}/$categoryId');
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
      debugPrint('MasterService: Fetching countries from ${ApiConstants.countries}');
      final response = await _api.get(ApiConstants.countries);
      debugPrint('MasterService: Countries response length: ${response.data['data']?.length}');
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
      debugPrint('MasterService: States response length: ${response.data['data']?.length}');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      debugPrint('MasterService: Error fetching states: $e');
      return [];
    }
  }

  // Get cities by country and state code
  Future<List<Map<String, dynamic>>> getCities(String countryCode, String stateCode) async {
    try {
      final response = await _api.get('${ApiConstants.cities}/$countryCode/$stateCode');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }
}
