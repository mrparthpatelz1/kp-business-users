import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../core/theme/app_theme.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Obx(() => _buildProgressIndicator()),

            // Form pages
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1PersonalInfo(context),
                  _buildStep2AddressInfo(context),
                  _buildStep3UserType(context),
                  _buildStep4Education(context),
                  _buildStep5Details(context),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Row(
        children: List.generate(controller.totalSteps.value, (index) {
          final isActive = index <= controller.currentStep.value;
          final isComplete = index < controller.currentStep.value;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isComplete
                        ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                  ),
                ),
                if (index < controller.totalSteps.value - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index < controller.currentStep.value
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1PersonalInfo(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Form(
        key: controller.step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Fill in your basic details',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 3.h),

            // Profile Picture Picker
            Center(
              child: Stack(
                children: [
                  Obx(
                    () => CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: controller.profileImage.value != null
                          ? FileImage(controller.profileImage.value!)
                          : null,
                      child: controller.profileImage.value == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => controller.showImagePickerOptions(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Center(
              child: Text(
                'Upload Profile Picture *',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Error message
            Obx(
              () => controller.errorMessage.isNotEmpty
                  ? _buildErrorMessage()
                  : const SizedBox.shrink(),
            ),

            // Full Name & Saakh Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextFormField(
                    controller: controller.surnameController,
                    decoration: const InputDecoration(labelText: 'Saakh *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Email
            Obx(
              () => TextFormField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: controller.isCheckingEmail.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : controller.emailController.text.isNotEmpty &&
                            GetUtils.isEmail(controller.emailController.text)
                      ? Icon(
                          controller.emailAvailable.value
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: controller.emailAvailable.value
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        )
                      : null,
                ),

                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (!GetUtils.isEmail(v)) return 'Invalid email';
                  return null;
                },
              ),
            ),
            SizedBox(height: 2.h),

            // Phone with country code dropdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country Code Dropdown
                SizedBox(
                  width: 28.w,
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.phoneCountryCode.value,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                      ),
                      isExpanded: true,
                      items: controller.countryDialCodes.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['code'],
                          child: Text(
                            '${c['code']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          controller.phoneCountryCode.value = v ?? '+91',
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                // Phone Number Field
                Expanded(
                  child: Obx(
                    () => TextFormField(
                      controller: controller.phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number *',
                        suffixIcon: controller.isCheckingPhone.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : controller.phoneController.text.length == 10
                            ? Icon(
                                controller.phoneAvailable.value
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: controller.phoneAvailable.value
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                              )
                            : null,
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(v))
                          return 'Enter 10 digit number';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Gender
            Text('Gender *', style: Theme.of(context).textTheme.titleMedium),
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
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
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
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 2.h),

            // Password
            Obx(
              () => TextFormField(
                controller: controller.passwordController,
                obscureText: controller.obscurePassword.value,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => controller.obscurePassword.toggle(),
                  ),
                  helperText: 'Min 6 characters',
                  helperMaxLines: 1,
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
            ),
            SizedBox(height: 2.h),

            // Confirm Password
            Obx(
              () => TextFormField(
                controller: controller.confirmPasswordController,
                obscureText: controller.obscureConfirmPassword.value,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureConfirmPassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => controller.obscureConfirmPassword.toggle(),
                  ),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (v != controller.passwordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2AddressInfo(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Form(
        key: controller.step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),
            Text(
              'Address Information',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Where do you live?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 3.h),

            // Error message
            Obx(
              () => controller.errorMessage.isNotEmpty
                  ? _buildErrorMessage()
                  : const SizedBox.shrink(),
            ),

            // Native Village - Searchable
            Obx(
              () => DropdownSearch<Map<String, dynamic>>(
                items: (filter, _) => controller.villages.toList(),
                selectedItem: controller.villages.firstWhereOrNull(
                  (v) => v['id'] == controller.selectedVillageId.value,
                ),
                itemAsString: (item) => item['village_name'] ?? '',
                compareFn: (a, b) => a['id'] == b['id'],
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: 'Native Village *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    hintText: 'Select your native village',
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search village...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                onChanged: (item) {
                  controller.selectedVillageId.value = item?['id'];
                },
                validator: (v) => v == null ? 'Required' : null,
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
                    style: Theme.of(context).textTheme.titleMedium,
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
                if (!RegExp(r'^[0-9]{6}$').hasMatch(v))
                  return 'Enter 6 digit zipcode';
                return null;
              },
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3UserType(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Text(
            'Select Your Category',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            'What best describes you?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 3.h),

          // Error message
          Obx(
            () => controller.errorMessage.isNotEmpty
                ? _buildErrorMessage()
                : const SizedBox.shrink(),
          ),

          Obx(
            () => Column(
              children: [
                _buildUserTypeCard(
                  context,
                  icon: Icons.business,
                  title: 'Business Owner',
                  subtitle: 'I own or run a business',
                  value: 'business',
                  isSelected: controller.userType.value == 'business',
                ),
                SizedBox(height: 2.h),
                _buildUserTypeCard(
                  context,
                  icon: Icons.work_outline,
                  title: 'Working Professional',
                  subtitle: 'I am employed in a job',
                  value: 'job',
                  isSelected: controller.userType.value == 'job',
                ),

                SizedBox(height: 2.h),
                _buildUserTypeCard(
                  context,
                  icon: Icons.school_outlined,
                  title: 'Student',
                  subtitle: 'I am currently studying',
                  value: 'student',
                  isSelected: controller.userType.value == 'student',
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildStep4Education(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Text(
            'Education Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            'Optional - Fill all fields if you want to add education',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 3.h),

          // Error message
          Obx(
            () => controller.errorMessage.isNotEmpty
                ? _buildErrorMessage()
                : const SizedBox.shrink(),
          ),

          // Education Type Selection
          Text(
            'Education Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => controller.educationType.value = 'school',
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: controller.educationType.value == 'school'
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: controller.educationType.value == 'school'
                              ? AppTheme.primaryColor
                              : AppTheme.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school,
                            color: controller.educationType.value == 'school'
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'School',
                            style: TextStyle(
                              color: controller.educationType.value == 'school'
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                              fontWeight:
                                  controller.educationType.value == 'school'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: InkWell(
                    onTap: () => controller.educationType.value = 'college',
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: controller.educationType.value == 'college'
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: controller.educationType.value == 'college'
                              ? AppTheme.primaryColor
                              : AppTheme.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.apartment,
                            color: controller.educationType.value == 'college'
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'College',
                            style: TextStyle(
                              color: controller.educationType.value == 'college'
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                              fontWeight:
                                  controller.educationType.value == 'college'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Institution Name
          Obx(
            () => TextFormField(
              controller: controller.institutionController,
              decoration: InputDecoration(
                labelText: controller.educationType.value == 'school'
                    ? 'School Name'
                    : 'College/University Name',
                hintText: controller.educationType.value == 'school'
                    ? 'e.g. Delhi Public School'
                    : 'e.g. Gujarat University',
                prefixIcon: const Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          SizedBox(height: 1.5.h),

          // Course/Standard
          Obx(
            () => TextFormField(
              controller: controller.qualificationController,
              decoration: InputDecoration(
                labelText: controller.educationType.value == 'school'
                    ? 'Standard/Class'
                    : 'Course/Degree',
                hintText: controller.educationType.value == 'school'
                    ? 'e.g. 10th, 12th'
                    : 'e.g. B.Tech, MBA',
                prefixIcon: const Icon(Icons.book),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          SizedBox(height: 1.5.h),

          // Field of Study (only for college)
          Obx(
            () => controller.educationType.value == 'college'
                ? Column(
                    children: [
                      TextFormField(
                        controller: controller.fieldOfStudyController,
                        decoration: const InputDecoration(
                          labelText: 'Branch/Stream',
                          hintText: 'e.g. Computer Science, Commerce',
                          prefixIcon: Icon(Icons.category),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      SizedBox(height: 1.5.h),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Start Year
          TextFormField(
            controller: controller.startYearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Start Year',
              hintText: '2018',
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          SizedBox(height: 1.5.h),

          // Currently Studying Toggle
          Obx(
            () => SwitchListTile(
              title: const Text('Currently Studying'),
              subtitle: const Text('Turn on if still enrolled'),
              value: controller.isCurrentlyStudying.value,
              onChanged: (val) => controller.isCurrentlyStudying.value = val,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 1.h),

          // Conditional fields based on currently studying
          Obx(
            () => controller.isCurrentlyStudying.value
                ? TextFormField(
                    controller: controller.currentYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Year of Study',
                      hintText: 'e.g. 2 (for 2nd year)',
                      prefixIcon: Icon(Icons.timeline),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.passingYearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Passing Year',
                                hintText: '2022',
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: TextFormField(
                              controller: controller.gradeController,
                              decoration: const InputDecoration(
                                labelText: 'Grade / %',
                                hintText: '85%',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildStep5Details(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Form(
        key: controller.step4FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),
            Text(
              'Additional Details',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Optional information to complete your profile',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 3.h),

            // Error message
            Obx(
              () => controller.errorMessage.isNotEmpty
                  ? _buildErrorMessage()
                  : const SizedBox.shrink(),
            ),

            // Business details (if business type selected)
            Obx(() {
              if (controller.userType.value == 'business') {
                return _buildBusinessSection(context);
              } else if (controller.userType.value == 'job') {
                return _buildJobSection(context);
              }
              return const SizedBox.shrink();
            }),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSection(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, 'Business Details', Icons.business),
              if (controller.businessForms.length < 5) // Limit to 5 businesses
                TextButton.icon(
                  onPressed: controller.addBusinessForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Business'),
                ),
            ],
          ),
          SizedBox(height: 1.5.h),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.businessForms.length,
            separatorBuilder: (context, index) => Column(
              children: [
                SizedBox(height: 2.h),
                Divider(thickness: 1, color: Colors.grey[300]),
                SizedBox(height: 2.h),
              ],
            ),
            itemBuilder: (context, index) {
              final form = controller.businessForms[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.businessForms.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Business ${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => controller.removeBusinessForm(index),
                        ),
                      ],
                    ),

                  // Business Logo Upload
                  Center(
                    child: Column(
                      children: [
                        Obx(
                          () => GestureDetector(
                            onTap: () => controller.pickBusinessLogo(index),
                            child: Container(
                              width: 25.w,
                              height: 25.w,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                                image: form.logo.value != null
                                    ? DecorationImage(
                                        image: FileImage(form.logo.value!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: form.logo.value == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 24.sp,
                                          color: AppTheme.primaryColor,
                                        ),
                                        SizedBox(height: 0.5.h),
                                        Text(
                                          'Logo',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Upload Business Logo (Optional)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),

                  TextFormField(
                    controller: form.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name *',
                      prefixIcon: Icon(Icons.store),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v!.isEmpty ? 'Business name is required' : null,
                  ),
                  SizedBox(height: 1.5.h),

                  // Year of Establishment
                  TextFormField(
                    controller: form.yearOfEstablishmentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Year of Establishment',
                      prefixIcon: Icon(Icons.calendar_today),
                      hintText: 'e.g. 2015',
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  TextFormField(
                    controller: form.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Business Email',
                      prefixIcon: Icon(Icons.email),
                      hintText: 'Leave empty if same as personal',
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !GetUtils.isEmail(v)) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 1.5.h),

                  // Business Phone with country code dropdown
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28.w,
                        child: Obx(
                          () => DropdownButtonFormField<String>(
                            value: form.phoneCountryCode.value,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 16,
                              ),
                            ),
                            isExpanded: true,
                            items: controller.countryDialCodes.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['code'],
                                child: Text(
                                  '${c['code']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                form.phoneCountryCode.value = v ?? '+91',
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: TextFormField(
                          controller: form.phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Business Phone',
                            hintText: 'Leave empty if same as personal',
                          ),
                          validator: (v) {
                            if (v != null &&
                                v.isNotEmpty &&
                                !RegExp(r'^[0-9]{10}$').hasMatch(v)) {
                              return 'Enter valid 10 digit number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),

                  // GST Number
                  TextFormField(
                    controller: form.gstNumberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'GST Number',
                      prefixIcon: Icon(Icons.numbers),
                      hintText: 'Optional',
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Website URL
                  TextFormField(
                    controller: form.websiteUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Website URL',
                      prefixIcon: Icon(Icons.language),
                      hintText: 'e.g. www.example.com',
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Number of Employees
                  TextFormField(
                    controller: form.numberOfEmployeesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of Employees',
                      prefixIcon: Icon(Icons.people),
                      hintText: 'e.g. 10',
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Annual Turnover
                  TextFormField(
                    controller: form.annualTurnoverController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Annual Turnover',
                      prefixIcon: Icon(Icons.currency_rupee),
                      hintText: 'e.g. 5000000',
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Business Type - Searchable Dropdown
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
                          labelText: 'Business Type *',
                          prefixIcon: Icon(Icons.category),
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
                      validator: (v) =>
                          v == null ? 'Business type is required' : null,
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Business Category - Searchable Dropdown
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
                          labelText: 'Business Category *',
                          prefixIcon: Icon(Icons.label),
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
                      onChanged: (item) async {
                        if (item != null) {
                          form.selectedCategoryId.value = item['id'];
                          // We need a specific list for this form, but we are using DropdownSearch.multiSelection below.
                          // The view needs a list of subcategories.
                          // But we replaced `loadBusinessSubcategories` in controller which was updating a SINGLE list.
                          // We need `form.subcategories` list.
                          // I will add `subcategories` to BusinessFormState via the onInit or just use FutureBuilder here?
                          // Better: Add `RxList<Map<String, dynamic>> subcategories` to BusinessFormState.
                        }
                      },
                      validator: (v) =>
                          v == null ? 'Business category is required' : null,
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Business Subcategories - Using FutureBuilder to fetch for this specific category
                  Obx(() {
                    if (form.selectedCategoryId.value == null)
                      return const SizedBox.shrink();

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: controller.getSubcategoriesForForm(
                        form.selectedCategoryId.value!,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        final subcategories = snapshot.data!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownSearch<Map<String, dynamic>>.multiSelection(
                              items: (filter, _) => subcategories,
                              selectedItems: subcategories
                                  .where(
                                    (sub) => form.selectedSubcategoryIds
                                        .contains(sub['id']),
                                  )
                                  .toList(),
                              itemAsString: (item) =>
                                  item['subcategory_name'] ?? '',
                              compareFn: (a, b) => a['id'] == b['id'],
                              decoratorProps: const DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Business Subcategories *',
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
                                form.selectedSubcategoryIds.value = items
                                    .map((item) => item['id'] as int)
                                    .toList();
                              },
                            ),
                            SizedBox(height: 1.5.h),
                          ],
                        );
                      },
                    );
                  }),

                  TextFormField(
                    controller: form.addressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address *',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    validator: (v) =>
                        v!.isEmpty ? 'Business address is required' : null,
                  ),
                  SizedBox(height: 1.5.h),

                  TextFormField(
                    controller: form.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Business Description',
                      hintText: 'Brief description of your business',
                    ),
                    maxLines: 3,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Job Details', Icons.work),
        SizedBox(height: 1.5.h),

        Obx(
          () => SwitchListTile(
            title: const Text('Currently Working Here'),
            subtitle: const Text('Turn off if you are not currently employed'),
            value: controller.isCurrentlyWorking.value,
            onChanged: (val) => controller.isCurrentlyWorking.value = val,
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 1.5.h),

        Obx(
          () => controller.isCurrentlyWorking.value
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: controller.companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        prefixIcon: Icon(Icons.business),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v!.isEmpty ? 'Company name is required' : null,
                    ),
                    SizedBox(height: 1.5.h),

                    TextFormField(
                      controller: controller.designationController,
                      decoration: const InputDecoration(
                        labelText: 'Designation/Role *',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v!.isEmpty ? 'Designation is required' : null,
                    ),
                    SizedBox(height: 1.5.h),

                    TextFormField(
                      controller: controller.experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Experience (in years)',
                        prefixIcon: Icon(Icons.timeline),
                        hintText: 'e.g. 3',
                      ),
                    ),
                    SizedBox(height: 1.5.h),

                    TextFormField(
                      controller: controller.departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.business_center),
                        hintText: 'e.g. IT, Sales, Marketing',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 1.5.h),

                    Obx(
                      () => InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1970),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            controller.dateOfJoining.value = date;
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Joining',
                            prefixIcon: Icon(Icons.calendar_today),
                            hintText: 'Tap to select date',
                          ),
                          child: Text(
                            controller.dateOfJoining.value != null
                                ? '${controller.dateOfJoining.value!.day}/${controller.dateOfJoining.value!.month}/${controller.dateOfJoining.value!.year}'
                                : 'Select date',
                            style: TextStyle(
                              color: controller.dateOfJoining.value != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 1.5.h),

                    // Job Type - Searchable Dropdown
                    DropdownSearch<Map<String, dynamic>>(
                      items: (filter, _) => controller.jobTypes.toList(),
                      selectedItem: controller.jobTypes.firstWhereOrNull(
                        (t) => t['id'] == controller.selectedJobTypeId.value,
                      ),
                      itemAsString: (item) => item['type_name'] ?? '',
                      compareFn: (a, b) => a['id'] == b['id'],
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Job Type *',
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
                        controller.selectedJobTypeId.value = item?['id'];
                      },
                      validator: (v) =>
                          v == null ? 'Job type is required' : null,
                    ),
                    SizedBox(height: 1.5.h),

                    // Job Category - Searchable Dropdown
                    DropdownSearch<Map<String, dynamic>>(
                      items: (filter, _) => controller.jobCategories.toList(),
                      selectedItem: controller.jobCategories.firstWhereOrNull(
                        (c) =>
                            c['id'] == controller.selectedJobCategoryId.value,
                      ),
                      itemAsString: (item) => item['category_name'] ?? '',
                      compareFn: (a, b) => a['id'] == b['id'],
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Job Category *',
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
                        if (item != null)
                          controller.loadJobSubcategories(item['id']);
                      },
                      validator: (v) =>
                          v == null ? 'Job category is required' : null,
                    ),
                    SizedBox(height: 1.5.h),

                    // Job Subcategories - Multi-Select Dropdown
                    Obx(
                      () => controller.jobSubcategories.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownSearch<
                                  Map<String, dynamic>
                                >.multiSelection(
                                  items: (filter, _) =>
                                      controller.jobSubcategories.toList(),
                                  selectedItems: controller.jobSubcategories
                                      .where(
                                        (sub) => controller
                                            .selectedJobSubcategoryIds
                                            .contains(sub['id']),
                                      )
                                      .toList(),
                                  itemAsString: (item) =>
                                      item['subcategory_name'] ?? '',
                                  compareFn: (a, b) => a['id'] == b['id'],
                                  decoratorProps: const DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: 'Job Subcategories *',
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
                                    controller.selectedJobSubcategoryIds.value =
                                        items
                                            .map((item) => item['id'] as int)
                                            .toList();
                                  },
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18.sp),
        ),
        SizedBox(width: 2.w),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildUserTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => controller.userType.value = value,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 22.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(
          () => Row(
            children: [
              if (controller.currentStep.value > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.previousStep,
                    child: const Text('Back'),
                  ),
                ),
              if (controller.currentStep.value > 0) SizedBox(width: 3.w),
              Expanded(
                flex: controller.currentStep.value == 0 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.nextStep,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          controller.currentStep.value ==
                                  controller.totalSteps.value - 1
                              ? 'Submit'
                              : 'Next',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(3.w),
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(color: AppTheme.errorColor, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
