import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put instead of lazyPut to ensure controller is created immediately
    Get.put<SplashController>(SplashController());
  }
}
