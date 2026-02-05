import 'package:get/get.dart';
import '../../data/providers/api_provider.dart';
import '../../data/services/storage_service.dart';

class PendingApprovalController extends GetxController {
  final ApiProvider _api = Get.find();
  final StorageService _storage = Get.find();

  final isLoading = false.obs;
  final villageAdmins = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchVillageAdmins();
  }

  Future<void> fetchVillageAdmins() async {
    try {
      isLoading.value = true;

      // Get current user's village_id from storage
      final userData = _storage.user;
      print('DEBUG: User data: $userData');

      if (userData != null) {
        dynamic villageId = userData['village_id'];

        // Handle case where village_id is inside native_village object
        if (villageId == null && userData['native_village'] != null) {
          villageId = userData['native_village']['id'];
        }

        if (villageId != null) {
          print('DEBUG: Fetching admins for village ID: $villageId');

          final response = await _api.get('/village-admins/$villageId');
          print('DEBUG: API Response: ${response.data}');

          if (response.data['success'] == true) {
            villageAdmins.value = List<Map<String, dynamic>>.from(
              response.data['data'] ?? [],
            );
            print(
              'DEBUG: Village admins loaded: ${villageAdmins.length} admins',
            );
            print('DEBUG: Admin data: $villageAdmins');
          } else {
            print('DEBUG: API returned success = false');
          }
        } else {
          print('DEBUG: No user data or village_id found');
        }
      }
    } catch (e) {
      print('ERROR fetching village admins: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
