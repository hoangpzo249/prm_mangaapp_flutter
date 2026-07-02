import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_exceptions.dart';
import '../../../../data/repositories/bookmark_repository.dart';
import '../../../../domain/entities/story.dart';
import '../net_image.dart';

class FeaturedSection extends StatefulWidget {
  final List<Story> randomStories;
  const FeaturedSection({super.key, this.randomStories = const []});

  @override
  State<FeaturedSection> createState() => _FeaturedSectionState();
}

class _FeaturedSectionState extends State<FeaturedSection> {
  final _bookmarks = BookmarkRepository.instance;
  Story? _active;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    if (widget.randomStories.isNotEmpty) _active = widget.randomStories.first;
    _checkStatus();
  }

  @override
  void didUpdateWidget(covariant FeaturedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_active == null && widget.randomStories.isNotEmpty) {
      setState(() => _active = widget.randomStories.first);
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final id = _active?.id;
    if (id == null || id.isEmpty) return;
    final b = await _bookmarks.checkBookmark(id);
    if (mounted) setState(() => _bookmarked = b);
  }

  Future<void> _toggleBookmark() async {
    final id = _active?.id;
    if (id == null || id.isEmpty) return;
    try {
      final res = await _bookmarks.toggleBookmark(id);
      setState(() => _bookmarked = res['isBookmarked'] == true);
      _snack(res['message']?.toString() ?? '');
    } on NotLoggedInException {
      Navigator.pushNamed(context, AppRoutes.login);
    } catch (_) {
      _snack('Failed to toggle bookmark');
    }
  }

  void _snack(String msg) {
    if (msg.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final top = _active;
    final list = widget.randomStories.take(10).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (top?.thumbnail != null)
                NetImage(url: top!.thumbnail, fit: BoxFit.cover, opacity: 0.4),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.background],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _genreTags(top),
              const SizedBox(height: 15),
              Text(
                top?.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 15),
              Text(
                (top?.description != null &&
                        top!.description!.isNotEmpty &&
                        top.description != 'Đang cập nhật...')
                    ? top.description!
                    : 'Read the latest chapters of this thrilling masterpiece on FCOMIC. Tap to start your journey now...',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),
              _actions(top),
              const SizedBox(height: 30),
              _rail(list),
            ],
          ),
        ),
      ],
    );
  }

  Widget _genreTags(Story? top) {
    return Row(
      children: [
        _tag('ACTION'),
        const SizedBox(width: 10),
        _tag('ADVENTURE'),
        const SizedBox(width: 10),
        _tag('MYSTERY'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Ionicons.star, size: 14, color: AppColors.star),
              Text(
                ' ${top?.rating ?? '4.6'}',
                style: const TextStyle(
                    color: AppColors.star, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _actions(Story? top) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              if (top?.id.isNotEmpty == true) {
                Navigator.pushNamed(context, '${AppRoutes.story}/${top!.id}');
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Ionicons.play, size: 18, color: Colors.black),
                  Text(' START READING',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _toggleBookmark,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _bookmarked ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _bookmarked ? Ionicons.bookmark : Ionicons.bookmark_outline,
                    size: 18,
                    color: _bookmarked ? Colors.white : AppColors.textSubtle,
                  ),
                  Text(
                    _bookmarked ? ' SAVED' : ' SAVE',
                    style: TextStyle(
                        color: _bookmarked ? Colors.white : AppColors.textSubtle,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rail(List<Story> list) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 15),
        itemBuilder: (_, i) {
          final item = list[i];
          final selected = _active?.id == item.id;
          final title = item.title.length > 12
              ? '${item.title.substring(0, 12)}...'
              : item.title;
          return GestureDetector(
            onTap: () {
              setState(() => _active = item);
              _checkStatus();
            },
            child: Opacity(
              opacity: selected ? 1 : 0.6,
              child: SizedBox(
                width: 80,
                child: Column(
                  children: [
                    NetImage(
                      url: item.thumbnail,
                      width: 80,
                      height: 120,
                      radius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textSubtle,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
