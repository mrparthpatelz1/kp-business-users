import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/master_service.dart';
import '../../data/providers/api_provider.dart';
import '../../core/constants/api_constants.dart';

class EditProfileController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();
  final AuthService _authService = Get.find<AuthService>();
  final MasterService _masterService = Get.find<MasterService>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString userType = ''.obs;

  // Personal Info Controllers
  final fullNameController = TextEditingController();
  final surnameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);
  final RxString gender = ''.obs;
  final RxString bloodGroup = ''.obs;

  // Gender and Blood Group options (matching registration)
  final List<String> genderOptions = ['male', 'female', 'other'];
  final List<String> bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  // Address Controllers
  final Rx<int?> selectedVillageId = Rx<int?>(null);
  final nativeVillageNameController = TextEditingController(); // For display
  final addressController = TextEditingController();
  final zipcodeController = TextEditingController();
  final RxString selectedCountryCode = 'IN'.obs;
  final RxString selectedStateCode = ''.obs;
  final RxString selectedCityName = ''.obs;

  // Master data (from MasterService)
  final RxList<Map<String, dynamic>> villages = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> countries = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> states = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> cities = <Map<String, dynamic>>[].obs;

  // Education List
  final RxList<Map<String, dynamic>> educationList =
      <Map<String, dynamic>>[].obs;

  // Job Details
  final jobCompanyController = TextEditingController();
  final jobDesignationController = TextEditingController();
  final jobDepartmentController = TextEditingController();
  final jobExperienceController = TextEditingController();
  final Rx<DateTime?> jobJoinDate = Rx<DateTime?>(null);

  // Job Categories
  final RxList<Map<String, dynamic>> jobTypes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobSubcategories =
      <Map<String, dynamic>>[].obs;
  final RxInt selectedJobTypeId = 0.obs;
  final RxInt selectedJobCategoryId = 0.obs;
  final RxList<int> selectedJobSubcategoryIds = <int>[].obs;

  // Business Details
  final businessNameController = TextEditingController();
  final businessDescriptionController = TextEditingController();
  final businessAddressController = TextEditingController();
  final businessEmailController = TextEditingController();
  final businessPhoneController = TextEditingController();
  final businessWebsiteController = TextEditingController();
  final businessGstController = TextEditingController();
  final businessEmployeesController = TextEditingController();
  final businessTurnoverController = TextEditingController();
  final businessEstablishmentYearController = TextEditingController();

  // Business Categories
  final RxList<Map<String, dynamic>> businessTypes =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> businessCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> businessSubcategories =
      <Map<String, dynamic>>[].obs;
  final RxInt selectedBusinessTypeId = 0.obs;
  final RxInt selectedBusinessCategoryId = 0.obs;
  final RxList<int> selectedBusinessSubcategoryIds = <int>[].obs;

  Map<String, dynamic>? originalProfile;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadMasterData(); // Wait for countries, villages to load
    loadProfile(); // Now load profile with master data available
  }

  @override
  void onClose() {
    fullNameController.dispose();
    surnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    nativeVillageNameController.dispose();
    addressController.dispose();
    zipcodeController.dispose();
    jobCompanyController.dispose();
    jobDesignationController.dispose();
    jobDepartmentController.dispose();
    jobExperienceController.dispose();
    businessNameController.dispose();
    businessDescriptionController.dispose();
    businessAddressController.dispose();
    businessEmailController.dispose();
    businessPhoneController.dispose();
    businessWebsiteController.dispose();
    businessGstController.dispose();
    businessEmployeesController.dispose();
    businessTurnoverController.dispose();
    businessEstablishmentYearController.dispose();
    super.onClose();
  }

  Future<void> loadMasterData() async {
    villages.value = await _masterService.getVillages();
    countries.value = await _masterService.getCountries();

    // Load job and business types/categories for dropdowns
    jobTypes.value = await _masterService.getJobTypes();
    jobCategories.value = await _masterService.getJobCategories();
    businessTypes.value = await _masterService.getBusinessTypes();
    businessCategories.value = await _masterService.getBusinessCategories();
  }

  Future<void> loadStates(String countryCode) async {
    selectedCountryCode.value = countryCode;
    selectedStateCode.value = '';
    selectedCityName.value = '';
    states.value = await _masterService.getStates(countryCode);
    cities.clear();
  }

  Future<void> loadCities(String stateCode) async {
    selectedStateCode.value = stateCode;
    selectedCityName.value = '';
    cities.value = await _masterService.getCities(
      selectedCountryCode.value,
      stateCode,
    );
  }

  Future<void> loadJobSubcategories(int categoryId) async {
    selectedJobCategoryId.value = categoryId;
    selectedJobSubcategoryIds.clear();
    jobSubcategories.value = await _masterService.getJobSubcategories(
      categoryId,
    );
  }

  Future<void> loadBusinessSubcategories(int categoryId) async {
    selectedBusinessCategoryId.value = categoryId;
    selectedBusinessSubcategoryIds.clear();
    businessSubcategories.value = await _masterService.getBusinessSubcategories(
      categoryId,
    );
  }

  void loadProfile() {
    final user = _authService.currentUser.value;
    if (user != null) {
      originalProfile = Map.from(user);
      userType.value = user['user_type']?.toString().toLowerCase() ?? '';

      // Personal Info
      fullNameController.text = user['full_name'] ?? '';
      surnameController.text = user['surname'] ?? '';
      phoneController.text = user['phone'] ?? '';
      emailController.text = user['email'] ?? '';
      gender.value = user['gender']?.toString().toLowerCase() ?? '';
      bloodGroup.value = user['blood_group'] ?? '';

      // Date of Birth
      if (user['date_of_birth'] != null) {
        try {
          dateOfBirth.value = DateTime.parse(user['date_of_birth']);
        } catch (e) {
          dateOfBirth.value = null;
        }
      }

      // Native Village
      if (user['native_village'] is Map) {
        selectedVillageId.value = user['native_village']['id'];
        nativeVillageNameController.text = user['native_village']['name'] ?? '';
      } else {
        nativeVillageNameController.text =
            user['native_village']?.toString() ?? '';
      }

      // Address - handle both nested and flat structures
      final address = user['address'];
      final addressLine = address is Map
          ? address['line']
          : (user['living_address'] ?? user['current_address']);
      final livingCity = address is Map ? address['city'] : user['living_city'];
      final livingState = address is Map
          ? address['state']
          : user['living_state'];
      final livingCountry = address is Map
          ? address['country']
          : user['living_country'];
      final livingZipcode = address is Map
          ? address['zipcode']
          : user['living_zipcode'];

      addressController.text = addressLine ?? '';
      zipcodeController.text = livingZipcode ?? '';

      // Load country/state/city if available (use extracted variables)
      if (livingCountry != null && countries.isNotEmpty) {
        final countryItem = countries.firstWhereOrNull(
          (c) => c['name'] == livingCountry,
        );
        if (countryItem != null) {
          // Set country code immediately so dropdown shows it
          selectedCountryCode.value = countryItem['code'];

          // Load states for this country
          loadStates(countryItem['code']).then((_) {
            if (livingState != null && states.isNotEmpty) {
              final stateItem = states.firstWhereOrNull(
                (s) => s['name'] == livingState,
              );
              if (stateItem != null) {
                // Set state code so dropdown shows it
                selectedStateCode.value = stateItem['code'];

                // Load cities for this state
                loadCities(stateItem['code']).then((_) {
                  if (livingCity != null) {
                    selectedCityName.value = livingCity;
                  }
                });
              }
            }
          });
        }
      }

      // Education
      if (user['education'] != null && user['education'] is List) {
        educationList.assignAll(
          List<Map<String, dynamic>>.from(user['education']),
        );
      }

      // Job Details
      if (userType.value == 'job' && user['job'] != null) {
        final job = user['job'];
        jobCompanyController.text = job['company_name'] ?? '';
        jobDesignationController.text =
            job['designation'] ?? job['job_title'] ?? '';
        jobDepartmentController.text = job['department'] ?? '';
        jobExperienceController.text =
            job['years_of_experience']?.toString() ?? '';

        // Parse joining date
        if (job['date_of_joining'] != null) {
          try {
            jobJoinDate.value = DateTime.parse(job['date_of_joining']);
          } catch (e) {
            jobJoinDate.value = null;
          }
        }

        // Load job categories (handle nested structure from backend)
        if (job['type'] is Map && job['type']['id'] != null) {
          selectedJobTypeId.value = job['type']['id'];
        }

        if (job['category'] is Map && job['category']['id'] != null) {
          selectedJobCategoryId.value = job['category']['id'];
          loadJobSubcategories(job['category']['id']).then((_) {
            // Load subcategories from array
            if (job['subcategories'] is List) {
              selectedJobSubcategoryIds.value = (job['subcategories'] as List)
                  .map((sub) => sub['id'] as int)
                  .toList();
            }
          });
        }
      }

      // Business Details
      if (userType.value == 'business' &&
          (user['business'] != null || user['businesses'] != null)) {
        final businesses = user['businesses'] ?? [user['business']];
        if (businesses is List && businesses.isNotEmpty) {
          final business = businesses[0];
          businessNameController.text = business['business_name'] ?? '';
          businessDescriptionController.text =
              business['description'] ?? business['business_description'] ?? '';
          businessAddressController.text =
              business['address'] ?? business['business_address'] ?? '';
          businessEmailController.text = business['business_email'] ?? '';
          businessPhoneController.text = business['business_phone'] ?? '';
          businessWebsiteController.text = business['website_url'] ?? '';
          businessGstController.text = business['gst_number'] ?? '';
          businessEmployeesController.text =
              business['number_of_employees']?.toString() ?? '';
          businessTurnoverController.text =
              business['annual_turnover']?.toString() ?? '';
          businessEstablishmentYearController.text =
              business['year_of_establishment']?.toString() ?? '';

          // Load business categories (handle nested structure from backend)
          if (business['type'] is Map && business['type']['id'] != null) {
            selectedBusinessTypeId.value = business['type']['id'];
          }

          if (business['category'] is Map &&
              business['category']['id'] != null) {
            selectedBusinessCategoryId.value = business['category']['id'];
            loadBusinessSubcategories(business['category']['id']).then((_) {
              // Load subcategories from array
              if (business['subcategories'] is List) {
                selectedBusinessSubcategoryIds.value =
                    (business['subcategories'] as List)
                        .map((sub) => sub['id'] as int)
                        .toList();
              }
            });
          }
        }
      }
    }
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth.value ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dateOfBirth.value = picked;
    }
  }

  Future<void> selectJobJoinDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: jobJoinDate.value ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      jobJoinDate.value = picked;
    }
  }

  void addEducation() {
    educationList.add({
      'qualification': '',
      'institution': '',
      'passing_year': '',
      'grade': '',
    });
  }

  void removeEducation(int index) {
    educationList.removeAt(index);
  }

  void updateEducation(int index, String key, dynamic value) {
    final item = Map<String, dynamic>.from(educationList[index]);
    item[key] = value;
    educationList[index] = item;
  }

  Future<bool> saveProfile() async {
    isSaving.value = true;
    try {
      final data = {
        // Basic Info
        'full_name': fullNameController.text.trim(),
        'surname': surnameController.text.trim(),
        'date_of_birth': dateOfBirth.value != null
            ? DateFormat('yyyy-MM-dd').format(dateOfBirth.value!)
            : null,
        'gender': gender.value,
        'blood_group': bloodGroup.value.isEmpty ? null : bloodGroup.value,

        // Address
        'living_address': addressController.text.trim(),
        'living_city': selectedCityName.value,
        'living_state': states.firstWhereOrNull(
          (s) => s['code'] == selectedStateCode.value,
        )?['name'],
        'living_country': countries.firstWhereOrNull(
          (c) => c['code'] == selectedCountryCode.value,
        )?['name'],
        'living_zipcode': zipcodeController.text.trim(),
        'user_type': userType.value,

        // Education
        'education': educationList.toList(),
      };

      // Job Data
      if (userType.value == 'job') {
        data['job'] = {
          'company_name': jobCompanyController.text.trim(),
          'designation': jobDesignationController.text.trim(),
          'department': jobDepartmentController.text.trim(),
          'years_of_experience': jobExperienceController.text.trim(),
          'date_of_joining': jobJoinDate.value != null
              ? DateFormat('yyyy-MM-dd').format(jobJoinDate.value!)
              : null,
          'job_type_id': selectedJobTypeId.value > 0
              ? selectedJobTypeId.value
              : null,
          'job_category_id': selectedJobCategoryId.value > 0
              ? selectedJobCategoryId.value
              : null,
          'job_subcategory_ids': selectedJobSubcategoryIds.isNotEmpty
              ? selectedJobSubcategoryIds.toList()
              : null,
        };
      }

      // Business Data
      if (userType.value == 'business') {
        data['business'] = {
          'business_name': businessNameController.text.trim(),
          'description': businessDescriptionController.text.trim(),
          'address': businessAddressController.text.trim(),
          'business_email': businessEmailController.text.trim(),
          'business_phone': businessPhoneController.text.trim(),
          'website_url': businessWebsiteController.text.trim(),
          'gst_number': businessGstController.text.trim(),
          'number_of_employees': businessEmployeesController.text.trim(),
          'annual_turnover': businessTurnoverController.text.trim(),
          'year_of_establishment': businessEstablishmentYearController.text
              .trim(),
          'business_type_id': selectedBusinessTypeId.value > 0
              ? selectedBusinessTypeId.value
              : null,
          'business_category_id': selectedBusinessCategoryId.value > 0
              ? selectedBusinessCategoryId.value
              : null,
          'business_subcategory_ids': selectedBusinessSubcategoryIds.isNotEmpty
              ? selectedBusinessSubcategoryIds.toList()
              : null,
        };
      }

      final response = await _api.put(ApiConstants.profile, data: data);

      if (response.statusCode == 200) {
        // Update local user data
        await _authService.getProfile();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
