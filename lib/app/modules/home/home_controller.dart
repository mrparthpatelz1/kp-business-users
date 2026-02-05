import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../data/services/auth_service.dart';

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  Map<String, dynamic>? get user => _authService.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _authService.getProfile();
  }

  Future<void> logout() async {
    await _authService.logout();
    Get.offAllNamed(Routes.LOGIN);
  }
}
