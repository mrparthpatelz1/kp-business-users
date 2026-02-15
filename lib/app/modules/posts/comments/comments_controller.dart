import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/providers/api_provider.dart';

class CommentsController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();
  final String postId;

  CommentsController(this.postId);

  final RxList<Map<String, dynamic>> comments = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final TextEditingController commentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadComments();
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> loadComments() async {
    isLoading.value = true;
    try {
      final response = await _api.get('${ApiConstants.posts}/$postId/comments');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        comments.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
    }
    isLoading.value = false;
  }

  Future<void> addComment() async {
    final content = commentController.text.trim();
    if (content.isEmpty) return;

    isSubmitting.value = true;
    try {
      final response = await _api.post(
        '${ApiConstants.posts}/$postId/comments',
        data: {'content': content},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newComment = response.data['data'];
        // Prepend comment to list
        comments.add(newComment);
        commentController.clear();

        // Don't reload - it causes the comment to disappear
        // The optimistic update above is sufficient
      } else {
        Get.snackbar('Error', 'Failed to post comment');
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      Get.snackbar('Error', 'Failed to post comment');
    }
    isSubmitting.value = false;
  }

  Future<void> updateComment(String commentId, String newContent) async {
    try {
      final response = await _api.put(
        '/comments/$commentId',
        data: {'content': newContent},
      );

      if (response.statusCode == 200) {
        // Update local list
        final index = comments.indexWhere(
          (c) => c['id'].toString() == commentId || c['uuid'] == commentId,
        );
        if (index != -1) {
          comments[index] = response.data['data'];
        }
        Get.snackbar('Success', 'Comment updated');
      }
    } catch (e) {
      debugPrint('Error updating comment: $e');
      Get.snackbar('Error', 'Failed to update comment');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final deleteResponse = await _api.delete('/comments/$commentId');

      if (deleteResponse.statusCode == 200) {
        comments.removeWhere(
          (c) => c['id'].toString() == commentId || c['uuid'] == commentId,
        );
        // Assuming ID is returned as int or string
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
    }
  }
}
