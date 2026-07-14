import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
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
  final _scroll = ScrollController();

  List<Story> _hotStories = [];
  List<Story> _randomStories = [];
  bool _loading = true;
  AppUser? _user;
  double _headerOffset = 0;

  double get _headerHeight => 60;

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
