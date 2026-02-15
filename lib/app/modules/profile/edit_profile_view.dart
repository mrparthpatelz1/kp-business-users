import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../data/services/auth_service.dart';
import 'edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    Get.put(EditProfileController());

    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            onPressed: () async {
              // Validate main form
              if (!formKey.currentState!.validate()) {
                return;
              }

              // Validate job form if user type is 'job'
              if (controller.userType.value == 'job') {
                if (!controller.jobFormKey.currentState!.validate()) {
                  return;
                }
              }

              // Show progress dialog
              Get.dialog(
                PopScope(
                  canPop: false,
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(5.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 2.h),
                          Text(
                            'Updating Profile...',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Obx(() {
                            final progress = controller.uploadProgress.value;
                            if (progress > 0 && progress < 1.0) {
                              return Column(
                                children: [
                                  LinearProgressIndicator(value: progress),
                                  SizedBox(height: 1.h),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Text(
                              'Please wait while we save your changes.',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                barrierDismissible: false,
              );

              final success = await controller.saveProfile();

              // Close dialog
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }

              if (success) {
                Get.back();
                Get.snackbar(
                  'Success',
                  'Profile updated successfully',
                  backgroundColor: AppTheme.successColor,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: EdgeInsets.all(4.w),
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to update profile',
                  backgroundColor: AppTheme.errorColor,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: EdgeInsets.all(4.w),
                );
              }
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            controller: controller.scrollController,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo
                Center(child: _buildProfilePhoto()),
                SizedBox(height: 3.h),

                // Personal Info Section Header
                _buildSectionHeader(context, 'Personal Information'),
                SizedBox(height: 2.h),

                // Full Name & Saakh Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: TextFormField(
                        controller: controller.surnameController,
                        decoration: const InputDecoration(labelText: 'Saakh *'),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Email (Read-only)
                TextFormField(
                  controller: controller.emailController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                    suffixIcon: Icon(Icons.lock, size: 16),
                  ),
                ),
                SizedBox(height: 2.h),

                // Phone (Read-only)
                TextFormField(
                  controller: controller.phoneController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixIcon: Icon(Icons.phone),
                    suffixIcon: Icon(Icons.lock, size: 16),
                  ),
                ),
                SizedBox(height: 2.h),

                // Gender
                Text(
                  'Gender *',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 1.h),
                Obx(
                  () => Row(
                    children: controller.genderOptions.map((g) {
                      final isSelected = controller.gender.value == g;
                      return Padding(
                        padding: EdgeInsets.only(right: 2.w),
                        child: ChoiceChip(
                          label: Text(g.capitalizeFirst!),
                          selected: isSelected,
                          onSelected: (_) => controller.gender.value = g,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 2.h),

                // User Type Dropdown (Allow switching)
                Obx(
                  () => DropdownSearch<String>(
                    items: (filter, _) => controller.userTypeOptions
                        .map((e) => e.capitalizeFirst!)
                        .toList(),
                    selectedItem: controller.userType.value.capitalizeFirst,
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'I am a...',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    popupProps: const PopupProps.menu(
                      fit: FlexFit.loose,
                      constraints: BoxConstraints(maxHeight: 200),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        controller.userType.value = val.toLowerCase();
                        // If switching to business and no form exists, add one
                        if (controller.userType.value == 'business' &&
                            controller.businessForms.isEmpty) {
                          controller.addBusinessForm();
                        }
                      }
                    },
                    onBeforePopupOpening: (selectedItem) async {
                      FocusScope.of(context).unfocus();
                      return true;
                    },
                  ),
                ),
                SizedBox(height: 2.h),

                // Date of Birth
                Obx(
                  () => InkWell(
                    onTap: () => controller.selectDateOfBirth(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        controller.dateOfBirth.value != null
                            ? DateFormat(
                                'dd/MM/yyyy',
                              ).format(controller.dateOfBirth.value!)
                            : 'Select date',
                        style: TextStyle(
                          color: controller.dateOfBirth.value != null
                              ? AppTheme.textPrimary
                              : AppTheme.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                // Blood Group (Optional)
                Text(
                  'Blood Group (Optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 1.h),
                Obx(
                  () => Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: controller.bloodGroupOptions.map((bg) {
                      final isSelected = controller.bloodGroup.value == bg;
                      return ChoiceChip(
                        label: Text(bg),
                        selected: isSelected,
                        onSelected: (_) =>
                            controller.bloodGroup.value = isSelected ? '' : bg,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 3.h),

                // Address Section Header
                _buildSectionHeader(context, 'Address Information'),
                SizedBox(height: 2.h),

                // Native Village (Read-only)
                TextFormField(
                  controller: controller.nativeVillageNameController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Native Village *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    suffixIcon: Icon(Icons.lock, size: 16),
                  ),
                ),
                SizedBox(height: 3.h),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Text(
                        'Current Living Address',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: 2.h),

                // Address line
                TextFormField(
                  controller: controller.addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address Line *',
                    prefixIcon: Icon(Icons.home_outlined),
                    hintText: 'House no, Street, Area',
                  ),
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 2.h),

                // Country - Searchable
                Obx(
                  () => DropdownSearch<Map<String, dynamic>>(
                    items: (filter, _) => controller.countries.toList(),
                    selectedItem: controller.countries.firstWhereOrNull(
                      (c) => c['code'] == controller.selectedCountryCode.value,
                    ),
                    itemAsString: (item) => item['name'] ?? '',
                    compareFn: (a, b) => a['code'] == b['code'],
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Country *',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search country...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    onChanged: (item) {
                      if (item != null) controller.loadStates(item['code']);
                    },
                    onBeforePopupOpening: (selectedItem) async {
                      FocusScope.of(context).unfocus();
                      return true;
                    },
                  ),
                ),
                SizedBox(height: 2.h),

                // State - Searchable
                Obx(
                  () => DropdownSearch<Map<String, dynamic>>(
                    items: (filter, _) => controller.states.toList(),
                    selectedItem: controller.states.firstWhereOrNull(
                      (s) => s['code'] == controller.selectedStateCode.value,
                    ),
                    itemAsString: (item) => item['name'] ?? '',
                    compareFn: (a, b) => a['code'] == b['code'],
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'State *',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search state...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    onChanged: (item) {
                      if (item != null) controller.loadCities(item['code']);
                    },
                    validator: (v) => v == null ? 'Required' : null,
                    onBeforePopupOpening: (selectedItem) async {
                      FocusScope.of(context).unfocus();
                      return true;
                    },
                  ),
                ),
                SizedBox(height: 2.h),

                // City - Searchable
                Obx(
                  () => DropdownSearch<Map<String, dynamic>>(
                    items: (filter, _) => controller.cities.toList(),
                    selectedItem: controller.cities.firstWhereOrNull(
                      (c) => c['name'] == controller.selectedCityName.value,
                    ),
                    itemAsString: (item) => item['name'] ?? '',
                    compareFn: (a, b) => a['name'] == b['name'],
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'City *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search city...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    onChanged: (item) {
                      controller.selectedCityName.value = item?['name'] ?? '';
                    },
                    validator: (v) => v == null ? 'Required' : null,
                    onBeforePopupOpening: (selectedItem) async {
                      FocusScope.of(context).unfocus();
                      return true;
                    },
                  ),
                ),
                SizedBox(height: 2.h),

                // Zipcode
                TextFormField(
                  controller: controller.zipcodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Zipcode *',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (!RegExp(r'^[0-9]{6}$').hasMatch(v)) {
                      return 'Enter 6 digit zipcode';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),

                // Education Section
                _buildSectionHeader(context, 'Education'),
                SizedBox(height: 2.h),
                Obx(
                  () => Column(
                    children: [
                      ...controller.educationList.asMap().entries.map(
                        (entry) => _buildEducationItem(entry.key, entry.value),
                      ),
                      TextButton.icon(
                        onPressed: () => controller.addEducation(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Education'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),

                // Professional Info (Dynamic)
                Obx(() {
                  if (controller.userType.value == 'job') {
                    return _buildJobSection(context);
                  } else if (controller.userType.value == 'business') {
                    return _buildBusinessSection(context);
                  }
                  return const SizedBox.shrink();
                }),

                SizedBox(height: 5.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Column(
      children: [
        Obx(() {
          final localImage = controller.profileImage.value;
          final user = Get.find<AuthService>().currentUser.value;

          ImageProvider? imageProvider;
          if (localImage != null) {
            // Show the newly picked local image
            imageProvider = FileImage(localImage);
          } else if (user?['profile_picture'] != null) {
            // Fall back to existing server image
            imageProvider = NetworkImage(
              ApiConstants.getFullUrl(user!['profile_picture']),
            );
          }

          return CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: AppTheme.primaryColor,
                  )
                : null,
          );
        }),
        SizedBox(height: 1.h),
        TextButton.icon(
          onPressed: () => controller.pickProfileImage(),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Change Photo'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
      ],
    );
  }

  Widget _buildEducationItem(int index, EducationFormState item) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Education #${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => controller.removeEducation(index),
                ),
              ],
            ),

            // Education Type
            Obx(
              () => DropdownButtonFormField<String>(
                value: item.educationType.value,
                decoration: const InputDecoration(labelText: 'Education Type'),
                items: const [
                  DropdownMenuItem(value: 'school', child: Text('School')),
                  DropdownMenuItem(
                    value: 'college',
                    child: Text('College/University'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) item.educationType.value = v;
                },
              ),
            ),
            SizedBox(height: 2.h),

            // Qualification & Institution (Common but labels might differ slightly)
            Obx(() {
              final isCollege = item.educationType.value == 'college';
              return Column(
                children: [
                  TextFormField(
                    controller: item.qualificationController,
                    decoration: InputDecoration(
                      labelText: isCollege ? 'Degree/Course' : 'Standard/Class',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: item.institutionController,
                    decoration: InputDecoration(
                      labelText: isCollege
                          ? 'University/College Name'
                          : 'School Name',
                    ),
                  ),
                ],
              );
            }),
            SizedBox(height: 2.h),

            Obx(() {
              if (item.educationType.value == 'college') {
                return Column(
                  children: [
                    TextFormField(
                      controller: item.fieldOfStudyController,
                      decoration: const InputDecoration(
                        labelText: 'Field of Study',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: item.startYearController,
                            decoration: const InputDecoration(
                              labelText: 'Start Year',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Row(
                            children: [
                              Obx(
                                () => Checkbox(
                                  value: item.isCurrentlyStudying.value,
                                  onChanged: (v) =>
                                      item.isCurrentlyStudying.value =
                                          v ?? false,
                                ),
                              ),
                              const Flexible(child: Text('Currently Studying')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    if (item.isCurrentlyStudying.value)
                      TextFormField(
                        controller: item.currentYearController,
                        decoration: const InputDecoration(
                          labelText: 'Current Year (e.g. 2nd Year)',
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item.passingYearController,
                              decoration: const InputDecoration(
                                labelText: 'Passing Year',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: TextFormField(
                              controller: item.gradeController,
                              decoration: const InputDecoration(
                                labelText: 'Grade/CGPA',
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              } else {
                // School
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: item.passingYearController,
                        decoration: const InputDecoration(
                          labelText: 'Passing Year',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: TextFormField(
                        controller: item.gradeController,
                        decoration: const InputDecoration(
                          labelText: 'Grade/Percentage',
                        ),
                      ),
                    ),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildJobSection(BuildContext context) {
    return Form(
      key: controller.jobFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Job Details'),
          SizedBox(height: 2.h),
          TextFormField(
            controller: controller.jobCompanyController,
            decoration: const InputDecoration(
              labelText: 'Company Name',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          SizedBox(height: 2.h),

          // Job Type - Searchable Dropdown
          Obx(
            () => DropdownSearch<Map<String, dynamic>>(
              items: (filter, _) => controller.jobTypes.toList(),
              selectedItem: controller.jobTypes.firstWhereOrNull(
                (t) => t['id'] == controller.selectedJobTypeId.value,
              ),
              itemAsString: (item) => item['type_name'] ?? '',
              compareFn: (a, b) => a['id'] == b['id'],
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Job Type',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: const TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search type...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              onChanged: (item) {
                controller.selectedJobTypeId.value = item?['id'] ?? 0;
              },
              onBeforePopupOpening: (selectedItem) async {
                FocusScope.of(context).unfocus();
                return true;
              },
            ),
          ),
          SizedBox(height: 2.h),

          // Job Category - Searchable Dropdown
          Obx(
            () => DropdownSearch<Map<String, dynamic>>(
              items: (filter, _) => controller.jobCategories.toList(),
              selectedItem: controller.jobCategories.firstWhereOrNull(
                (c) => c['id'] == controller.selectedJobCategoryId.value,
              ),
              itemAsString: (item) => item['category_name'] ?? '',
              compareFn: (a, b) => a['id'] == b['id'],
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Job Category',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: const TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search category...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              onChanged: (item) {
                if (item != null) controller.loadJobSubcategories(item['id']);
              },
            ),
          ),
          SizedBox(height: 2.h),

          // Job Subcategories - Multi-Select Dropdown
          Obx(
            () => controller.jobSubcategories.isNotEmpty
                ? Column(
                    children: [
                      DropdownSearch<Map<String, dynamic>>.multiSelection(
                        items: (filter, _) =>
                            controller.jobSubcategories.toList(),
                        selectedItems: controller.jobSubcategories
                            .where(
                              (sub) => controller.selectedJobSubcategoryIds
                                  .contains(sub['id']),
                            )
                            .toList(),
                        itemAsString: (item) => item['subcategory_name'] ?? '',
                        compareFn: (a, b) => a['id'] == b['id'],
                        decoratorProps: const DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: 'Job Subcategories',
                            prefixIcon: Icon(Icons.category_outlined),
                            hintText: 'Select multiple subcategories',
                          ),
                        ),
                        popupProps: PopupPropsMultiSelection.menu(
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search subcategories...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        onChanged: (items) {
                          controller.selectedJobSubcategoryIds.value = items
                              .map((item) => item['id'] as int)
                              .toList();
                        },
                      ),
                      SizedBox(height: 2.h),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          TextFormField(
            controller: controller.jobDesignationController,
            decoration: const InputDecoration(
              labelText: 'Designation',
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: controller.jobDepartmentController,
            decoration: const InputDecoration(
              labelText: 'Department',
              prefixIcon: Icon(Icons.work),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.jobExperienceController,
                  decoration: const InputDecoration(
                    labelText: 'Exp (Years)',
                    prefixIcon: Icon(Icons.timeline),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Obx(
                  () => InkWell(
                    onTap: () => controller.selectJobJoinDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Join Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        controller.jobJoinDate.value != null
                            ? DateFormat(
                                'dd/MM/yyyy',
                              ).format(controller.jobJoinDate.value!)
                            : 'Select date',
                        style: TextStyle(
                          color: controller.jobJoinDate.value != null
                              ? AppTheme.textPrimary
                              : AppTheme.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection(BuildContext context) {
    return Obx(() {
      final forms = controller.businessForms;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, 'Business Details'),
              if (forms.length < 5)
                TextButton.icon(
                  onPressed: () => controller.addBusinessForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Business'),
                ),
            ],
          ),
          SizedBox(height: 2.h),

          if (forms.isEmpty) const Text('No businesses added.'),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: forms.length,
            separatorBuilder: (context, index) => Column(
              children: [
                SizedBox(height: 2.h),
                Divider(thickness: 1, color: Colors.grey[300]),
                SizedBox(height: 2.h),
              ],
            ),
            itemBuilder: (context, index) {
              final form = forms[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Business ${index + 1}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (forms.length > 1 || form.id != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => controller.removeBusinessForm(index),
                        ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Logo Picker
                  Center(
                    child: GestureDetector(
                      onTap: () => controller.pickBusinessLogo(index),
                      child: Obx(() {
                        if (form.logo.value != null) {
                          return CircleAvatar(
                            radius: 40,
                            backgroundImage: FileImage(form.logo.value!),
                          );
                        } else if (form.currentLogoUrl?.value != null &&
                            form.currentLogoUrl!.value!.isNotEmpty) {
                          return CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(
                              ApiConstants.getFullUrl(
                                form.currentLogoUrl!.value,
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: Colors.grey[600],
                            ),
                          );
                        }
                      }),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  TextFormField(
                    controller: form.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name *',
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 2.h),

                  // Business Type
                  Obx(
                    () => DropdownSearch<Map<String, dynamic>>(
                      items: (filter, _) => controller.businessTypes.toList(),
                      selectedItem: controller.businessTypes.firstWhereOrNull(
                        (t) => t['id'] == form.selectedTypeId.value,
                      ),
                      itemAsString: (item) => item['type_name'] ?? '',
                      compareFn: (a, b) => a['id'] == b['id'],
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Business Type',
                          prefixIcon: Icon(Icons.business_center),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search type...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      onChanged: (item) {
                        form.selectedTypeId.value = item?['id'];
                      },
                      validator: (v) => v == null ? 'Required' : null,
                      onBeforePopupOpening: (selectedItem) async {
                        FocusScope.of(context).unfocus();
                        return true;
                      },
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Business Category
                  Obx(
                    () => DropdownSearch<Map<String, dynamic>>(
                      items: (filter, _) =>
                          controller.businessCategories.toList(),
                      selectedItem: controller.businessCategories
                          .firstWhereOrNull(
                            (c) => c['id'] == form.selectedCategoryId.value,
                          ),
                      itemAsString: (item) => item['category_name'] ?? '',
                      compareFn: (a, b) => a['id'] == b['id'],
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Business Category',
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search category...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      onChanged: (item) {
                        if (item != null) {
                          form.selectedCategoryId.value = item['id'];
                          // Reset subcategories when category changes
                          form.selectedSubcategoryIds.clear();
                        }
                      },
                      validator: (v) => v == null ? 'Required' : null,
                      onBeforePopupOpening: (selectedItem) async {
                        FocusScope.of(context).unfocus();
                        return true;
                      },
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Business Subcategories
                  Obx(() {
                    if (form.selectedCategoryId.value == null) {
                      return const SizedBox.shrink();
                    }
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: controller.getSubcategoriesForForm(
                        form.selectedCategoryId.value!,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final subcategories = snapshot.data!;

                        return DropdownSearch<
                          Map<String, dynamic>
                        >.multiSelection(
                          items: (filter, _) => subcategories,
                          selectedItems: subcategories
                              .where(
                                (s) => form.selectedSubcategoryIds.contains(
                                  s['id'],
                                ),
                              )
                              .toList(),
                          itemAsString: (item) =>
                              item['subcategory_name'] ?? '',
                          compareFn: (a, b) => a['id'] == b['id'],
                          decoratorProps: const DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: 'Business Subcategories',
                              prefixIcon: Icon(Icons.category_outlined),
                              hintText: 'Select multiple',
                            ),
                          ),
                          popupProps: PopupPropsMultiSelection.menu(
                            showSearchBox: true,
                            searchFieldProps: const TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search subcategories...',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          onChanged: (items) {
                            form.selectedSubcategoryIds.value = items
                                .map((i) => i['id'] as int)
                                .toList();
                          },
                          onBeforePopupOpening: (selectedItems) async {
                            FocusScope.of(context).unfocus();
                            return true;
                          },
                        );
                      },
                    );
                  }),
                  SizedBox(height: 2.h),

                  TextFormField(
                    controller: form.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: form.addressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address *',
                      prefixIcon: Icon(Icons.place),
                    ),
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 2.h),

                  // Phone and Email
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: form.phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: TextFormField(
                          controller: form.emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  TextFormField(
                    controller: form.websiteUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      prefixIcon: Icon(Icons.language),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  SizedBox(height: 2.h),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: form.gstNumberController,
                          decoration: const InputDecoration(
                            labelText: 'GST Number',
                            prefixIcon: Icon(Icons.receipt),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: TextFormField(
                          controller: form.yearOfEstablishmentController,
                          decoration: const InputDecoration(
                            labelText: 'Est. Year',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: form.numberOfEmployeesController,
                          decoration: const InputDecoration(
                            labelText: 'Employees',
                            prefixIcon: Icon(Icons.people),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: TextFormField(
                          controller: form.annualTurnoverController,
                          decoration: const InputDecoration(
                            labelText: 'Turnover',
                            prefixIcon: Icon(Icons.monetization_on),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      );
    });
  }
}
