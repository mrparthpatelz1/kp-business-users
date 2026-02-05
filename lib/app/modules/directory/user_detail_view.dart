import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/user_profile_content.dart';
import 'directory_controller.dart';

class UserDetailView extends StatefulWidget {
  final String userId;

  const UserDetailView({super.key, required this.userId});

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  final DirectoryController controller = Get.find<DirectoryController>();
  Map<String, dynamic>? user;
  bool isLoading = true;

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
              child: UserProfileContent(user: user!),
            ),
    );
  }
}
