import 'package:flutter/material.dart';

import '../../features/domain/entities/app_user.dart';

import '../../features/presentation/view/screens/admin/admin_dashboard_screen.dart';
import '../../features/presentation/view/screens/admin/admin_user_form_screen.dart';
import '../../features/presentation/view/screens/admin/admin_users_list_screen.dart';

import '../../features/presentation/view/screens/auth/login_screen.dart';
import '../../features/presentation/view/screens/auth/register_screen.dart';
import '../../features/presentation/view/screens/bookmarks/bookmarks_screen.dart';
import '../../features/presentation/view/screens/chapter/chapter_reader_screen.dart';
import '../../features/presentation/view/screens/main_tabs.dart';
import '../../features/presentation/view/screens/notifications/notifications_screen.dart';
import '../../features/presentation/view/screens/payment/payment_screen.dart';
import '../../features/presentation/view/screens/profile/profile_screen.dart';
import '../../features/presentation/view/screens/story/story_detail_screen.dart';

class AppRoutes {
  static const String home = '/';

  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String payment = '/payment';
  static const String bookmarks = '/bookmarks';

  static const String story = '/story';
  static const String chapter = '/chapter';

  static const String adminDashboard = '/admin-dashboard';
  static const String adminUsers = '/admin-users';
  static const String adminUserForm = '/admin-user-form';
  static const String adminReports = '/admin-reports';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Uri uri = Uri.parse(settings.name ?? home);
    final List<String> segments = uri.pathSegments;

    // /story/:id
    if (segments.length == 2 && segments.first == 'story') {
      return _fade(StoryDetailScreen(storyId: segments[1]), settings);
    }

    // /chapter/:id
    if (segments.length == 2 && segments.first == 'chapter') {
      return _fade(ChapterReaderScreen(chapterId: segments[1]), settings);
    }

    switch (uri.path) {
      case home:
        final arguments = settings.arguments;

        int initialIndex = 0;
        String? exploreSort;

        if (arguments is Map<String, dynamic>) {
          final tab = arguments['tab'];
          final sort = arguments['sort'];

          if (tab is int) {
            initialIndex = tab;
          }

          if (sort is String) {
            exploreSort = sort;
          }
        }

        return _fade(
          MainTabs(initialIndex: initialIndex, exploreSort: exploreSort),
          settings,
        );

      case login:
        return _fade(const LoginScreen(), settings);

      case register:
        return _fade(const RegisterScreen(), settings);

      case profile:
        return _fade(const ProfileScreen(), settings);

      case payment:
        return _fade(const PaymentScreen(), settings);

      case bookmarks:
        return _fade(const BookmarksScreen(), settings);

      case adminDashboard:
        return _fade(const AdminDashboardScreen(), settings);

      case adminUsers:
        return _fade(const AdminUsersListScreen(), settings);

      case adminUserForm:
        final arguments = settings.arguments;

        return _fade(
          AdminUserFormScreen(user: arguments is AppUser ? arguments : null),
          settings,
        );

      case adminReports:
        return _fade(const _AdminReportsPlaceholderScreen(), settings);

      default:
        return _fade(const _RouteNotFoundScreen(), settings);
    }
  }

  static PageRoute<dynamic> _fade(Widget child, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return child;
          },
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }
}

class _AdminReportsPlaceholderScreen extends StatelessWidget {
  const _AdminReportsPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo vi phạm')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chức năng báo cáo vi phạm đang được hoàn thiện.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy trang')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          },
          child: const Text('Về trang chủ'),
        ),
      ),
    );
  }
}
