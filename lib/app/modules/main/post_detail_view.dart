import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../posts/comments/comments_controller.dart';
import '../chat/chat_controller.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

class PostDetailView extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailView({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Initialize comments controller
    final commentsController =
        Get.isRegistered<CommentsController>(tag: post['id'].toString())
        ? Get.find<CommentsController>(tag: post['id'].toString())
        : Get.put(
            CommentsController(post['id'].toString()),
            tag: post['id'].toString(),
          );

    final postType = post['post_type'] ?? 'general';
    final isAd = postType == 'ad';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar - Large image header ONLY for ads
          if (isAd)
            SliverAppBar(
              expandedHeight: 35.h,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: post['image_url'] != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            post['image_url'].startsWith('http')
                                ? post['image_url']
                                : '${ApiConstants.assetBaseUrl}${post['image_url']}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _getPostTypeColor(
                                postType,
                              ).withValues(alpha: 0.1),
                              child: Icon(
                                _getPostTypeIcon(postType),
                                size: 100,
                                color: _getPostTypeColor(postType),
                              ),
                            ),
                          ),
                          // Gradient overlay for better readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: _getPostTypeColor(
                          postType,
                        ).withValues(alpha: 0.1),
                        child: Icon(
                          _getPostTypeIcon(postType),
                          size: 100,
                          color: _getPostTypeColor(postType),
                        ),
                      ),
              ),
            )
          else
            // Regular AppBar for non-ad posts
            SliverAppBar(
              pinned: true,
              title: Text(_getPostTypeLabel(postType)),
            ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info at Top
                  if (post['author'] != null) ...[
                    _buildAuthorHeader(context, post),
                    SizedBox(height: 2.h),
                    const Divider(),
                    SizedBox(height: 2.h),
                  ],

                  // Post Type Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getPostTypeColor(postType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getPostTypeColor(postType)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPostTypeIcon(postType),
                          color: _getPostTypeColor(postType),
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          _getPostTypeLabel(postType),
                          style: TextStyle(
                            color: _getPostTypeColor(postType),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Title and Share Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post['title'] ?? 'Post',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final String link =
                              'kpbusiness://post?id=${post['id']}';
                          Share.share(
                            'Check out this post: ${post['title']}\n$link',
                          );
                        },
                        icon: const Icon(Icons.share),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),

                  // Posted Date
                  if (post['created_at'] != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Posted ${_formatDate(post['created_at'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Description
                  if (post['description'] != null &&
                      post['description'].isNotEmpty) ...[
                    const Divider(),
                    SizedBox(height: 2.h),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      post['description'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 3.h),
                  ],

                  // Additional metadata for job/investment posts
                  if (postType == 'job_seeking' || postType == 'hiring') ...[
                    const Divider(),
                    SizedBox(height: 2.h),
                    Text(
                      'Job Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    if (post['company'] != null)
                      _buildInfoRow(Icons.business, 'Company', post['company']),
                    if (post['location'] != null)
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        post['location'],
                      ),
                    if (post['salary'] != null)
                      _buildInfoRow(
                        Icons.currency_rupee,
                        'Salary',
                        post['salary'],
                      ),
                    SizedBox(height: 2.h),
                  ],

                  if (postType == 'investment') ...[
                    const Divider(),
                    SizedBox(height: 2.h),
                    Text(
                      'Investment Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    if (post['investment_amount'] != null)
                      _buildInfoRow(
                        Icons.currency_rupee,
                        'Amount',
                        post['investment_amount'],
                      ),
                    if (post['returns'] != null)
                      _buildInfoRow(
                        Icons.trending_up,
                        'Returns',
                        post['returns'],
                      ),
                    SizedBox(height: 2.h),
                  ],
                ],
              ),
            ),
          ),

          // Comments Section
          SliverToBoxAdapter(
            child: _buildCommentsSection(context, commentsController),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: 4.h)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          SizedBox(width: 2.w),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getPostTypeIcon(String? postType) {
    switch (postType) {
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

  Color _getPostTypeColor(String? postType) {
    switch (postType) {
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

  Widget _buildAuthorHeader(BuildContext context, Map<String, dynamic> post) {
    final storage = Get.find<StorageService>();
    final currentUser = storage.user;
    final isOwnPost =
        currentUser != null &&
        post['author'] != null &&
        (post['author']['id'] == currentUser['id'] ||
            post['user']?['id'] == currentUser['uuid']);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              (post['author']['full_name'] ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${post['author']['full_name'] ?? ''} ${post['author']['surname'] ?? ''}'
                      .trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
                if (post['author']['email'] != null)
                  Text(
                    post['author']['email'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                  ),
              ],
            ),
          ),
          // Message Button - only show if NOT own post
          if (!isOwnPost && post['author']['id'] != null)
            IconButton(
              onPressed: () {
                final chatController = Get.put(ChatController());
                chatController.startConversation(post['author']['id']);
              },
              icon: Icon(
                Icons.message_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }

  String _getPostTypeLabel(String? postType) {
    switch (postType) {
      case 'job_seeking':
        return 'Job Seeking';
      case 'investment':
        return 'Investment Opportunity';
      case 'hiring':
        return 'Hiring';
      case 'ad':
        return 'Featured Ad';
      default:
        return 'Post';
    }
  }

  Widget _buildCommentsSection(
    BuildContext context,
    CommentsController controller,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          SizedBox(height: 1.h),
          Text(
            'Comments',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),

          // Comment List
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.comments.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  'No comments yet. Be the first to comment!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.comments.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final comment = controller.comments[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to commenter's profile
                        final commenterId = comment['user_id'];
                        Get.toNamed(
                          Routes.FULL_PROFILE,
                          arguments: {'userId': commenterId},
                        );
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: comment['user_photo'] != null
                            ? NetworkImage(
                                ApiConstants.getFullUrl(comment['user_photo']),
                              )
                            : null,
                        child: comment['user_photo'] == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to commenter's profile
                                    final commenterId = comment['user_id'];
                                    Get.toNamed(
                                      Routes.FULL_PROFILE,
                                      arguments: {'userId': commenterId},
                                    );
                                  },
                                  child: Text(
                                    comment['user_name'] ?? 'User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  comment['content'] ?? '',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          // Action buttons (Edit/Delete)
                          Row(
                            children: [
                              Text(
                                _formatCommentTime(comment['created_at']),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              // Check if user owns comment or is admin
                              if (_canModifyComment(comment)) ...[
                                SizedBox(width: 2.w),
                                InkWell(
                                  onTap: () => _showEditCommentDialog(
                                    context,
                                    controller,
                                    comment,
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              if (_canDeleteComment(comment)) ...[
                                SizedBox(width: 2.w),
                                InkWell(
                                  onTap: () => _confirmDeleteComment(
                                    context,
                                    controller,
                                    comment,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatDate(comment['created_at']),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }),

          SizedBox(height: 2.h),

          // Add Comment Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Obx(
                () => IconButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () => controller.addComment(),
                  icon: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h), // Safe area bottom
        ],
      ),
    );
  }

  String _formatCommentTime(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  bool _canModifyComment(Map<String, dynamic> comment) {
    final storage = Get.find<StorageService>();
    final currentUser = storage.user;
    if (currentUser == null) return false;

    // User can edit their own comments
    final commentUserId = comment['user_id'];
    final currentUserId = currentUser['id'];
    return commentUserId == currentUserId;
  }

  bool _canDeleteComment(Map<String, dynamic> comment) {
    final storage = Get.find<StorageService>();
    final currentUser = storage.user;
    if (currentUser == null) return false;

    // User can delete their own comments OR admin can delete any comment
    final commentUserId = comment['user_id'];
    final currentUserId = currentUser['id'];
    final userRole = currentUser['role'];

    return commentUserId == currentUserId ||
        userRole == 'super_admin' ||
        userRole == 'admin';
  }

  void _showEditCommentDialog(
    BuildContext context,
    CommentsController controller,
    Map<String, dynamic> comment,
  ) {
    final editController = TextEditingController(text: comment['content']);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty) {
                final commentId = comment['uuid'] ?? comment['id'].toString();
                controller.updateComment(commentId, newContent);
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(
    BuildContext context,
    CommentsController controller,
    Map<String, dynamic> comment,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final commentId = comment['uuid'] ?? comment['id'].toString();
              controller.deleteComment(commentId);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
