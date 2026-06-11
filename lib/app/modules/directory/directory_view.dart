import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'directory_controller.dart';
import 'user_detail_view.dart';
import '../../widgets/shimmer_loading.dart';

class DirectoryView extends GetView<DirectoryController> {
  const DirectoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, village, business...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.searchController.clear();
                            controller.searchQuery.value = '';
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (value) => controller.search(value),
              onChanged: (value) {
                // Auto-search when query is empty or >= 3 characters
                if (value.length >= 3 || value.isEmpty) {
                  controller.searchQuery.value = value;
                }
              },
            ),
          ),

          // Total Members Card
          Obx(() => Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_alt_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Directory Members',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '${controller.totalUsers.value}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          SizedBox(height: 1.h),

          // Filter Chips
          Obx(() => _buildFilterChips()),

          // User List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.users.isEmpty) {
                return const ShimmerDirectory();
              }

              if (controller.users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 60.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No users found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 1.h),
                      TextButton(
                        onPressed: () => controller.clearFilters(),
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadUsers(refresh: true),
                child: ListView.builder(
                  controller: controller.scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: controller.users.length + 1,
                  itemBuilder: (context, index) {
                    if (index == controller.users.length) {
                      if (controller.isLoadingMore.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }


                    return _buildUserCard(context, controller.users[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final hasFilters =
        controller.selectedVillage.value.isNotEmpty ||
        controller.selectedUserType.value.isNotEmpty ||
        controller.selectedBusinessCategory.value.isNotEmpty ||
        controller.selectedBusinessSubcategory.value.isNotEmpty ||
        controller.selectedJobCategory.value.isNotEmpty ||
        controller.selectedJobSubcategory.value.isNotEmpty;

    if (!hasFilters) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Wrap(
        spacing: 2.w,
        children: [
          if (controller.selectedUserType.value.isNotEmpty)
            Chip(
              label: Text(controller.selectedUserType.value.toUpperCase()),
              onDeleted: () => controller.filterByUserType(''),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
          if (controller.selectedBusinessCategory.value.isNotEmpty)
            Chip(
              label: Text(
                'Bus: ${controller.businessCategories.firstWhere((cat) => cat['id'].toString() == controller.selectedBusinessCategory.value, orElse: () => {'category_name': 'Category'})['category_name']}',
              ),
              onDeleted: () => controller.filterByBusinessCategory(''),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
          if (controller.selectedBusinessSubcategory.value.isNotEmpty)
            Chip(
              label: Text(
                'Bus Sub: ${controller.businessSubcategories.firstWhere((sub) => sub['id'].toString() == controller.selectedBusinessSubcategory.value, orElse: () => {'subcategory_name': 'Subcategory'})['subcategory_name']}',
              ),
              onDeleted: () => controller.filterByBusinessSubcategory(''),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
          if (controller.selectedJobCategory.value.isNotEmpty)
            Chip(
              label: Text(
                'Job: ${controller.jobCategories.firstWhere((cat) => cat['id'].toString() == controller.selectedJobCategory.value, orElse: () => {'category_name': 'Category'})['category_name']}',
              ),
              onDeleted: () => controller.filterByJobCategory(''),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
          if (controller.selectedJobSubcategory.value.isNotEmpty)
            Chip(
              label: Text(
                'Job Sub: ${controller.jobSubcategories.firstWhere((sub) => sub['id'].toString() == controller.selectedJobSubcategory.value, orElse: () => {'subcategory_name': 'Subcategory'})['subcategory_name']}',
              ),
              onDeleted: () => controller.filterByJobSubcategory(''),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
          if (hasFilters)
            ActionChip(
              label: const Text('Clear All'),
              onPressed: () => controller.clearFilters(),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final userType = user['user_type']?.toString() ?? 'user';
    final isBusinessUser = userType == 'business';

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Get.to(() => UserDetailView(userId: user['id'])),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
            child: Row(
              children: [
                // Profile Avatar with border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isBusinessUser
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : AppTheme.accentColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: UserAvatar(
                    radius: 26,
                    imageUrl: user['profile_picture'],
                    name: user['full_name'] ?? user['surname'],
                    isBusiness: isBusinessUser,
                    enablePopup: true,
                  ),
                ),
                SizedBox(width: 3.5.w),

                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user['full_name'] ?? ''} ${user['surname'] ?? ''}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    fontSize: 14.5.sp,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isBusinessUser
                                  ? AppTheme.primaryColor.withOpacity(0.08)
                                  : AppTheme.accentColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              userType == 'job' ? 'JOB SEEKER' : userType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: isBusinessUser
                                    ? AppTheme.primaryColor
                                    : AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.8.h),
                      if (user['native_village'] != null && user['native_village'].toString().isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13.sp,
                              color: AppTheme.primaryColor.withOpacity(0.6),
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                user['native_village'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),

                // Details chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    Get.bottomSheet(
      isScrollControlled: true,
      SafeArea(
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Users',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                // User Type Filter
                Text(
                  'User Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 1.h),
                Obx(
                  () => Wrap(
                    spacing: 2.w,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: controller.selectedUserType.value.isEmpty,
                        onSelected: (_) {
                          controller.filterByUserType('');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Business'),
                        selected:
                            controller.selectedUserType.value == 'business',
                        onSelected: (_) {
                          controller.filterByUserType('business');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Job Seeker'),
                        selected: controller.selectedUserType.value == 'job',
                        onSelected: (_) {
                          controller.filterByUserType('job');
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                // Business Category Filter
                Obx(() {
                  // Show business filters only when NOT job seeker
                  if (controller.selectedUserType.value != 'job') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          value:
                              controller.selectedBusinessCategory.value.isEmpty
                              ? null
                              : controller.selectedBusinessCategory.value,
                          hint: const Text('Select category'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All Categories'),
                            ),
                            ...controller.businessCategories.map(
                              (cat) => DropdownMenuItem(
                                value: cat['id'].toString(),
                                child: Text(cat['category_name']),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              controller.filterByBusinessCategory(value ?? ''),
                        ),
                        SizedBox(height: 2.h),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                // Business Subcategory Filter
                Obx(() {
                  if (controller.selectedBusinessCategory.value.isNotEmpty &&
                      controller.businessSubcategories.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Subcategory',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          value:
                              controller
                                  .selectedBusinessSubcategory
                                  .value
                                  .isEmpty
                              ? null
                              : controller.selectedBusinessSubcategory.value,
                          hint: const Text('Select subcategory'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All Subcategories'),
                            ),
                            ...controller.businessSubcategories.map(
                              (sub) => DropdownMenuItem(
                                value: sub['id'].toString(),
                                child: Text(sub['subcategory_name']),
                              ),
                            ),
                          ],
                          onChanged: (value) => controller
                              .filterByBusinessSubcategory(value ?? ''),
                        ),
                        SizedBox(height: 2.h),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                // Job Category Filter
                Obx(() {
                  // Show job filters only when NOT business user
                  if (controller.selectedUserType.value != 'business') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          value: controller.selectedJobCategory.value.isEmpty
                              ? null
                              : controller.selectedJobCategory.value,
                          hint: const Text('Select category'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All Categories'),
                            ),
                            ...controller.jobCategories.map(
                              (cat) => DropdownMenuItem(
                                value: cat['id'].toString(),
                                child: Text(cat['category_name']),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              controller.filterByJobCategory(value ?? ''),
                        ),
                        SizedBox(height: 2.h),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                // Job Subcategory Filter
                Obx(() {
                  if (controller.selectedJobCategory.value.isNotEmpty &&
                      controller.jobSubcategories.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Subcategory',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          value: controller.selectedJobSubcategory.value.isEmpty
                              ? null
                              : controller.selectedJobSubcategory.value,
                          hint: const Text('Select subcategory'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All Subcategories'),
                            ),
                            ...controller.jobSubcategories.map(
                              (sub) => DropdownMenuItem(
                                value: sub['id'].toString(),
                                child: Text(sub['subcategory_name']),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              controller.filterByJobSubcategory(value ?? ''),
                        ),
                        SizedBox(height: 2.h),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
