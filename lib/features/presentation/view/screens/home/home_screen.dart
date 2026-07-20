import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/repositories/story_repository.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/story.dart';
import '../../widgets/home/featured_section.dart';
import '../../widgets/home/latest_updates.dart';
import '../../widgets/home/popular_rank.dart';
import '../../widgets/logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _stories = StoryRepository.instance;
  final _auth = AuthRepository.instance;
  final _notifications = NotificationRepository.instance;
  final _scroll = ScrollController();

  List<Story> _hotStories = [];
  List<Story> _randomStories = [];
  bool _loading = true;
  AppUser? _user;
  int _unreadCount = 0;
  double _headerOffset = 0;

  double get _headerHeight => 60 + MediaQuery.paddingOf(context).top;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadData();
    _checkUser();
  }

  void _onScroll() {
    final o = _scroll.offset.clamp(0.0, _headerHeight);
    if (o != _headerOffset) setState(() => _headerOffset = o);
  }

  Future<void> _checkUser() async {
    final u = await _auth.getUserData();
    if (mounted) setState(() => _user = u);
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_user == null) {
      if (_unreadCount != 0 && mounted) setState(() => _unreadCount = 0);
      return;
    }
    try {
      final res = await _notifications.getNotifications(limit: 1);
      if (!mounted) return;
      setState(() => _unreadCount = res.unreadCount);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _stories.fetchHotStories(),
      _stories.fetchRandomStories(),
    ]);
    if (!mounted) return;
    setState(() {
      _hotStories = results[0];
      _randomStories = results[1];
      _loading = false;
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const ColoredBox(
        color: AppColors.background,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          ListView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: _headerHeight),
            children: [
              FeaturedSection(randomStories: _randomStories),
              const LatestUpdates(),
              PopularRank(hotStories: _hotStories),
            ],
          ),
          Positioned(
            top: -_headerOffset,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: _headerHeight,
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Logo(fontSize: 22),
              Row(
                children: [
                  if (_user != null && !_user!.isVip)
                    _iconBtn(
                      const Icon(Ionicons.diamond,
                          size: 24, color: AppColors.gold),
                      () => Navigator.pushNamed(context, AppRoutes.payment),
                    ),
                  if (_user != null) _bellButton(),
                  _iconBtn(
                    const Icon(Ionicons.bookmark_outline,
                        size: 24, color: Colors.white),
                    () => Navigator.pushNamed(context, AppRoutes.bookmarks),
                  ),
                  const SizedBox(width: 15),
                  _userButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(Widget child, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(5), child: child),
      ),
    );
  }

  Widget _bellButton() {
    final count = _unreadCount;
    final label = count > 99 ? '99+' : '$count';
    return _iconBtn(
      Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Ionicons.notifications_outline,
              size: 24, color: Colors.white),
          if (count > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: count > 9 ? 5 : 4,
                  vertical: 1,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
      () async {
        await Navigator.pushNamed(context, AppRoutes.notifications);
        _loadUnreadCount();
      },
    );
  }

  Widget _userButton() {
    final loggedIn = _user != null;
    final avatarUrl = _user?.avatar;

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
            context, loggedIn ? AppRoutes.profile : AppRoutes.login);
        _checkUser();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: loggedIn
            ? ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          _user!.username.isNotEmpty
                              ? _user!.username[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    : Text(
                        _user!.username.isNotEmpty
                            ? _user!.username[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              )
            : const Icon(Ionicons.person_outline,
                size: 18, color: Colors.white),
      ),
    );
  }
}
