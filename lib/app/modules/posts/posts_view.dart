import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import 'posts_controller.dart';
import 'create_post_view.dart';
import '../main/post_detail_view.dart';

class PostsView extends GetView<PostsController> {
  const PostsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: Column(
        children: [
          // Post Type Tabs
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.postTypes.length,
              itemBuilder: (context, index) {
                final type = controller.postTypes[index];
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: Obx(() {
                    final isSelected =
                        controller.selectedType.value == type['key'];
                    return ChoiceChip(
                      label: Text(type['label']!),
                      selected: isSelected,
                      onSelected: (_) =>
                          controller.changePostType(type['key']!),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // Posts List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.posts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getEmptyIcon(), size: 60.sp, color: Colors.grey),
                      SizedBox(height: 2.h),
                      Text(
                        'No posts found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Be the first to post!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadPosts(refresh: true),
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: controller.posts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(context, controller.posts[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreatePostView()),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Post', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (controller.selectedType.value) {
      case 'job_seeking':
        return Icons.work_outline;
      case 'investment':
        return Icons.trending_up;
      case 'hiring':
        return Icons.person_add;
      case 'ad':
        return Icons.campaign_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post) {
    final postType = post['post_type']?.toString() ?? '';
    final user = post['user'] as Map<String, dynamic>?;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _showPostDetail(context, post),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getPostTypeColor(
                      postType,
                    ).withOpacity(0.1),
                    backgroundImage: user?['profile_photo'] != null
                        ? NetworkImage(
                            (user!['profile_photo'] as String).startsWith(
                                  'http',
                                )
                                ? user!['profile_photo']
                                : '${ApiConstants.assetBaseUrl}${user!['profile_photo']}',
                          )
                        : null,
                    child: user?['profile_photo'] == null
                        ? Icon(
                            _getPostTypeIcon(postType),
                            color: _getPostTypeColor(postType),
                            size: 18,
                          )
                        : null,
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
                        ),
                        Text(
                          _formatDate(post['created_at']),
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
                      color: _getPostTypeColor(postType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPostTypeLabel(postType),
                      style: TextStyle(
                        color: _getPostTypeColor(postType),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Title
              Text(
                post['title'] ?? '',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),

              // Description
              Text(
                post['description'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Additional Info
              SizedBox(height: 1.5.h),
              Wrap(
                spacing: 3.w,
                runSpacing: 1.h,
                children: [
                  if (post['location'] != null)
                    _buildInfoChip(Icons.location_on, post['location']),
                  if (post['salary_range'] != null)
                    _buildInfoChip(Icons.currency_rupee, post['salary_range']),
                  if (post['investment_amount'] != null)
                    _buildInfoChip(
                      Icons.monetization_on,
                      post['investment_amount'],
                    ),
                  if (post['category'] != null)
                    _buildInfoChip(Icons.category, post['category']),
                ],
              ),
            ],
          ),
        ),
      ),
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

  Color _getPostTypeColor(String type) {
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

  IconData _getPostTypeIcon(String type) {
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

  String _getPostTypeLabel(String type) {
    switch (type) {
      case 'job_seeking':
        return 'JOB SEEKING';
      case 'investment':
        return 'INVESTMENT OPPORTUNITY';
      case 'hiring':
        return 'HIRING';
      case 'ad':
        return 'AD';
      default:
        return type.toUpperCase();
    }
  }

  void _showPostDetail(BuildContext context, Map<String, dynamic> post) {
    Get.to(() => PostDetailView(post: post));
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return dateString;
    }
  }
}
