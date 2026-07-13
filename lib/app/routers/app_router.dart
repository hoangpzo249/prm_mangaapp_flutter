import 'package:flutter/material.dart';

import '../../features/presentation/view/screens/auth/login_screen.dart';
import '../../features/presentation/view/screens/auth/register_screen.dart';
import '../../features/presentation/view/screens/bookmarks/bookmarks_screen.dart';
import '../../features/presentation/view/screens/chapter/chapter_reader_screen.dart';
import '../../features/presentation/view/screens/main_tabs.dart';
import '../../features/presentation/view/screens/payment/payment_screen.dart';
import '../../features/presentation/view/screens/profile/profile_screen.dart';
import '../../features/presentation/view/screens/profile/edit_profile_screen.dart';
import '../../features/presentation/view/screens/profile/change_password_screen.dart';
import '../../features/presentation/view/screens/auth/forgot_password_screen.dart';
import '../../features/presentation/view/screens/story/story_detail_screen.dart';

/// Central route table.
///   /               -> tabs (Home/Explore/History)
///   /login /register /profile /payment /bookmarks
///   /story/:id      -> StoryDetailScreen
///   /chapter/:id    -> ChapterReaderScreen
class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const profile = '/profile';
  static const payment = '/payment';
  static const bookmarks = '/bookmarks';
  static const story = '/story';
  static const chapter = '/chapter';
  static const forgotPassword = '/forgotPassword';
  static const editProfile = '/editProfile';
  static const changePassword = '/changePassword';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final segments = uri.pathSegments;

    if (segments.length == 2 && segments.first == 'story') {
      return _fade(StoryDetailScreen(storyId: segments[1]), settings);
    }
    if (segments.length == 2 && segments.first == 'chapter') {
      return _fade(ChapterReaderScreen(chapterId: segments[1]), settings);
    }

    switch (uri.path) {
      case AppRoutes.home:
        final args = settings.arguments as Map<String, dynamic>?;
        return _fade(
          MainTabs(
            initialIndex: args?['tab'] as int? ?? 0,
            exploreSort: args?['sort'] as String?,
          ),
          settings,
        );
      case AppRoutes.login:
        return _fade(const LoginScreen(), settings);
      case AppRoutes.register:
        return _fade(const RegisterScreen(), settings);
      case AppRoutes.profile:
        return _fade(const ProfileScreen(), settings);
      case AppRoutes.payment:
        return _fade(const PaymentScreen(), settings);
      case AppRoutes.bookmarks:
        return _fade(const BookmarksScreen(), settings);
      case AppRoutes.forgotPassword:
        return _fade(const ForgotPasswordScreen(), settings);
      case AppRoutes.editProfile:
        return _fade(const EditProfileScreen(), settings);
      case AppRoutes.changePassword:
        return _fade(const ChangePasswordScreen(), settings);
      default:
        return _fade(const MainTabs(), settings);
    }
  }

  static PageRoute _fade(Widget child, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }
}