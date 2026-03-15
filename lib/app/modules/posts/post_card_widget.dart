import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../main/post_detail_view.dart';
import 'posts_controller.dart';
import '../../core/utils/date_utils.dart';

/// Shared Post Card Widget - Used by both PostsView and HomeTab
class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onTap;
  final bool compact;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final postType = post['post_type']?.toString() ?? '';
    final user = post['user'] as Map<String, dynamic>?;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 1.5.h : 2.h),
      child: InkWell(
        onTap: onTap ?? () => _showPostDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 3.w : 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  UserAvatar(
                    radius: compact ? 16 : 20,
                    imageUrl: user?['profile_picture'],
                    name: user?['name'] ?? 'Anonymous',
                    backgroundColor: getPostTypeColor(
                      postType,
                    ).withOpacity(0.1),
                    iconColor: getPostTypeColor(postType),
                    enablePopup: true,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['name'] ?? 'Anonymous',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppDateUtils.formatTimeAgo(post['created_at']),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getPostTypeColor(postType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getPostTypeLabel(postType),
                      style: TextStyle(
                        color: getPostTypeColor(postType),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  _buildMoreMenu(context, post),
                ],
              ),
              SizedBox(height: compact ? 1.h : 2.h),

              // Title
              Text(
                post['title'] ?? '',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),

              // Description
              Text(
                post['description'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Additional Info (hidden in compact mode)
              if (!compact) ...[
                SizedBox(height: 1.5.h),
                Wrap(
                  spacing: 3.w,
                  runSpacing: 1.h,
                  children: [
                    if (post['location'] != null)
                      _buildInfoChip(Icons.location_on, post['location']),
                    if (post['salary_range'] != null)
                      _buildInfoChip(
                        Icons.currency_rupee,
                        post['salary_range'],
                      ),
                    if (post['investment_amount'] != null)
                      _buildInfoChip(
                        Icons.currency_rupee,
                        post['investment_amount'],
                      ),
                    if (post['category'] != null)
                      _buildInfoChip(Icons.category, post['category']),
                  ],
                ),
              ],

              // Comment Previews
              if (post['latest_comments'] != null &&
                  (post['latest_comments'] as List).isNotEmpty) ...[
                SizedBox(height: 2.h),
                Divider(height: 1, color: Colors.grey[300]),
                SizedBox(height: 1.h),
                _buildCommentPreviews(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, Map<String, dynamic> post) {
    // Determine if current user is the owner to show delete/edit instead of report/block
    // but without full controller access we can just show report/block and handle it in the controller action
    // For simplicity, we just provide the menu universally.
    final user = post['user'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? 'User';

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) {
        if (value == 'report') {
          // Send to controller or show dialog
          _showReportDialog(context, post['id']);
        } else if (value == 'block') {
          _showBlockDialog(context, user?['id'], userName);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Report Post'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Block User'),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context, dynamic postId) {
    String reason = '';
    Get.dialog(
      AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this post?'),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                hintText: 'e.g. Spam, inappropriate, generic',
              ),
              onChanged: (val) => reason = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reason.trim().isEmpty) {
                Get.snackbar('Error', 'Please enter a reason');
                return;
              }
              Get.back();

              if (Get.isRegistered<PostsController>()) {
                try {
                  Get.find<PostsController>().reportPost(postId, reason);
                } catch (e) {
                  debugPrint('Failed to call reportPost: $e');
                }
              } else {
                debugPrint('PostsController is not registered');
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, dynamic userId, String userName) {
    Get.dialog(
      AlertDialog(
        title: Text('Block $userName?'),
        content: const Text(
          'They will not be able to interact with you and their posts will be hidden from your feed.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();

              if (Get.isRegistered<PostsController>()) {
                try {
                  Get.find<PostsController>().blockUser(userId, userName);
                } catch (e) {
                  debugPrint('Failed to call blockUser: $e');
                }
              } else {
                debugPrint('PostsController is not registered');
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentPreviews(BuildContext context) {
    final comments = (post['latest_comments'] as List)
        .cast<Map<String, dynamic>>();
    final totalComments = comments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...comments
            .take(3)
            .map(
              (comment) => Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        (comment['user_name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['user_name'] ?? 'Anonymous',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          Text(
                            comment['content'] ?? '',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (totalComments > 3)
          TextButton(
            onPressed: () => _showPostDetail(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View all $totalComments comments',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: Colors.grey),
        SizedBox(width: 1.w),
        Text(
          text,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showPostDetail(BuildContext context) {
    Get.to(() => PostDetailView(post: post));
  }

  // Static helper methods for external use
  static Color getPostTypeColor(String type) {
    switch (type) {
      case 'job_seeking':
        return Colors.blue;
      case 'investment':
        return Colors.green;
      case 'hiring':
        return Colors.orange;
      case 'ad':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  static IconData getPostTypeIcon(String type) {
    switch (type) {
      case 'job_seeking':
        return Icons.work;
      case 'investment':
        return Icons.trending_up;
      case 'hiring':
        return Icons.person_add;
      case 'ad':
        return Icons.campaign;
      default:
        return Icons.article;
    }
  }

  static String getPostTypeLabel(String type) {
    switch (type) {
      case 'job_seeking':
        return 'JOB';
      case 'investment':
        return 'INVEST';
      case 'hiring':
        return 'HIRING';
      case 'ad':
        return 'AD';
      default:
        return 'POST';
    }
  }
}
