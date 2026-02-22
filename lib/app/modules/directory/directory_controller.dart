import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';
import '../../data/services/master_service.dart';

class DirectoryController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();
  final MasterService _masterService = Get.find<MasterService>();

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedVillage = ''.obs;
  final RxString selectedUserType = ''.obs;
  final RxString selectedBusinessCategory = ''.obs;
  final RxString selectedBusinessSubcategory = ''.obs;
  final RxString selectedJobCategory = ''.obs;
  final RxString selectedJobSubcategory = ''.obs;

  // Master data for filters
  final RxList<Map<String, dynamic>> businessCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> businessSubcategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobSubcategories =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMasterData();
    loadUsers();
  }

  Future<void> loadMasterData() async {
    try {
      businessCategories.value = await _masterService.getBusinessCategories();
      jobCategories.value = await _masterService.getJobCategories();
      // Load all subcategories upfront (unlinked from category)
      businessSubcategories.value = await _masterService
          .getBusinessSubcategories();
      jobSubcategories.value = await _masterService.getJobSubcategories();
    } catch (e) {
      debugPrint('Error loading master data: $e');
    }
  }

  Future<void> loadBusinessSubcategories([int? categoryId]) async {
    // No-op: subcategories are now preloaded at startup
  }

  Future<void> loadJobSubcategories([int? categoryId]) async {
    // No-op: subcategories are now preloaded at startup
  }

  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      users.clear();
    }

    isLoading.value = true;

    try {
      final queryParams = <String, dynamic>{
        'page': currentPage.value,
        'per_page': 20,
      };

      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }
      if (selectedVillage.value.isNotEmpty) {
        queryParams['village_id'] = selectedVillage.value;
      }
      if (selectedUserType.value.isNotEmpty) {
        queryParams['user_type'] = selectedUserType.value;
      }
      if (selectedBusinessCategory.value.isNotEmpty) {
        queryParams['business_category_id'] = selectedBusinessCategory.value;
      }
      if (selectedBusinessSubcategory.value.isNotEmpty) {
        queryParams['business_subcategory_id'] =
            selectedBusinessSubcategory.value;
      }
      if (selectedJobCategory.value.isNotEmpty) {
        queryParams['job_category_id'] = selectedJobCategory.value;
      }
      if (selectedJobSubcategory.value.isNotEmpty) {
        queryParams['job_subcategory_id'] = selectedJobSubcategory.value;
      }

      final response = await _api.get(
        ApiConstants.directory,
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> userList = data['data'] ?? [];

        if (refresh) {
          users.value = userList.cast<Map<String, dynamic>>();
        } else {
          users.addAll(userList.cast<Map<String, dynamic>>());
        }

        totalPages.value = data['pagination']['total_pages'] ?? 1;
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }

    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || currentPage.value >= totalPages.value) return;

    isLoadingMore.value = true;
    currentPage.value++;
    await loadUsers();
    isLoadingMore.value = false;
  }

  void search(String query) {
    searchQuery.value = query;
    loadUsers(refresh: true);
  }

  void filterByVillage(String villageId) {
    selectedVillage.value = villageId;
    loadUsers(refresh: true);
  }

  void filterByUserType(String userType) {
    selectedUserType.value = userType;
    loadUsers(refresh: true);
  }

  void filterByBusinessCategory(String categoryId) {
    selectedBusinessCategory.value = categoryId;
    selectedBusinessSubcategory.value = ''; // Clear selected subcategory
    loadUsers(refresh: true);
  }

  void filterByBusinessSubcategory(String subcategoryId) {
    selectedBusinessSubcategory.value = subcategoryId;
    loadUsers(refresh: true);
  }

  void filterByJobCategory(String categoryId) {
    selectedJobCategory.value = categoryId;
    selectedJobSubcategory.value = ''; // Clear selected subcategory
    loadUsers(refresh: true);
  }

  void filterByJobSubcategory(String subcategoryId) {
    selectedJobSubcategory.value = subcategoryId;
    loadUsers(refresh: true);
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedVillage.value = '';
    selectedUserType.value = '';
    selectedBusinessCategory.value = '';
    selectedBusinessSubcategory.value = '';
    selectedJobCategory.value = '';
    selectedJobSubcategory.value = '';
    loadUsers(refresh: true);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _api.get('${ApiConstants.directory}/$userId');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
    return null;
  }
}
