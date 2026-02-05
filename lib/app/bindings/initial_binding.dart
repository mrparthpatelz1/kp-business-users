import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/providers/api_provider.dart';
import '../data/services/auth_service.dart';
import '../data/services/storage_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Storage
    Get.put(GetStorage(), permanent: true);
    Get.put(StorageService(), permanent: true);
    
    // API Provider
    Get.put(ApiProvider(), permanent: true);
    
    // Services
    Get.put(AuthService(), permanent: true);
  }
}
