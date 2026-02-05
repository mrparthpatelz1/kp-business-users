import 'package:get/get.dart';
import 'register_controller.dart';
import '../../../data/services/master_service.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterService>(() => MasterService());
    Get.lazyPut<RegisterController>(() => RegisterController());
  }
}
