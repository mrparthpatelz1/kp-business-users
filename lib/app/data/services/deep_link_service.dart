import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_links/app_links.dart';
import '../../routes/app_routes.dart';
import '../../core/constants/api_constants.dart';
import '../../data/services/auth_service.dart';
import '../../data/providers/api_provider.dart';

class DeepLinkService extends GetxService {
  late AppLinks _appLinks;
  final AuthService _authService = Get.find<AuthService>();
  final ApiProvider _api = Get.find<ApiProvider>();

  @override
  void onInit() {
    super.onInit();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final Uri? uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen to incoming links
    _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep Link Error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');

    // Scheme: kpbusiness://post?id=123
    if (uri.scheme == 'kpbusiness' && uri.host == 'post') {
      final String? postId = uri.queryParameters['id'];
      if (postId != null) {
        _navigateToPost(postId);
      }
    }
  }

  Future<void> _navigateToPost(String postId) async {
    // Wait for auth to be ready if needed
    // Assuming authService is initialized.

    if (!_authService.isLoggedIn.value) {
      // If not logged in, maybe direct to login?
      // For now, let's just let user login usually.
      // Or we can show snackbar "Please login to view post"
      Get.snackbar('Login Required', 'Please login to view this post');
      return;
    }

    // Fetch Post Details
    try {
      // We need a way to fetch single post.
      // ApiProvider generic get.

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await _api.get('${ApiConstants.posts}/$postId');
      Get.back(); // Close loading

      if (response.statusCode == 200) {
        final post = response.data['data'];
        // Navigate to Detail View
        // We need to import PostDetailView.
        // Better to use Named Route if possible, but PostDetailView expects object arg usually.
        // Let's use Get.to(() => PostDetailView(post: post));
        // But we need to import it.
        // Since this service is in core/data, importing module view might vary.
        // Ideally use Get.toNamed with arguments if route supports it.
        // Our routes don't define post detail with ID params yet.
        // We can add a route '/post-detail' that reads args?
        // Existing Routes.CREATE_POST etc.
        // Let's try dynamic import or use GET.toNamed if we updated AppPages.
        // For now, let's cheat and use a dedicated route handler or callback.
        // Or just import it.

        // Actually, best practice:
        // Define Route '/post/:id' and middleware fetches it?
        // Or Route '/post-detail' takes 'post' object in arguments.
        Get.toNamed(Routes.POST_DETAIL, arguments: post);
        // Wait, we don't have that route.

        // Let's implement fetch and navigate inside MainController or specific controller?
        // Or just import the view here.
      } else {
        Get.snackbar('Error', 'Post not found');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint('Nav Error: $e');
      Get.snackbar('Error', 'Could not load post');
    }
  }
}
