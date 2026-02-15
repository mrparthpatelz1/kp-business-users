import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import 'posts_controller.dart';
import 'create_post_view.dart';
import 'post_card_widget.dart';
import '../../widgets/shimmer_loading.dart';

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
                return const ShimmerPosts();
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
                    return PostCard(post: controller.posts[index]);
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
}
