import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/user_profile_content.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';
import '../../data/services/auth_service.dart';
import 'directory_controller.dart';

class UserDetailView extends StatefulWidget {
  final String userId;

  const UserDetailView({super.key, required this.userId});

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  final DirectoryController controller = Get.find<DirectoryController>();
  final ApiProvider _api = Get.find<ApiProvider>();
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> userPosts = [];
  bool isLoading = true;
  bool isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await controller.getUserProfile(widget.userId);
    setState(() {
      user = data;
      isLoading = false;
    });
    // Load posts using numeric_id from profile
    if (data != null) {
      final numericId = data['numeric_id'];
      if (numericId != null) {
        _loadPosts(numericId);
      }
    }
  }

  Future<void> _loadPosts(dynamic userId) async {
    setState(() => isLoadingPosts = true);
    try {
      final response = await _api.get('${ApiConstants.userPosts}/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          userPosts = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading user posts: $e');
    }
    setState(() => isLoadingPosts = false);
  }

  bool _isOwnProfile() {
    if (user == null) return false;
    final currentUser = Get.find<AuthService>().currentUser.value;
    if (currentUser == null) return false;
    return user!['id'] == currentUser['id'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user?['full_name'] ?? 'User Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? const Center(child: Text('User not found'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserProfileContent(
                    user: user!,
                    isOwnProfile: _isOwnProfile(),
                  ),
                  SizedBox(height: 2.h),
                  _buildPostsSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildPostsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posts',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 2.h),
        if (isLoadingPosts)
          const Center(child: CircularProgressIndicator())
        else if (userPosts.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'No posts yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: userPosts.length,
            separatorBuilder: (c, i) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final post = userPosts[index];
              return _buildPostItem(context, post);
            },
          ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildPostItem(BuildContext context, Map<String, dynamic> post) {
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
            Text(
              _formatDate(post['created_at']),
              style: TextStyle(color: Colors.grey, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    return AppDateUtils.formatDate(dateStr);
  }

  String _formatPostType(String? type) {
    if (type == null) return '';
    return type.split('_').map((word) => word.capitalizeFirst).join(' ');
  }
}
