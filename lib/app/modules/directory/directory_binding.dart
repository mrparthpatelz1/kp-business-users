import 'package:get/get.dart';
import '../../data/services/master_service.dart';
import 'directory_controller.dart';

class DirectoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterService>(() => MasterService());
    Get.lazyPut<DirectoryController>(() => DirectoryController());
  }
}
