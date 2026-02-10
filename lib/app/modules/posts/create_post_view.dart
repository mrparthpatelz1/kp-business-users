import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import 'posts_controller.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final PostsController controller = Get.find<PostsController>();
  final AuthService authService = Get.find<AuthService>();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _salaryController = TextEditingController();
  final _investmentController = TextEditingController();
  final _experienceController = TextEditingController();

  String _selectedType = 'job_seeking';
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isEditing = false;
  String? _editingPostId;

  @override
  void initState() {
    super.initState();
    // Check if we are editing
    if (Get.arguments != null && Get.arguments['post'] != null) {
      final post = Get.arguments['post'];
      _isEditing = true;
      _editingPostId = post['id'].toString();
      _selectedType = post['post_type'];
      _titleController.text = post['title'] ?? '';
      _descriptionController.text = post['description'] ?? '';
      _categoryController.text = post['category'] ?? '';
      _locationController.text = post['location'] ?? '';
      _contactController.text = post['contact_info'] ?? '';
      _salaryController.text = post['salary_range'] ?? '';
      _investmentController.text = post['investment_amount']?.toString() ?? '';
      _experienceController.text = post['experience_required'] ?? '';
    } else {
      // Set default contact info from user profile only if creating new
      final user = authService.currentUser.value;
      if (user != null) {
        _contactController.text = user['phone'] ?? user['email'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _salaryController.dispose();
    _investmentController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Post' : 'Create Post')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Type Selection - Disabled if editing
                Text(
                  'Post Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  children: controller.creatablePostTypes.map((type) {
                    final isSelected = _selectedType == type['key'];
                    return ChoiceChip(
                      label: Text(type['label']!),
                      selected: isSelected,
                      onSelected: _isEditing
                          ? null
                          : (_) {
                              setState(() {
                                _selectedType = type['key']!;
                                if (_selectedType != 'ad') {
                                  _selectedImage = null;
                                }
                              });
                            },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      // Visual cue for disabled state
                      disabledColor: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.7)
                          : null,
                    );
                  }).toList(),
                ),
                SizedBox(height: 3.h),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Title is required' : null,
                ),
                SizedBox(height: 2.h),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Description is required' : null,
                ),
                SizedBox(height: 2.h),

                // Image Upload - Only for Ads
                if (_selectedType == 'ad') ...[
                  Text(
                    'Ad Image',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  // Show existing image if editing and no new image selected?
                  // The current API doesn't seem to return the image URL easily in the post object for display here without handling,
                  // but usually it's in 'media_url' or similar.
                  // For simplicity, we just allow uploading a NEW image to replace.
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 20.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: _removeImage,
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 15.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              _isEditing
                                  ? 'Tap to replace image (optional)'
                                  : 'Tap to add image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 2.h),
                ],

                // Category
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category / Industry',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                SizedBox(height: 2.h),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 2.h),

                // Contact Info
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Info',
                    prefixIcon: Icon(Icons.contact_phone),
                  ),
                ),
                SizedBox(height: 2.h),

                // Conditional Fields
                if (_selectedType == 'job_seeking' ||
                    _selectedType == 'hiring') ...[
                  TextFormField(
                    controller: _salaryController,
                    decoration: const InputDecoration(
                      labelText: 'Salary Range (Expected/Offered)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],

                if (_selectedType == 'hiring') ...[
                  TextFormField(
                    controller: _experienceController,
                    decoration: const InputDecoration(
                      labelText: 'Experience Required',
                      prefixIcon: Icon(Icons.work_history),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],

                if (_selectedType == 'investment') ...[
                  TextFormField(
                    controller: _investmentController,
                    decoration: const InputDecoration(
                      labelText: 'Investment Amount Needed',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],

                SizedBox(height: 2.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing
                                ? 'Update Post'
                                : (_selectedType == 'ad'
                                      ? 'Create Ad'
                                      : 'Create Post'),
                          ),
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final postData = {
      'post_type': _selectedType,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : null,
      'location': _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      'contact_info': _contactController.text.trim().isNotEmpty
          ? _contactController.text.trim()
          : null,
      'salary_range': _salaryController.text.trim().isNotEmpty
          ? _salaryController.text.trim()
          : null,
      'investment_amount': _investmentController.text.trim().isNotEmpty
          ? _investmentController.text.trim()
          : null,
      'experience_required': _experienceController.text.trim().isNotEmpty
          ? _experienceController.text.trim()
          : null,
    };

    Map<String, dynamic> result;

    if (_isEditing) {
      // Note: Currently updatePost in controller doesn't support image update separately,
      // but typically APIs handle it. We'll just call updatePost for now.
      // If image support is needed for update, we'd need a similar `updatePostWithImage`.
      // For now, let's assume basic update.
      result = await controller.updatePost(_editingPostId!, postData);
    } else {
      if (_selectedType == 'ad' && _selectedImage != null) {
        result = await controller.createPostWithImage(
          postData,
          _selectedImage!.path,
        );
      } else {
        result = await controller.createPost(postData);
      }
    }

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Get.back();
      Get.snackbar(
        'Success',
        result['message'],
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'],
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
