import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/auth/login/login_binding.dart';
import '../modules/auth/login/login_view.dart';
import '../modules/auth/register/register_binding.dart';
import '../modules/auth/register/register_view.dart';
import '../modules/main/main_view.dart';
import '../modules/main/main_binding.dart';
import '../modules/pending_approval/pending_approval_view.dart';
import '../modules/profile/edit_profile_view.dart';
import '../modules/profile/edit_profile_binding.dart';
import '../modules/profile/full_profile_view.dart';
import '../modules/profile/other_user_profile_view.dart';
import '../modules/profile/other_user_profile_controller.dart';
import '../modules/posts/create_post_view.dart';
import '../modules/chat/chat_list_view.dart';
import '../modules/chat/chat_detail_view.dart';
import '../modules/main/post_detail_view.dart';
import '../modules/auth/forgot_password/forgot_password_view.dart';
import '../modules/announcements/announcements_view.dart';
import '../modules/announcements/announcements_binding.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const MainView(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.PENDING_APPROVAL,
      page: () => const PendingApprovalView(),
    ),
    GetPage(
      name: Routes.EDIT_PROFILE,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(name: Routes.FULL_PROFILE, page: () => const FullProfileView()),
    GetPage(
      name: Routes.OTHER_USER_PROFILE,
      page: () => const OtherUserProfileView(),
      binding: BindingsBuilder(() {
        Get.put(OtherUserProfileController());
      }),
    ),
    GetPage(name: Routes.CREATE_POST, page: () => const CreatePostView()),
    GetPage(name: Routes.CHAT_LIST, page: () => const ChatListView()),
    GetPage(name: Routes.CHAT_DETAIL, page: () => const ChatDetailView()),
    GetPage(
      name: Routes.POST_DETAIL,
      page: () => PostDetailView(post: Get.arguments),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
    ),
    GetPage(
      name: Routes.ANNOUNCEMENTS,
      page: () => const AnnouncementsView(),
      binding: AnnouncementsBinding(),
    ),
  ];
}
