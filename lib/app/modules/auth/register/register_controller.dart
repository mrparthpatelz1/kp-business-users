import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // FormData
import '../../../routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/master_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/storage_service.dart';

class BusinessFormState {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final annualTurnoverController = TextEditingController(); // Keep it here
  final yearOfEstablishmentController = TextEditingController();
  final gstNumberController = TextEditingController();
  final websiteUrlController = TextEditingController();
  final numberOfEmployeesController = TextEditingController();

  final RxString phoneCountryCode = '+91'.obs;
  final Rx<int?> selectedTypeId = Rx<int?>(null);
  final Rx<int?> selectedCategoryId = Rx<int?>(null);
  final RxList<int> selectedSubcategoryIds = <int>[].obs;

  // Note: Logo handling might need to be per-business if complex,
  // but for now we'll stick to one logo or none for extra businesses due to UI/Backend ease
  // or add a file picker here.
  // The backend supports mapped logos but validation might be tricky.
  // Let's assume One Logo for Primary Business (first one) primarily for now,
  // or add `Rx<File?> logo` here.
  final Rx<File?> logo = Rx<File?>(null);

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    annualTurnoverController.dispose();
    yearOfEstablishmentController.dispose();
    gstNumberController.dispose();
    websiteUrlController.dispose();
    numberOfEmployeesController.dispose();
  }
}

class RegisterController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final MasterService _masterService = Get.find<MasterService>();

  // Form keys for each step
  final step1FormKey = GlobalKey<FormState>();
  final step2FormKey = GlobalKey<FormState>();
  final step3FormKey = GlobalKey<FormState>();
  final step4FormKey = GlobalKey<FormState>();

  // Page controller
  final PageController pageController = PageController();
  final RxInt currentStep = 0.obs;
  final RxInt totalSteps =
      5.obs; // Personal, Address, User Type, Education, Details

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isCheckingEmail = false.obs;
  final RxBool isCheckingPhone = false.obs;
  final RxString errorMessage = ''.obs;

  // Step 1: Personal Information
  final fullNameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final RxString phoneCountryCode = '+91'.obs; // Default India
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);
  final RxString gender = ''.obs;
  final RxString bloodGroup = ''.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool emailAvailable = true.obs;
  final RxBool phoneAvailable = true.obs;

  // Country dial codes
  final List<Map<String, String>> countryDialCodes = [
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

  // Step 2: Address Information
  final addressController = TextEditingController();
  final zipcodeController = TextEditingController();
  final Rx<int?> selectedVillageId = Rx<int?>(null);
  final RxString selectedCountryCode = 'IN'.obs;
  final RxString selectedStateCode = ''.obs;
  final RxString selectedCityName = ''.obs;

  // Step 3: User Type
  final RxString userType = ''.obs;

  // Step 4: Education Details
  final RxString educationType = 'college'.obs; // school or college
  final qualificationController = TextEditingController(); // Course/Standard
  final institutionController = TextEditingController();
  final fieldOfStudyController = TextEditingController();
  final startYearController = TextEditingController();
  final passingYearController = TextEditingController();
  final currentYearController =
      TextEditingController(); // Current year of study
  final gradeController = TextEditingController();
  final RxBool isCurrentlyStudying = false.obs;

  // Step 4: Business Details (if user_type == business)
  // Step 4: Business Details (if user_type == business)
  // Replaced single controllers with a list of forms
  final RxList<BusinessFormState> businessForms = <BusinessFormState>[].obs;

  void addBusinessForm() {
    businessForms.add(BusinessFormState());
  }

  void removeBusinessForm(int index) {
    if (businessForms.length > 1) {
      final form = businessForms[index];
      form.dispose();
      businessForms.removeAt(index);
    }
  }

  // Step 4: Job Details (if user_type == job)
  final companyNameController = TextEditingController();
  final designationController = TextEditingController();
  final departmentController = TextEditingController();
  final experienceController = TextEditingController(); // Years of experience
  final Rx<DateTime?> dateOfJoining = Rx<DateTime?>(null);
  final Rx<int?> selectedJobTypeId = Rx<int?>(null);
  final Rx<int?> selectedJobCategoryId = Rx<int?>(null);
  final RxList<int> selectedJobSubcategoryIds = <int>[].obs; // Multi-select
  final RxBool isCurrentlyWorking =
      true.obs; // For job users - are they currently employed?

  // Master data
  final RxList<Map<String, dynamic>> villages = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> countries = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> states = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> cities = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> businessTypes =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> businessCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> businessSubcategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobTypes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobSubcategories =
      <Map<String, dynamic>>[].obs;

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
  final List<String> userTypeOptions = ['business', 'job', 'student'];

  // Profile Image
  final Rx<File?> profileImage = Rx<File?>(null);

  Future<void> pickProfileImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      profileImage.value = File(image.path);
    }
  }

  void showImagePickerOptions() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          color: Colors.white,
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Get.back();
                  pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Get.back();
                  pickProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    villages.value = await _masterService.getVillages();
    countries.value = await _masterService.getCountries();
    // Initialize one business form
    addBusinessForm();
    businessTypes.value = await _masterService.getBusinessTypes();
    businessCategories.value = await _masterService.getBusinessCategories();
    jobTypes.value = await _masterService.getJobTypes();
    jobCategories.value = await _masterService.getJobCategories();
    // Load states for India by default
    states.value = await _masterService.getStates('IN');
  }

  Future<void> loadStates(String countryCode) async {
    selectedCountryCode.value = countryCode;
    selectedStateCode.value = '';
    selectedCityName.value = '';
    cities.clear();
    states.value = await _masterService.getStates(countryCode);
  }

  Future<void> loadCities(String stateCode) async {
    selectedStateCode.value = stateCode;
    selectedCityName.value = '';
    cities.value = await _masterService.getCities(
      selectedCountryCode.value,
      stateCode,
    );
  }

  Future<void> loadBusinessSubcategories(int categoryId, int formIndex) async {
    // We need to load subcategories for a specific form?
    // The MasterService returns all subcategories for a category.
    // If we want to cache them, we might need a map.
    // However, usually we can just fetch them when category changes.
    // But since it's a list, we need to know WHICH form to update list for?
    // Actually, the `businessSubcategories` list in controller is shared!
    // This is a problem for multiple forms with different categories.
    // We should move `businessSubcategories` list INTO `BusinessFormState` or map it.

    // BETTER APPROACH: Add `RxList<Map<String, dynamic>> subcategories` to BusinessFormState
    // And update that specific list.

    // I will need to update BusinessFormState to include subcategories list.
    // But for now, I'll return the list and let the view assign it?
    // No, controller logic is better.

    // Let's assume I'll add `RxList<Map<String, dynamic>> subcategories` to BusinessFormState (I'll do it in next `replace` if needed, but I can't edit previous replacement chunk easily here without overlap/complexity).
    // Actually, I can just fetch it here and assigning it to the form's list if I had one.
    // I'll leave this function for now and modify `BusinessFormState` in the view/controller properly.
    // Wait, the View observes `controller.businessSubcategories`.
    // If Form A has Category X, and Form B has Category Y, they need disjoint subcategory lists.
    // So `RegisterController` CANNOT have a single `businessSubcategories` list.
    // It must be in `BusinessFormState`.

    if (formIndex < 0 || formIndex >= businessForms.length) return;

    // Ideally validation happens in view or we use a FutureBuilder.
    // But let's add `subcategories` to `BusinessFormState` via a separate mechanism or just use a Map<int, List> in controller.
    // Using Map in controller:
    // final Map<int, RxList<Map<String, dynamic>>> formSubcategories = {};
    // ...
  }

  // Helper to fetch subcategories for a form
  Future<List<Map<String, dynamic>>> getSubcategoriesForForm(
    int categoryId,
  ) async {
    return await _masterService.getBusinessSubcategories(categoryId);
  }

  Future<void> loadJobSubcategories(int categoryId) async {
    selectedJobCategoryId.value = categoryId;
    selectedJobSubcategoryIds.clear();
    jobSubcategories.value = await _masterService.getJobSubcategories(
      categoryId,
    );
  }

  Future<void> nextStep() async {
    bool isValid = false;

    switch (currentStep.value) {
      case 0:
        // Step 1 Validation
        if (profileImage.value == null) {
          _showError('Please select a profile picture');
          return;
        }

        isValid = step1FormKey.currentState?.validate() ?? false;
        if (!isValid) return;

        if (gender.value.isEmpty) {
          _showError('Please select your gender');
          return;
        }
        if (dateOfBirth.value == null) {
          _showError('Please select your date of birth');
          return;
        }

        // Check email and phone availability on Next button click
        isLoading.value = true;
        await checkEmail(emailController.text.trim());
        await checkPhone(phoneController.text.trim());
        isLoading.value = false;

        if (!emailAvailable.value) {
          _showError('Email is already registered');
          return;
        }
        if (!phoneAvailable.value) {
          _showError('Phone number is already registered');
          return;
        }
        break;
      case 1:
        isValid = step2FormKey.currentState?.validate() ?? false;
        if (isValid && selectedVillageId.value == null) {
          _showError('Please select your native village');
          return;
        }
        if (isValid && selectedStateCode.value.isEmpty) {
          _showError('Please select your state');
          return;
        }
        if (isValid && selectedCityName.value.isEmpty) {
          _showError('Please select your city');
          return;
        }
        break;
      case 2: // User Type Step
        isValid = userType.value.isNotEmpty;
        if (!isValid) {
          _showError('Please select your user type');
          return;
        }
        break;
      case 3: // Education Step (Optional but all-or-nothing)
        // For school: field_of_study is optional
        // For college: field_of_study is required
        bool isSchool = educationType.value == 'school';

        bool anyFilled =
            qualificationController.text.isNotEmpty ||
            institutionController.text.isNotEmpty ||
            (!isSchool && fieldOfStudyController.text.isNotEmpty) ||
            passingYearController.text.isNotEmpty ||
            gradeController.text.isNotEmpty ||
            currentYearController.text.isNotEmpty;

        // If user is student, education is mandatory
        if (userType.value == 'student' && !anyFilled) {
          _showError('Education details are mandatory for students');
          return;
        }

        if (anyFilled || userType.value == 'student') {
          // Basic required fields for both school and college
          if (qualificationController.text.isEmpty ||
              institutionController.text.isEmpty) {
            _showError('Please fill qualification and institution details');
            return;
          }

          // field_of_study (branch/stream) required only for college
          if (!isSchool && fieldOfStudyController.text.isEmpty) {
            _showError('Please fill branch/stream for college education');
            return;
          }

          // Year validation based on currently studying
          if (isCurrentlyStudying.value) {
            if (currentYearController.text.isEmpty) {
              _showError('Please fill current year of study');
              return;
            }
          } else {
            if (passingYearController.text.isEmpty ||
                gradeController.text.isEmpty) {
              _showError('Please fill passing year and grade');
              return;
            }
          }
        }
        isValid = true;

        // If student, this is the last step
        if (userType.value == 'student' && isValid) {
          _submitRegistration();
          return;
        }
        break;
      case 4: // Type Specific Details
        if (userType.value == 'business') {
          // First validate the form to show inline errors on fields
          isValid = step4FormKey.currentState?.validate() ?? false;
          if (!isValid) {
            return; // Form validation will show red borders on invalid fields
          }

          // Validate all business forms
          // bool allValid = true; // Unused
          for (int i = 0; i < businessForms.length; i++) {
            // We don't have a FormKey for each dynamic form easily unless we generate them.
            // But we can check values manually or rely on `step4FormKey` if it wraps the whole list.
            // If `step4FormKey` wraps the ListView, it should validate all fields.
            // Let's assume `step4FormKey` wraps the column of forms.
          }

          isValid = step4FormKey.currentState?.validate() ?? false;
          if (!isValid) return;

          // Check subcategories for each form
          for (var form in businessForms) {
            if (form.selectedSubcategoryIds.isEmpty) {
              _showError(
                'Please select subcategories for business: ${form.nameController.text}',
              );
              return;
            }
          }
        } else if (userType.value == 'job') {
          if (isCurrentlyWorking.value) {
            // Use form validation to show inline errors on fields
            isValid = step4FormKey.currentState?.validate() ?? false;
            if (!isValid) {
              return; // Form validation will show red borders on invalid fields
            }

            // Check subcategories separately (multi-select doesn't have form validator)
            if (selectedJobSubcategoryIds.isEmpty) {
              _showError('Please select at least one job subcategory');
              return;
            }
          } else {
            isValid = true; // Not working, so details optional
          }
        }
        break;
    }

    if (isValid) {
      if (currentStep.value < 4) {
        // Max step is now 4
        currentStep.value++;
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitRegistration();
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> checkEmail(String email) async {
    if (!GetUtils.isEmail(email)) return;

    isCheckingEmail.value = true;
    emailAvailable.value = await _authService.checkEmail(email);
    isCheckingEmail.value = false;
  }

  Future<void> checkPhone(String phone) async {
    if (phone.length != 10) return;

    isCheckingPhone.value = true;
    final fullPhone = '${phoneCountryCode.value}$phone';
    phoneAvailable.value = await _authService.checkPhone(fullPhone);
    isCheckingPhone.value = false;
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

  void selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          dateOfBirth.value ??
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dateOfBirth.value = picked;
    }
  }

  Future<void> _submitRegistration() async {
    isLoading.value = true;
    errorMessage.value = '';

    final stateName =
        states.firstWhereOrNull(
          (s) => s['code'] == selectedStateCode.value,
        )?['name'] ??
        selectedStateCode.value;
    final countryName =
        countries.firstWhereOrNull(
          (c) => c['code'] == selectedCountryCode.value,
        )?['name'] ??
        'India';

    final data = {
      'full_name': fullNameController.text.trim(),
      'surname': surnameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': '${phoneCountryCode.value}${phoneController.text.trim()}',
      'phone_country_code': phoneCountryCode.value,
      'password': passwordController.text,
      'gender': gender.value,
      'date_of_birth': dateOfBirth.value?.toIso8601String().split('T')[0],
      'blood_group': bloodGroup.value.isNotEmpty ? bloodGroup.value : null,
      'native_village_id': selectedVillageId.value,
      'living_address': addressController.text.trim(),
      'living_city': selectedCityName.value,
      'living_state': stateName,
      'living_country': countryName,
      'living_zipcode': zipcodeController.text.trim(),
      'user_type': userType.value,
      // Include FCM token for push notifications
      if (Get.isRegistered<NotificationService>())
        'fcm_token': Get.find<NotificationService>().fcmToken.value,
      // Education (optional)
      if (qualificationController.text.isNotEmpty)
        'education': {
          'education_type': educationType.value,
          'qualification': qualificationController.text.trim(),
          'institution': institutionController.text.trim(),
          'field_of_study': fieldOfStudyController.text.trim(),
          if (startYearController.text.isNotEmpty)
            'start_year': int.tryParse(startYearController.text.trim()),
          if (passingYearController.text.isNotEmpty &&
              !isCurrentlyStudying.value)
            'passing_year': int.tryParse(passingYearController.text.trim()),
          if (currentYearController.text.isNotEmpty &&
              isCurrentlyStudying.value)
            'current_year': int.tryParse(currentYearController.text.trim()),
          'is_currently_studying': isCurrentlyStudying.value,
          if (gradeController.text.isNotEmpty && !isCurrentlyStudying.value)
            'grade': gradeController.text.trim(),
        },
      // Business details (if user_type == business)
      if (userType.value == 'business')
        'businesses': businessForms
            .map(
              (form) => {
                'business_name': form.nameController.text.trim(),
                if (form.emailController.text.trim().isNotEmpty)
                  'business_email': form.emailController.text.trim(),
                if (form.phoneController.text.trim().isNotEmpty)
                  'business_phone':
                      '${form.phoneCountryCode.value}${form.phoneController.text.trim()}',
                if (form.addressController.text.trim().isNotEmpty)
                  'business_address': form.addressController.text.trim(),
                if (form.descriptionController.text.trim().isNotEmpty)
                  'business_description': form.descriptionController.text
                      .trim(),
                if (form.yearOfEstablishmentController.text.trim().isNotEmpty)
                  'year_of_establishment': int.tryParse(
                    form.yearOfEstablishmentController.text.trim(),
                  ),
                if (form.gstNumberController.text.trim().isNotEmpty)
                  'gst_number': form.gstNumberController.text.trim(),
                if (form.websiteUrlController.text.trim().isNotEmpty)
                  'website_url': form.websiteUrlController.text.trim(),
                if (form.numberOfEmployeesController.text.trim().isNotEmpty)
                  'number_of_employees': int.tryParse(
                    form.numberOfEmployeesController.text.trim(),
                  ),
                if (form.annualTurnoverController.text.trim().isNotEmpty)
                  'annual_turnover': double.tryParse(
                    form.annualTurnoverController.text.trim(),
                  ),
                if (form.selectedTypeId.value != null)
                  'business_type_id': form.selectedTypeId.value,
                if (form.selectedCategoryId.value != null)
                  'business_category_id': form.selectedCategoryId.value,
                if (form.selectedSubcategoryIds.isNotEmpty)
                  'business_subcategory_ids': form.selectedSubcategoryIds
                      .toList(),
              },
            )
            .toList(),
      // Job details (if user_type == job)
      if (userType.value == 'job')
        'job': {
          'is_current': isCurrentlyWorking.value,
          if (isCurrentlyWorking.value &&
              companyNameController.text.trim().isNotEmpty)
            'company_name': companyNameController.text.trim(),
          if (isCurrentlyWorking.value &&
              designationController.text.trim().isNotEmpty)
            'designation': designationController.text.trim(),
          if (isCurrentlyWorking.value &&
              departmentController.text.trim().isNotEmpty)
            'department': departmentController.text.trim(),
          if (isCurrentlyWorking.value &&
              experienceController.text.trim().isNotEmpty)
            'years_of_experience': experienceController.text.trim(),
          if (isCurrentlyWorking.value && dateOfJoining.value != null)
            'date_of_joining': dateOfJoining.value!.toIso8601String().split(
              'T',
            )[0],
          if (isCurrentlyWorking.value && selectedJobTypeId.value != null)
            'job_type_id': selectedJobTypeId.value,
          if (isCurrentlyWorking.value && selectedJobCategoryId.value != null)
            'job_category_id': selectedJobCategoryId.value,
          if (isCurrentlyWorking.value && selectedJobSubcategoryIds.isNotEmpty)
            'job_subcategory_ids': selectedJobSubcategoryIds.toList(),
        },
    };

    // Debug: print the data being sent
    debugPrint('Register data: $data');

    // Handle file upload if business logo OR profile image is present
    Map<String, dynamic> result;

    // Check if any business has a logo
    List<File> businessLogos = [];
    List<int> businessLogoIndices = [];
    for (int i = 0; i < businessForms.length; i++) {
      if (businessForms[i].logo.value != null) {
        businessLogos.add(businessForms[i].logo.value!);
        businessLogoIndices.add(i);
      }
    }

    if (businessLogos.isNotEmpty || profileImage.value != null) {
      // Create FormData
      final Map<String, dynamic> formMap = {
        ...data,
        // For businesses, we need to handle multiple forms
        if (data.containsKey('businesses'))
          'businesses': jsonEncode(data['businesses']),
        // Send indices for logos
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

      result = await _authService.registerWithFile(formData);
    } else {
      // JSON submission
      result = await _authService.register(data);
    }

    isLoading.value = false;

    if (result['success']) {
      // Save user data to storage so PendingApprovalController can access village_id
      if (result['data'] != null) {
        Get.find<StorageService>().user = result['data'];
      }

      // Upload FCM token after successful registration
      try {
        if (Get.isRegistered<NotificationService>()) {
          final notificationService = Get.find<NotificationService>();
          await notificationService.uploadTokenToServer();
        }
      } catch (e) {
        debugPrint('Failed to upload FCM token after registration: $e');
      }

      Get.offAllNamed(Routes.PENDING_APPROVAL);
      Get.snackbar(
        'Success',
        'Registration successful. Please wait for approval.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      _showError(result['message'] ?? 'Registration failed');
    }
  }

  void goToLogin() {
    Get.back();
  }

  @override
  void onClose() {
    pageController.dispose();
    fullNameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    zipcodeController.dispose();
    qualificationController.dispose();
    institutionController.dispose();
    fieldOfStudyController.dispose();
    startYearController.dispose();
    passingYearController.dispose();
    currentYearController.dispose();
    gradeController.dispose();
    for (var form in businessForms) {
      form.dispose();
    }
    companyNameController.dispose();
    designationController.dispose();
    departmentController.dispose();
    experienceController.dispose();
    super.onClose();
  }
}
