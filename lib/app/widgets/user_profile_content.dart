import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import 'user_avatar.dart';
import '../modules/profile/profile_controller.dart';
import '../modules/chat/chat_controller.dart';

import '../routes/app_routes.dart';

class UserProfileContent extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isOwnProfile;

  // We can get the controller via Get.find if it's in the context of ProfileView,
  // or pass it. Since this widget might be used elsewhere without ProfileController,
  // let's try to find it gracefully or handle logic differently.
  // However, for "My Posts" and "Change Password", it relies heavily on ProfileController logic.
  // Let's assume ProfileController is available if isOwnProfile is true.

  const UserProfileContent({
    super.key,
    required this.user,
    this.isOwnProfile = false,
  });

  ProfileController? get controller {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Basic Parsing (same as before)
    final village = user['native_village'];

    final nativeVillage = village is Map
        ? village['name']
        : (village ?? user['native_village']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. New Summarized Header
        _buildNewHeader(context, user, nativeVillage),
        SizedBox(height: 2.h),

        // 2. Change Password Section (Moved to top)
        if (isOwnProfile) ...[
          Text(
            'Security',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 1.h),
          _buildChangePasswordSection(context),
          SizedBox(height: 3.h),
          const Divider(),
          SizedBox(height: 2.h),
        ],

        // 3. User Posts Section (My Posts)
        if (isOwnProfile && controller != null) ...[
          Text(
            'My Posts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 2.h),
          Obx(() {
            if (controller!.userPosts.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Text(
                    'No posts yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }
            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller!.userPosts.length,
              separatorBuilder: (c, i) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final post = controller!.userPosts[index];
                return _buildMyPostItem(context, post);
              },
            );
          }),
          SizedBox(height: 2.h),
        ],
      ],
    );
  }

  // --- Header Section ---
  Widget _buildNewHeader(
    BuildContext context,
    Map<String, dynamic> user,
    String? villageName,
  ) {
    // Should show: Name, Saakh, Specific details (Business name/cat or Job details), Student tag
    final userType = user['user_type']?.toString().toLowerCase();

    // Extract Saakh (Surname)
    final saakh = user['surname'] ?? '';

    // Extract subtitle info based on user type
    String subtitle = '';
    String subSubtitle = '';

    if (userType == 'business') {
      final businesses = user['businesses'] as List?;
      if (businesses != null && businesses.isNotEmpty) {
        final b = businesses[0];
        subtitle = b['business_name'] ?? 'Business Owner';
        subSubtitle = b['category']?['name'] ?? b['category_name'] ?? '';
        if (subSubtitle.isNotEmpty) {
          final sub = b['subcategories'];
          if (sub != null) {
            // If it's a list or single object, try to get name
            // Simplified for display
          }
        }
      } else {
        subtitle = 'Business Owner';
      }
    } else if (userType == 'job') {
      final job = user['job'];
      if (job != null) {
        subtitle = job['designation'] ?? 'Employee';
        subSubtitle = job['company_name'] ?? '';
        // If company is empty, maybe show category
        if (subSubtitle.isEmpty) {
          subSubtitle = job['category']?['name'] ?? '';
        }
      } else {
        subtitle = 'Job Professional';
      }
    } else if (userType == 'student') {
      subtitle = 'Student';
      // Maybe show education?
      final edu = user['education'] as List?;
      if (edu != null && edu.isNotEmpty) {
        subSubtitle = edu[0]['degree_name'] ?? edu[0]['qualification'] ?? '';
      }
    }

    return Card(
      elevation: 3,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Get.toNamed(Routes.FULL_PROFILE, arguments: user);
        },
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(5.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  UserAvatar(
                    radius: 35,
                    imageUrl: user['profile_picture'],
                    name: user['full_name'] ?? 'U',
                  ),
                  SizedBox(width: 4.w),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (saakh.isNotEmpty) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            saakh, // Just the surname/saakh
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                        if (villageName != null) ...[
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                villageName,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 1.h),
                        Divider(height: 1.5.h),
                        // Role/Work Info
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (subSubtitle.isNotEmpty)
                          Text(
                            subSubtitle,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        // Add some space at bottom for the button
                        if (subtitle.isNotEmpty || subSubtitle.isNotEmpty)
                          SizedBox(height: 3.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 2.w,
              right: 2.w,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isOwnProfile && user['numeric_id'] != null)
                    TextButton.icon(
                      onPressed: () {
                        final chatController = Get.put(ChatController());
                        chatController.startConversation(user['numeric_id']);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        Icons.message_rounded,
                        size: 14.sp,
                        color: AppTheme.primaryColor,
                      ),
                      label: Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!isOwnProfile && user['numeric_id'] != null)
                    SizedBox(width: 2.w),
                  TextButton(
                    onPressed: () {
                      Get.toNamed(Routes.FULL_PROFILE, arguments: user);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Profile',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10.sp,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- My Post Item ---
  Widget _buildMyPostItem(BuildContext context, Map<String, dynamic> post) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post['title'] ?? 'No Title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatPostType(post['post_type']),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              post['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 14.sp),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(post['created_at']),
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Edit Post
                        if (controller != null) {
                          controller?.editPost(post);
                        }
                      },
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Delete Post
                        _showDeleteConfirmDialog(context, post['id']);
                      },
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, dynamic postId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller?.deletePost(postId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- Change Password Section ---
  // --- Change Password Section ---
  Widget _buildChangePasswordSection(BuildContext context) {
    if (controller == null) return const SizedBox.shrink();
    return _ChangePasswordWidget(controller: controller!);
  }

  // --- Helpers ---

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatPostType(String? type) {
    if (type == null) return '';
    return type.split('_').map((word) => word.capitalizeFirst).join(' ');
  }

  // --- Reused Section Builders ---
}

class _ChangePasswordWidget extends StatefulWidget {
  final ProfileController controller;

  const _ChangePasswordWidget({required this.controller});

  @override
  State<_ChangePasswordWidget> createState() => _ChangePasswordWidgetState();
}

class _ChangePasswordWidgetState extends State<_ChangePasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _isLoading = false.obs;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      Get.snackbar(
        'Error',
        'New passwords do not match',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _isLoading.value = true;
    final res = await widget.controller.changePassword(
      _oldPassCtrl.text,
      _newPassCtrl.text,
    );
    _isLoading.value = false;

    if (res['success'] == true) {
      Get.snackbar(
        'Success',
        'Password changed successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    } else {
      Get.snackbar(
        'Error',
        res['message'] ?? 'Failed to change password',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.lock, color: AppTheme.primaryColor),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _oldPassCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Old Password',
                    ),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 1.h),
                  TextFormField(
                    controller: _newPassCtrl,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                  ),
                  SizedBox(height: 1.h),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                    ),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 2.h),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading.value ? null : _submit,
                        child: _isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update Password'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
