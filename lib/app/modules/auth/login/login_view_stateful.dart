import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../routes/app_routes.dart';

/// Stateful login view with manual controller management
/// This eliminates disposal issues by giving us full control over controller lifecycle
class LoginViewStateful extends StatefulWidget {
  const LoginViewStateful({super.key});

  @override
  State<LoginViewStateful> createState() => _LoginViewStatefulState();
}

class _LoginViewStatefulState extends State<LoginViewStateful> {
  // Controllers - managed by this State, not GetX
  late final TextEditingController _loginController;
  late final TextEditingController _passwordController;
  late final GlobalKey<FormState> _formKey;

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Services
  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers once - they persist for the lifetime of this widget
    _loginController = TextEditingController();
    _passwordController = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    // Clean disposal - only called when widget is permanently removed
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        _loginController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        // Only clear on success
        _loginController.clear();
        _passwordController.clear();

        // Upload FCM token
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.uploadTokenToServer();
        } catch (e) {
          debugPrint('Failed to upload FCM token: $e');
        }

        Get.offAllNamed(Routes.HOME);
      } else {
        // On error, keep text fields filled - just show snackbar
        String displayMessage = result['message'] ?? 'Login failed';

        if (result['code'] == 'INVALID_CREDENTIALS') {
          displayMessage = 'Invalid email/phone or password';
        } else if (result['code'] == 'ACCOUNT_PENDING') {
          displayMessage = 'Your account is pending approval';
          if (result['data'] != null && result['data']['user'] != null) {
            Get.find<StorageService>().user = result['data']['user'];
          }
        } else if (result['code'] == 'ACCOUNT_REJECTED') {
          displayMessage = 'Your account has been rejected';
          if (result['data'] != null && result['data']['user'] != null) {
            Get.find<StorageService>().user = result['data']['user'];
          }
        }

        if (mounted) {
          Get.snackbar(
            'Login Failed',
            displayMessage,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error_outline, color: Colors.white),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'An error occurred. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
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
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 6.h),

                  // Logo
                  Center(
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.primaryColor,
                              child: Center(
                                child: Text(
                                  '48 KP',
                                  style: GoogleFonts.sora(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),

                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.sora(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '48 Kadva Patidar Business Summit',
                    style: GoogleFonts.sora(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),

                  // Login field
                  TextFormField(
                    controller: _loginController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email / Phone',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or phone';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 1.h),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Login button
                  SizedBox(
                    height: 7.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => Get.toNamed(Routes.REGISTER),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
