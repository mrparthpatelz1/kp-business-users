import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/api_provider.dart';

class PostsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ApiProvider _api = Get.find<ApiProvider>();

  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> posts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> homeScreenPosts =
      <Map<String, dynamic>>[].obs; // Separate list for home screen
  final RxList<Map<String, dynamic>> myPosts = <Map<String, dynamic>>[].obs;

  // Home Screen Pagination
  final RxInt homeScreenPage = 1.obs;
  final RxBool isLoadingHomeScreen = false.obs;
  final RxBool hasMoreHomeScreen = true.obs;

  final RxString selectedType = 'all'.obs; // Default to 'all'
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  // Filter options for viewing posts (includes 'All')
  final List<Map<String, String>> postTypes = [
    {'key': 'all', 'label': 'All'},
    {'key': 'job_seeking', 'label': 'Job Seeking'},
    {'key': 'investment', 'label': 'Investment Opportunity'},
    {'key': 'hiring', 'label': 'Hiring'},
    {'key': 'ad', 'label': 'Ads'},
  ];

  // Post types for creating posts (excludes 'All' - users must select specific type)
  final List<Map<String, String>> creatablePostTypes = [
    {'key': 'job_seeking', 'label': 'Job Seeking'},
    {'key': 'investment', 'label': 'Investment Opportunity'},
    {'key': 'hiring', 'label': 'Hiring'},
    {'key': 'ad', 'label': 'Ads'},
  ];

  final RxList<Map<String, dynamic>> adsList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHomeScreenPosts(); // Load home screen data separately
    loadPosts();
    loadAds();
  }

  /// Load posts specifically for home screen - ALWAYS loads "all" posts
  /// This is decoupled from the Post page filter
  Future<void> loadHomeScreenPosts({
    bool refresh = false,
    bool loadMore = false,
  }) async {
    if (isLoadingHomeScreen.value) return;

    if (refresh) {
      homeScreenPage.value = 1;
      hasMoreHomeScreen.value = true;
    }

    if (loadMore && !hasMoreHomeScreen.value) return;

    isLoadingHomeScreen.value = true;
    try {
      final response = await _api.get(
        ApiConstants.posts,
        queryParams: {
          'page': homeScreenPage.value,
          'per_page': 10,
          'include_comments': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<Map<String, dynamic>> newPosts = data
            .cast<Map<String, dynamic>>();

        if (refresh) {
          homeScreenPosts.value = newPosts; // Replace list
        } else {
          homeScreenPosts.addAll(newPosts); // Append list
        }

        if (newPosts.length < 10) {
          hasMoreHomeScreen.value = false;
        } else {
          homeScreenPage.value++;
        }
      }
    } catch (e) {
      debugPrint('Error loading home screen posts: $e');
    } finally {
      isLoadingHomeScreen.value = false;
    }
  }

  Future<void> loadAds() async {
    try {
      final response = await _api.get(
        ApiConstants.posts,
        queryParams: {'type': 'ad', 'page': 1, 'per_page': 10},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        adsList.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading ads: $e');
    }
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      posts.clear();
    }

    isLoading.value = true;
    try {
      final queryParams = <String, dynamic>{
        'page': currentPage.value,
        'per_page': 20,
      };

      // Only add type filter if not 'all'
      if (selectedType.value != 'all') {
        queryParams['type'] = selectedType.value;
      }

      final response = await _api.get(
        ApiConstants.posts,
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        List<Map<String, dynamic>> postsData = data
            .cast<Map<String, dynamic>>();

        if (refresh) {
          posts.value = postsData;
        } else {
          posts.addAll(postsData);
        }
        totalPages.value = response.data['pagination']?['total_pages'] ?? 1;
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
    isLoading.value = false;
  }

  // Get ads for slider - uses separate ads list
  List<Map<String, dynamic>> get ads => adsList;

  // Get recent posts (non-ads) for home screen - uses home screen posts (decoupled)
  // Filtering out ads from recent posts to avoid duplication if they appear there
  List<Map<String, dynamic>> get recentPosts =>
      homeScreenPosts.where((p) => p['post_type'] != 'ad').toList();

  void changePostType(String type) {
    selectedType.value = type;
    loadPosts(refresh: true);
  }

  Future<void> loadMyPosts() async {
    try {
      final response = await _api.get(ApiConstants.myPosts);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        myPosts.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading my posts: $e');
    }
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    try {
      debugPrint('Creating post with data: $data');
      final response = await _api.post(ApiConstants.posts, data: data);
      debugPrint(
        'Create post response: ${response.statusCode} - ${response.data}',
      );
      if (response.statusCode == 201) {
        loadMyPosts();
        loadPosts(refresh: true);
        loadHomeScreenPosts(refresh: true); // Refresh home screen too
        return {'success': true, 'message': 'Post created successfully'};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to create post',
      };
    } on DioException catch (e) {
      debugPrint('Error creating post: $e');
      // Extract error message from response if available
      String errorMessage = 'Failed to create post';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      debugPrint('Error creating post: $e');
      return {'success': false, 'message': 'Failed to create post'};
    }
  }

  Future<Map<String, dynamic>> createPostWithImage(
    Map<String, dynamic> data,
    String? imagePath,
  ) async {
    try {
      debugPrint('Creating post with image. Data: $data, Image: $imagePath');
      if (imagePath != null && data['post_type'] == 'ad') {
        // Upload with image for ads
        final response = await _api.uploadFile(
          ApiConstants.posts,
          imagePath,
          data: data,
        );
        debugPrint(
          'Upload response: ${response.statusCode} - ${response.data}',
        );
        if (response.statusCode == 201) {
          loadMyPosts();
          loadPosts(refresh: true);
          loadHomeScreenPosts(refresh: true);
          return {'success': true, 'message': 'Ad created successfully'};
        }
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to create ad',
        };
      } else {
        return createPost(data);
      }
    } on DioException catch (e) {
      debugPrint('Error creating post with image: $e');
      // Extract error message from response if available
      String errorMessage = 'Failed to create post';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      debugPrint('Error creating post with image: $e');
      return {'success': false, 'message': 'Failed to create post: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePost(
    String postId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.put(
        '${ApiConstants.posts}/$postId',
        data: data,
      );
      if (response.statusCode == 200) {
        loadMyPosts();
        return {'success': true, 'message': 'Post updated successfully'};
      }
      return {'success': false, 'message': 'Failed to update post'};
    } catch (e) {
      debugPrint('Error updating post: $e');
      return {'success': false, 'message': 'Failed to update post'};
    }
  }

  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final response = await _api.delete('${ApiConstants.posts}/$postId');
      if (response.statusCode == 200) {
        myPosts.removeWhere((p) => p['id'] == postId);
        return {'success': true, 'message': 'Post deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete post'};
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return {'success': false, 'message': 'Failed to delete post'};
    }
  }
}
