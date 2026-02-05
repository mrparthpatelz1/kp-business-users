import 'package:get/get.dart';
import 'pending_approval_controller.dart';

class PendingApprovalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PendingApprovalController());
  }
}
