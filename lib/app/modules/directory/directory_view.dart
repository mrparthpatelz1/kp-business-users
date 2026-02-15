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
              decoration: InputDecoration(
                hintText: 'Search by name, village, business...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.searchQuery.value = '';
                            controller.loadUsers(refresh: true);
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
                if (value.isEmpty) {
                  controller.search('');
                }
              },
            ),
          ),

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
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: controller.users.length + 1,
                  itemBuilder: (context, index) {
                    if (index == controller.users.length) {
                      if (controller.currentPage.value <
                          controller.totalPages.value) {
                        controller.loadMore();
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

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => Get.to(() => UserDetailView(userId: user['id'])),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Profile Photo
              UserAvatar(
                radius: 28,
                imageUrl: user['profile_picture'],
                name: user['full_name'] ?? user['surname'],
                isBusiness: isBusinessUser,
              ),
              SizedBox(width: 4.w),

              // User Info
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
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isBusinessUser
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            userType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isBusinessUser
                                  ? AppTheme.primaryColor
                                  : AppTheme.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    if (user['native_village'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              user['native_village'],
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (user['current_address'] != null) ...[
                      SizedBox(height: 0.3.h),
                      Row(
                        children: [
                          Icon(Icons.home, size: 14.sp, color: Colors.grey),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              user['current_address'],
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
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
