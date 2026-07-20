import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_exceptions.dart';
import '../../../../data/repositories/bookmark_repository.dart';
import '../../../../data/repositories/chapter_repository.dart';
import '../../../../data/repositories/history_repository.dart';
import '../../../../data/repositories/report_repository.dart';
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
  final _reports = ReportRepository.instance;

  Story? _story;
  String? _firstChapterId;
  String? _continueChapterId;
  num? _continueChapterNumber;

  bool _loading = true;
  bool _bookmarked = false;
  bool _submittingReport = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final story = await _stories.fetchStoryById(widget.storyId);
      final chapters = await _chapters.fetchChaptersByStoryId(widget.storyId);

      String? firstChapterId;
      if (chapters.isNotEmpty) {
        chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
        firstChapterId = chapters.first.id;
      }

      bool bookmarked = false;
      try {
        bookmarked = await _bookmarks.checkBookmark(widget.storyId);
      } on NotLoggedInException {
        bookmarked = false;
      }

      String? continueChapterId;
      num? continueChapterNumber;

      try {
        final entry = await _history.getStoryHistory(widget.storyId);
        if (entry != null && entry.chapterId != null) {
          continueChapterId = entry.chapterId;
          continueChapterNumber = entry.chapterNumber;
        }
      } on NotLoggedInException {
        continueChapterId = null;
        continueChapterNumber = null;
      }

      if (!mounted) return;

      setState(() {
        _story = story;
        _firstChapterId = firstChapterId;
        _bookmarked = bookmarked;
        _continueChapterId = continueChapterId;
        _continueChapterNumber = continueChapterNumber;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _story = null;
        _loading = false;
        _loadError = _extractErrorMessage(
          error,
          fallback: 'Unable to load story details',
        );
      });
    }

    // 3 request phụ chạy song song, cập nhật khi từng cái xong.
    unawaited(
      _chapters
          .fetchChaptersByStoryId(widget.storyId)
          .then((chapters) {
            if (!mounted || chapters.isEmpty) return;
            chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
            setState(() => _firstChapterId = chapters.first.id);
          })
          .catchError((_) {}),
    );

    unawaited(
      _bookmarks
          .checkBookmark(widget.storyId)
          .then((b) {
            if (!mounted) return;
            setState(() => _bookmarked = b);
          })
          .catchError((_) {}),
    );

    unawaited(
      _history
          .getStoryHistory(widget.storyId)
          .then((entry) {
            if (!mounted || entry == null || entry.chapterId == null) return;
            setState(() {
              _continueChapterId = entry.chapterId;
              _continueChapterNumber = entry.chapterNumber;
            });
          })
          .catchError((_) {}),
    );
  }

  Future<void> _toggleBookmark() async {
    try {
      final res = await _bookmarks.toggleBookmark(widget.storyId);
      final isBookmarked = res['isBookmarked'] == true;

      if (!mounted) return;

      setState(() => _bookmarked = isBookmarked);
      _snack(
        isBookmarked ? 'Added to your library' : 'Removed from your library',
      );
    } on NotLoggedInException {
      if (!mounted) return;
      _showLoginPrompt(
        message: 'You need to login to save stories to your library.',
      );
    } catch (error) {
      if (!mounted) return;
      _snack(
        _extractErrorMessage(error, fallback: 'Failed to update bookmark'),
      );
    }
  }

  Future<void> _reportStory() async {
    if (_submittingReport) return;

    final reason = await _showReportDialog();
    if (reason == null || reason.trim().isEmpty) return;

    if (!mounted) return;

    setState(() => _submittingReport = true);

    try {
      await _reports.reportStory(widget.storyId, reason.trim());

      if (!mounted) return;
      _snack('Report submitted successfully');
    } on NotLoggedInException {
      if (!mounted) return;
      _showLoginPrompt(
        message: 'You need to login before reporting this story.',
      );
    } catch (error) {
      if (!mounted) return;
      _snack(_extractErrorMessage(error, fallback: 'Failed to submit report'));
    } finally {
      if (mounted) {
        setState(() => _submittingReport = false);
      }
    }
  }

  Future<String?> _showReportDialog() async {
    const reasons = <String>[
      'Inappropriate content',
      'Copyright violation',
      'Spam or misleading content',
      'Violence or offensive content',
      'Other',
    ];

    final controller = TextEditingController();
    String? selectedReason;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final showCustomReason = selectedReason == 'Other';

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
              contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              title: const Row(
                children: [
                  Icon(
                    Ionicons.flag_outline,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report Story',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select the reason that best describes the violation.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...reasons.map(
                      (reason) => RadioListTile<String>(
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedReason = value;
                          });
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          reason,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (showCustomReason) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 500,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Describe the violation...',
                          hintStyle: const TextStyle(
                            color: AppColors.textSubtle,
                          ),
                          counterStyle: const TextStyle(
                            color: AppColors.textSubtle,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSubtle),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          final customReason = controller.text.trim();

                          if (selectedReason == 'Other' &&
                              customReason.isEmpty) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a report reason'),
                                ),
                              );
                            return;
                          }

                          Navigator.pop(
                            dialogContext,
                            selectedReason == 'Other'
                                ? customReason
                                : selectedReason,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: AppColors.textSubtle,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );

    // Không dispose controller ngay sau khi dialog đóng.
    // TextField vẫn có thể đang được Flutter tháo khỏi widget tree,
    // dispose tại đây dễ gây assertion `_dependents.isEmpty`.
    return result;
  }

  void _snack(String message) {
    if (!mounted || message.trim().isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLoginPrompt({required String message}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Login Required',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: const Text(
              'Login',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _extractErrorMessage(Object error, {required String fallback}) {
    final raw = error.toString().trim();

    if (raw.isEmpty) return fallback;

    final cleaned = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_story == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Ionicons.book_outline,
                    size: 64,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Story not found',
                    style: TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _load,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Try Again'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.home,
                          (route) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Go Home'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        StoryInfo(story: _story!),
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          color: AppColors.card,
                        ),
                        StoryInteractionSection(
                          storyId: widget.storyId,
                          showComments: false,
                        ),
                        ChapterList(storyId: widget.storyId),
                        StoryInteractionSection(
                          storyId: widget.storyId,
                          showRating: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar()),
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
          colors: [Colors.transparent, Color(0xF20B162C), AppColors.background],
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 30,
        ),
        child: Row(
          children: [
            _circleActionButton(
              onTap: _toggleBookmark,
              icon: _bookmarked ? Ionicons.bookmark : Ionicons.bookmark_outline,
              foregroundColor: _bookmarked ? Colors.white : AppColors.primary,
              backgroundColor: _bookmarked
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.1),
              borderColor: _bookmarked
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.3),
              tooltip: _bookmarked ? 'Remove bookmark' : 'Add bookmark',
            ),
            const SizedBox(width: 10),
            _circleActionButton(
              onTap: _submittingReport ? null : _reportStory,
              icon: Ionicons.flag_outline,
              foregroundColor: Colors.redAccent,
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              borderColor: Colors.redAccent.withValues(alpha: 0.35),
              tooltip: 'Report story',
              loading: _submittingReport,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: hasChapter
                    ? () => Navigator.pushNamed(
                        context,
                        '${AppRoutes.chapter}/$targetChapterId',
                      )
                    : null,
                child: Container(
                  height: 58,
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
                              color: AppColors.primary.withValues(alpha: 0.3),
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
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
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

  Widget _circleActionButton({
    required VoidCallback? onTap,
    required IconData icon,
    required Color foregroundColor,
    required Color backgroundColor,
    required Color borderColor,
    required String tooltip,
    bool loading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: onTap == null ? 0.6 : 1,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.redAccent,
                    ),
                  )
                : Icon(icon, size: 23, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}
