import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'pending_approval_controller.dart';

class PendingApprovalView extends StatelessWidget {
  const PendingApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PendingApprovalController());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 4.h),
              // Success icon
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty_rounded,
                  size: 40.sp,
                  color: AppTheme.warningColor,
                ),
              ),
              SizedBox(height: 4.h),

              Text(
                'Registration Submitted!',
                style: GoogleFonts.sora(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),

              Text(
                'Your account is pending approval from the village admin. You will be notified once your account is approved.',
                style: GoogleFonts.sora(
                  fontSize: 15.sp,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),

              // Info card
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'This usually takes 1-2 business days. Contact your village admin for faster approval.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),

              // Village Admins Section
              Obx(() {
                if (controller.isLoading.value) {
                  return const CircularProgressIndicator();
                }

                if (controller.villageAdmins.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.contact_phone,
                            color: AppTheme.primaryColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Contact Village Admin',
                            style: GoogleFonts.sora(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),

                      ...controller.villageAdmins.map((admin) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 3.h),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryColor
                                    .withOpacity(0.1),
                                radius: 24,
                                child: Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      admin['name'] ?? 'Admin',
                                      style: GoogleFonts.sora(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (admin['phone'] != null) ...[
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        admin['phone'],
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (admin['phone'] != null)
                                IconButton(
                                  onPressed: () =>
                                      _makePhoneCall(admin['phone']),
                                  icon: Icon(
                                    Icons.phone,
                                    color: AppTheme.successColor,
                                    size: 24,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.successColor
                                        .withOpacity(0.1),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }),

              SizedBox(height: 4.h),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.offAllNamed(Routes.LOGIN),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not make phone call',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
