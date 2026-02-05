import 'package:get/get.dart';
import '../../data/services/master_service.dart';
import '../../data/services/deep_link_service.dart';
import '../../data/services/connectivity_service.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize MasterService for DirectoryController
    Get.lazyPut<MasterService>(() => MasterService());
    Get.put(DeepLinkService());
    Get.put(ConnectivityService());
    // Controllers are initialized in MainView
  }
}
