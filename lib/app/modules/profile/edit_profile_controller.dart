import 'package:flutter/material.dart';
import 'package:get/get.dart'
    hide FormData, MultipartFile; // Hide from Get to use Dio's
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert'; // For jsonEncode
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // For FormData, MultipartFile
import '../../data/services/auth_service.dart';
import '../../data/services/master_service.dart';
import '../../data/providers/api_provider.dart';
import '../../core/constants/api_constants.dart';

class BusinessFormState {
  int? id;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final phoneCountryCode = '+91'.obs;
  final websiteUrlController = TextEditingController();
  final gstNumberController = TextEditingController();
  final numberOfEmployeesController = TextEditingController();
  final annualTurnoverController = TextEditingController();
  final yearOfEstablishmentController = TextEditingController();

  final selectedTypeId = Rx<int?>(null);
  final selectedCategoryId = Rx<int?>(null);
  final selectedSubcategoryIds = <int>[].obs;

  final Rx<File?> logo = Rx<File?>(null);
  final Rx<String?> currentLogoUrl = Rx<String?>(
    null,
  ); // For existing logo display

  // Logo placeholder - currently edit not supported?
  // We can add logic later.

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    emailController.dispose();
    phoneController.dispose();
    websiteUrlController.dispose();
    gstNumberController.dispose();
    numberOfEmployeesController.dispose();
    annualTurnoverController.dispose();
    yearOfEstablishmentController.dispose();
  }
}

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

  // Business Details List
  final RxList<BusinessFormState> businessForms = <BusinessFormState>[].obs;

  // Business Categories for Dropdowns (shared but selection is per form)
  final RxList<Map<String, dynamic>> businessTypes =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> businessCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> countryDialCodes =
      <Map<String, dynamic>>[].obs;

  // Profile Picture
  final Rx<File?> profileImage = Rx<File?>(null);

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
    for (var form in businessForms) {
      form.dispose();
    }
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
    countryDialCodes.value = await _masterService.getCountryDialCodes();
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

  Future<List<Map<String, dynamic>>> getSubcategoriesForForm(
    int categoryId,
  ) async {
    return await _masterService.getBusinessSubcategories(categoryId);
  }

  Future<void> pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      profileImage.value = File(image.path);
    }
  }

  Future<void> pickBusinessLogo(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (index < businessForms.length) {
        businessForms[index].logo.value = File(image.path);
      }
    }
  }

  void addBusinessForm([Map<String, dynamic>? business]) {
    final form = BusinessFormState();

    if (business != null) {
      form.id = business['id']; // Store ID for updates/deletions
      form.nameController.text = business['business_name'] ?? '';
      form.descriptionController.text =
          business['description'] ?? business['business_description'] ?? '';
      form.addressController.text =
          business['address'] ?? business['business_address'] ?? '';

      // Handle phone with country code
      String phone = business['business_phone'] ?? '';
      // Simple logic to extract code if needed, or just set raw for now
      // Assuming phone might contain code or not.
      // Ideally backend returns separated, but here we might need to parse.
      // For now, let's put whole string in controller or split if we know format.
      // Let's assume standard format +919876543210
      if (phone.startsWith('+') && phone.length > 3) {
        // rough extraction
        // This logic might need refinement based on exact format
        form.phoneController.text = phone.substring(3); // Remove +91
        form.phoneCountryCode.value = phone.substring(0, 3);
      } else {
        form.phoneController.text = phone;
      }

      form.emailController.text = business['business_email'] ?? '';
      form.websiteUrlController.text = business['website_url'] ?? '';
      form.gstNumberController.text = business['gst_number'] ?? '';
      form.numberOfEmployeesController.text =
          business['number_of_employees']?.toString() ?? '';
      form.annualTurnoverController.text =
          business['annual_turnover']?.toString() ?? '';
      form.yearOfEstablishmentController.text =
          business['year_of_establishment']?.toString() ?? '';

      if (business['logo'] != null) {
        form.currentLogoUrl.value = business['logo'];
      }

      if (business['type'] is Map && business['type']['id'] != null) {
        form.selectedTypeId.value = business['type']['id'];
      } else if (business['business_type_id'] != null) {
        form.selectedTypeId.value = business['business_type_id'];
      }

      if (business['category'] is Map && business['category']['id'] != null) {
        form.selectedCategoryId.value = business['category']['id'];
      } else if (business['business_category_id'] != null) {
        form.selectedCategoryId.value = business['business_category_id'];
      }

      // Subcategories
      List<int> subIds = [];
      if (business['subcategories'] is List) {
        subIds = (business['subcategories'] as List)
            .map((s) => s['id'] as int)
            .toList();
      } else if (business['business_subcategory_ids'] is List) {
        subIds = List<int>.from(business['business_subcategory_ids']);
      }
      form.selectedSubcategoryIds.addAll(subIds);
    }

    businessForms.add(form);
  }

  Future<void> removeBusinessForm(int index) async {
    final form = businessForms[index];
    if (form.id != null) {
      // It's an existing business, delete via API
      try {
        isLoading.value = true; // or generic loading
        final result = await _authService.deleteBusiness(form.id!);
        if (result['success']) {
          form.dispose();
          businessForms.removeAt(index);
          Get.snackbar('Success', 'Business deleted successfully');
        } else {
          Get.snackbar(
            'Error',
            result['message'] ?? 'Failed to delete business',
          );
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete business: $e');
      } finally {
        isLoading.value = false;
      }
    } else {
      // Local only
      form.dispose();
      businessForms.removeAt(index);
    }
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
      if (userType.value == 'business') {
        businessForms.clear();
        final businesses =
            user['businesses'] ??
            (user['business'] != null ? [user['business']] : []);
        if (businesses is List && businesses.isNotEmpty) {
          for (var b in businesses) {
            addBusinessForm(b);
          }
        } else {
          // Add one empty form if none exist
          addBusinessForm();
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
      final Map<String, dynamic> data = {
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

      // Job Details
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
        data['businesses'] = businessForms
            .map(
              (form) => {
                if (form.id != null) 'id': form.id,
                'business_name': form.nameController.text.trim(),
                'business_description': form.descriptionController.text.trim(),
                'business_address': form.addressController.text.trim(),
                'business_email': form.emailController.text.trim(),
                'business_phone':
                    '${form.phoneCountryCode.value}${form.phoneController.text.trim()}',
                'website_url': form.websiteUrlController.text.trim(),
                'gst_number': form.gstNumberController.text.trim(),
                'number_of_employees': int.tryParse(
                  form.numberOfEmployeesController.text.trim(),
                ),
                'annual_turnover': double.tryParse(
                  form.annualTurnoverController.text.trim(),
                ),
                'year_of_establishment': int.tryParse(
                  form.yearOfEstablishmentController.text.trim(),
                ),
                'business_type_id': form.selectedTypeId.value,
                'business_category_id': form.selectedCategoryId.value,
                'business_subcategory_ids': form.selectedSubcategoryIds
                    .toList(),
              },
            )
            .toList();
      }

      // Check for files to upload
      List<File> businessLogos = [];
      List<int> businessLogoIndices = [];
      for (int i = 0; i < businessForms.length; i++) {
        if (businessForms[i].logo.value != null) {
          businessLogos.add(businessForms[i].logo.value!);
          businessLogoIndices.add(i);
        }
      }

      if (profileImage.value != null || businessLogos.isNotEmpty) {
        final Map<String, dynamic> formMap = {
          ...data,
          if (data.containsKey('businesses'))
            'businesses': jsonEncode(data['businesses']),
          if (data.containsKey('education'))
            'education': jsonEncode(data['education']),
          if (data.containsKey('job')) 'job': jsonEncode(data['job']),
          if (businessLogos.isNotEmpty)
            'business_logo_indices': jsonEncode(businessLogoIndices),
        };

        final formData = FormData.fromMap(formMap);

        if (profileImage.value != null) {
          formData.files.add(
            MapEntry(
              'profile_picture',
              await MultipartFile.fromFile(
                profileImage.value!.path,
                filename: profileImage.value!.path.split('/').last,
              ),
            ),
          );
        }

        if (businessLogos.isNotEmpty) {
          for (var file in businessLogos) {
            formData.files.add(
              MapEntry(
                'business_logo',
                await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                ),
              ),
            );
          }
        }

        // AuthService updateProfile needs to handle FormData?
        // _authService.updateProfileWithFile? Or check if updateProfile can handle it.
        // Since we haven't implemented updateProfileWithFile in AuthService, detailed check:
        // _api.putFormData(ApiConstants.profile, formData) calls PUT /profile with multipart.
        // The backend supports this.
        // So we just need to ensure we call the API correctly.

        final response = await _api.putFormData(ApiConstants.profile, formData);

        if (response.statusCode == 200) {
          await _authService.getProfile();
          return true;
        }
        return false;
      } else {
        // JSON Update
        final response = await _api.put(ApiConstants.profile, data: data);
        if (response.statusCode == 200) {
          await _authService.getProfile();
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
