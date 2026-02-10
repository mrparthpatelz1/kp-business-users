import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../data/services/auth_service.dart';
import '../directory/directory_controller.dart';
import '../directory/directory_view.dart';
import '../announcements/announcements_controller.dart';
import '../announcements/announcements_view.dart';
import '../chat/chat_controller.dart';
import '../posts/posts_controller.dart';
import '../posts/posts_view.dart';
import '../posts/post_card_widget.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_view.dart';
import '../../routes/app_routes.dart';
import 'post_detail_view.dart';

class MainController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final MainController controller = Get.put(MainController());
  final AuthService authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    // Initialize all controllers
    Get.put(DirectoryController());
    Get.put(AnnouncementsController());
    Get.put(PostsController());
    Get.put(ProfileController());
  }

  Future<void> _showExitDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.exit_to_app,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Exit App'),
          ],
        ),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (result == true) {
      SystemNavigator.pop();
    }
  }

  // Reordered: Home, Posts, Directory, Profile (removed Announcements from navbar)
  final List<Widget> _pages = [
    const _HomeTab(),
    const PostsView(),
    const DirectoryView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (controller.selectedIndex.value != 0) {
          controller.changeTab(0);
        } else {
          await _showExitDialog();
        }
      },
      child: Obx(
        () => Scaffold(
          body: SafeArea(child: _pages[controller.selectedIndex.value]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: controller.changeTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: 'Posts',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Directory',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final postsController = Get.find<PostsController>();
    final announcementsController = Get.find<AnnouncementsController>();
    final chatController = Get.put(ChatController());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.business, color: AppTheme.primaryColor),
            SizedBox(width: 2.w),
            const Text('KP Business'),
          ],
        ),
        actions: [
          // Notification icon for Announcements with badge
          Obx(() {
            final count = announcementsController.unreadCount.value;
            return IconButton(
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
              tooltip: 'Announcements',
              onPressed: () {
                announcementsController.markAllAsSeen();
                Get.to(() => const AnnouncementsView());
              },
            );
          }),
          // Inbox Icon with badge
          Obx(() {
            final count = chatController.totalUnreadCount.value;
            return IconButton(
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              tooltip: 'Messages',
              onPressed: () => Get.toNamed(Routes.CHAT_LIST),
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await postsController.loadHomeScreenPosts(refresh: true);
          await postsController.loadPosts(refresh: true);
          await postsController.loadAds();
          await announcementsController.loadAnnouncements();
          await chatController.loadUnreadCount();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
              // Load more when near bottom
              postsController.loadHomeScreenPosts(loadMore: true);
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Obx(() {
                  final user = authService.currentUser.value;
                  return Card(
                    color: AppTheme.primaryColor,
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: user?['profile_picture'] != null
                                ? NetworkImage(
                                    ApiConstants.getFullUrl(
                                      user!['profile_picture'],
                                    ),
                                  )
                                : null,
                            child: user?['profile_picture'] == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30,
                                  )
                                : null,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14.sp,
                                  ),
                                ),
                                Text(
                                  user?['full_name'] ?? 'User',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 3.h),

                // Ads Slider - Horizontal carousel for ads
                _buildAdsSlider(context, postsController),

                SizedBox(height: 3.h),

                // Recent Posts - Uses same UI as PostsView
                Text(
                  'Recent Posts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Obx(() {
                  // Get exactly 2 most recent non-ad posts from decoupled home data
                  final recentPosts = postsController.recentPosts;

                  if (recentPosts.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Center(
                          child: Text(
                            'No posts yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: recentPosts
                        .map((p) => PostCard(post: p, compact: true))
                        .toList(),
                  );
                }),
                SizedBox(height: 2.h),

                // View All Posts Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.find<MainController>().changeTab(1),
                    child: const Text('View All Posts'),
                  ),
                ),
                SizedBox(height: 2.h),
                // Loading Indicator
                Obx(() {
                  if (postsController.isLoadingHomeScreen.value &&
                      postsController.homeScreenPage.value > 1) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const SizedBox.shrink();
                }),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdsSlider(
    BuildContext context,
    PostsController postsController,
  ) {
    return Obx(() {
      // Fixed: Use post_type == 'ad' instead of category == 'ads'
      final ads = postsController.ads;

      if (ads.isEmpty) {
        return const SizedBox.shrink();
      }

      // Page controller for auto-scroll
      final pageController = PageController(viewportFraction: 0.95);
      final currentPage = 0.obs;

      // Auto-scroll timer
      Future.delayed(const Duration(seconds: 3), () {
        if (pageController.hasClients && ads.isNotEmpty) {
          Timer.periodic(const Duration(seconds: 3), (timer) {
            if (!pageController.hasClients) {
              timer.cancel();
              return;
            }
            final nextPage = (currentPage.value + 1) % ads.length;
            pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            currentPage.value = nextPage;
          });
        }
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Ads',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 25.h, // Increased from 15.h to 25.h
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) => currentPage.value = index,
              itemCount: ads.length,
              itemBuilder: (context, index) {
                final ad = ads[index];
                return _buildAdCard(context, ad);
              },
            ),
          ),
          SizedBox(height: 1.h),
          // Page indicators
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                ads.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: currentPage.value == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentPage.value == index
                        ? AppTheme.primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAdCard(BuildContext context, Map<String, dynamic> ad) {
    // Get the base URL for images
    // final baseUrl = 'http://192.168.1.43:3000'; // Same as ApiConstants.baseUrl without /api/v1

    return Container(
      width: 95.w, // Full width with small margin (changed from 70.w)
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      child: InkWell(
        onTap: () => Get.to(() => PostDetailView(post: ad)),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: ad['image_url'] != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      ad['image_url'].startsWith('http')
                          ? ad['image_url']
                          : '${ApiConstants.assetBaseUrl}${ad['image_url']}', // Prepend base URL if relative
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAdContent(ad),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Text(
                          ad['title'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                )
              : _buildAdContent(ad),
        ),
      ),
    );
  }

  Widget _buildAdContent(Map<String, dynamic> ad) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.1),
          ],
        ),
      ),
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: AppTheme.primaryColor, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  ad['title'] ?? 'Ad',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            ad['description'] ?? '',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreviewCard(
    BuildContext context,
    Map<String, dynamic> post,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getPostTypeColor(post['post_type']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPostTypeIcon(post['post_type']),
                color: _getPostTypeColor(post['post_type']),
                size: 18.sp,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    post['description'] ?? '',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPostTypeColor(post['post_type']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getPostTypeLabel(post['post_type']),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: _getPostTypeColor(post['post_type']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  String _getPostTypeLabel(String? postType) {
    switch (postType) {
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
