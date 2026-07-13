import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_exceptions.dart';
import '../../../../data/repositories/bookmark_repository.dart';
import '../../../../data/repositories/chapter_repository.dart';
import '../../../../data/repositories/history_repository.dart';
import '../../../../data/repositories/story_repository.dart';
import '../../../../domain/entities/story.dart';
import '../../widgets/story/chapter_list.dart';
import '../../widgets/story/story_header.dart';
import '../../widgets/story/story_info.dart';
import '../../widgets/story/story_interaction_section.dart';

class StoryDetailScreen extends StatefulWidget {
  final String storyId;
  const StoryDetailScreen({super.key, required this.storyId});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final _stories = StoryRepository.instance;
  final _chapters = ChapterRepository.instance;
  final _bookmarks = BookmarkRepository.instance;
  final _history = HistoryRepository.instance;

  Story? _story;
  String? _firstChapterId;
  String? _continueChapterId;
  num? _continueChapterNumber;
  bool _loading = true;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final story = await _stories.fetchStoryById(widget.storyId);
    final chapters = await _chapters.fetchChaptersByStoryId(widget.storyId);
    if (chapters.isNotEmpty) {
      chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
      _firstChapterId = chapters.first.id;
    }
    _bookmarked = await _bookmarks.checkBookmark(widget.storyId);

    final entry = await _history.getStoryHistory(widget.storyId);
    if (entry != null && entry.chapterId != null) {
      _continueChapterId = entry.chapterId;
      _continueChapterNumber = entry.chapterNumber;
    }

    if (mounted) {
      setState(() {
        _story = story;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final res = await _bookmarks.toggleBookmark(widget.storyId);
      final isBookmarked = res['isBookmarked'] == true;
      setState(() => _bookmarked = isBookmarked);
      _snack(isBookmarked
          ? 'Added to your library'
          : 'Removed from your library');
    } on NotLoggedInException {
      _loginPrompt();
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

  void _loginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Login Required',
            style: TextStyle(color: Colors.white)),
        content: const Text('You need to login to save stories to your library.',
            style: TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSubtle)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: const Text('Login',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_story == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Ionicons.book_outline,
                  size: 64, color: AppColors.border),
              const SizedBox(height: 16),
              const Text('Story not found',
                  style: TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (r) => false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Go Back',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                StoryHeader(story: _story!),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        StoryInfo(story: _story!),
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          color: AppColors.card,
                        ),
                        ChapterList(storyId: widget.storyId),
                        StoryInteractionSection(storyId: widget.storyId),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final hasContinue = _continueChapterId != null;
    final targetChapterId = _continueChapterId ?? _firstChapterId;
    final hasChapter = targetChapterId != null;
    final label = hasContinue
        ? 'Continue Chapter ${_continueChapterNumber ?? ''}'.trim()
        : (hasChapter ? 'Read First Chapter' : 'No Chapters Yet');
    return Container(
      height: 110,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color(0xF20B162C),
            AppColors.background
          ],
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleBookmark,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _bookmarked
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _bookmarked
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _bookmarked
                      ? Ionicons.bookmark
                      : Ionicons.bookmark_outline,
                  size: 24,
                  color: _bookmarked ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: hasChapter
                    ? () => Navigator.pushNamed(context,
                        '${AppRoutes.chapter}/$targetChapterId')
                    : null,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasChapter
                          ? [AppColors.primary, AppColors.primaryDark]
                          : [AppColors.textFaint, AppColors.border],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: hasChapter
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasContinue ? Ionicons.play : Ionicons.book,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
