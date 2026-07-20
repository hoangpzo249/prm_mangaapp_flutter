import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_exceptions.dart';
import '../../../../application/services/storage_service.dart';
import '../../../../data/repositories/chapter_repository.dart';
import '../../../../data/repositories/history_repository.dart';
import '../../../../data/repositories/story_repository.dart';
import '../../../../domain/entities/chapter.dart';
import '../../../../domain/entities/history_item.dart';

class ChapterReaderScreen extends StatefulWidget {
  final String chapterId;
  const ChapterReaderScreen({super.key, required this.chapterId});

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  final _chapters = ChapterRepository.instance;
  final _stories = StoryRepository.instance;
  final _history = HistoryRepository.instance;
  final _storage = StorageService.instance;

  Chapter? _chapter;
  List<Chapter> _allChapters = [];
  bool _loading = true;
  bool _showControls = true;
  String _readingMode = 'vertical';

  static const _controlBg = Color(0xF20F172A);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await _storage.getReadingMode();
    if (mounted) setState(() {
      _loading = true;
      _readingMode = mode;
    });
    try {
      final data = await _chapters.fetchChapterContent(widget.chapterId);
      _chapter = data;

      if (data.storyId != null) {
        final story = await _stories.fetchStoryById(data.storyId!);
        await _storage.pushHistory(HistoryItem(
          storyId: data.storyId!,
          storyTitle: story?.title,
          storyThumbnail: story?.thumbnail,
          chapterId: data.id,
          chapterNumber: data.chapterNumber,
          chapterTitle: data.title,
          readAt: DateTime.now().toIso8601String(),
        ));
        _history.syncReadingHistory(data.storyId!, data.id);

        final chapters =
            await _chapters.fetchChaptersByStoryId(data.storyId!);
        chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
        _allChapters = chapters;
      }
    } on VipRequiredException catch (e) {
      if (!mounted) return;
      _gateAlert(e);
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _gateAlert(VipRequiredException e) {
    final isVip = e.status == 403;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(isVip ? 'VIP Required' : 'Login Required',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          isVip
              ? 'You need to upgrade to VIP for \$2/month to read this chapter.'
              : 'You need to login to read this VIP chapter.',
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.maybePop(context);
            },
            child: const Text('Back',
                style: TextStyle(color: AppColors.textSubtle)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(
                  context, isVip ? AppRoutes.payment : AppRoutes.login);
            },
            child: Text(isVip ? 'Unlock VIP' : 'Login',
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _navigateToChapter(String chapterId) {
    Navigator.pushReplacementNamed(context, '${AppRoutes.chapter}/$chapterId');
  }

  Chapter? get _prev {
    final i = _allChapters.indexWhere((c) => c.id == _chapter?.id);
    return i > 0 ? _allChapters[i - 1] : null;
  }

  Chapter? get _next {
    final i = _allChapters.indexWhere((c) => c.id == _chapter?.id);
    return (i >= 0 && i < _allChapters.length - 1)
        ? _allChapters[i + 1]
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_chapter == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chapter content not found',
                  style: TextStyle(color: AppColors.textLight, fontSize: 18)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Back',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _content(),
          if (_showControls) _header(),
          if (_showControls) _footer(),
        ],
      ),
    );
  }

  Widget _content() {
    final content = _chapter!.content;
    if (content.isEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showControls = !_showControls),
        child: const Padding(
          padding: EdgeInsets.only(top: 50),
          child: Text('Content has not been updated yet...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textLight)),
        ),
      );
    }

    Widget scrollable;
    if (_readingMode == 'horizontal') {
      scrollable = PageView.builder(
        itemCount: content.length + 1,
        itemBuilder: (_, i) {
          if (i == content.length) return _endOfChapter();
          return Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: _AutoHeightImage(url: content[i]),
            ),
          );
        },
      );
    } else {
      scrollable = ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: content.length + 1,
        itemBuilder: (_, i) {
          if (i == content.length) return _endOfChapter();
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: _AutoHeightImage(url: content[i]),
          );
        },
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showControls = !_showControls),
      child: scrollable,
    );
  }

  Widget _endOfChapter() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const Text('End of Chapter',
              style: TextStyle(color: AppColors.textDim)),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(child: _endNavBtn('Previous', _prev, isPrev: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _endNavBtn('Next', _next, isPrev: false)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _endNavBtn(String label, Chapter? target, {required bool isPrev}) {
    final enabled = target != null;
    final color = enabled ? Colors.white : AppColors.textFaint;
    return GestureDetector(
      onTap: enabled ? () => _navigateToChapter(target.id) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPrev) Icon(Ionicons.chevron_back, size: 20, color: color),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w600)),
              if (!isPrev)
                Icon(Ionicons.chevron_forward, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding:
            EdgeInsets.only(left: 15, right: 15, top: topPad + 10, bottom: 15),
        decoration: const BoxDecoration(
          color: _controlBg,
          border:
              Border(bottom: BorderSide(color: Color(0x0DFFFFFF), width: 1)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_chapter?.storyId != null) {
                  Navigator.pushReplacementNamed(context,
                      '${AppRoutes.story}/${_chapter!.storyId}');
                } else {
                  Navigator.maybePop(context);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Ionicons.arrow_back, size: 24, color: Colors.white),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('Chapter ${_chapter!.chapterNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  if ((_chapter!.title ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(_chapter!.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSubtle)),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showSettingsModal,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Ionicons.settings_outline, size: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cài đặt đọc',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Ionicons.arrow_down_outline, color: Colors.white),
              title: const Text('Cuộn dọc', style: TextStyle(color: Colors.white)),
              trailing: _readingMode == 'vertical' ? const Icon(Ionicons.checkmark, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _readingMode = 'vertical');
                _storage.setReadingMode('vertical');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.arrow_forward_outline, color: Colors.white),
              title: const Text('Cuộn ngang', style: TextStyle(color: Colors.white)),
              trailing: _readingMode == 'horizontal' ? const Icon(Ionicons.checkmark, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _readingMode = 'horizontal');
                _storage.setReadingMode('horizontal');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 35),
        decoration: const BoxDecoration(
          color: _controlBg,
          border: Border(top: BorderSide(color: Color(0x0DFFFFFF), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _footerBtn(Ionicons.play_skip_back, 'Prev', _prev),
            GestureDetector(
              onTap: _openChapterModal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Ionicons.list, size: 20, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                        'Ch. ${_chapter!.chapterNumber} / ${_allChapters.length}',
                        style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            _footerBtn(Ionicons.play_skip_forward, 'Next', _next),
          ],
        ),
      ),
    );
  }

  Widget _footerBtn(IconData icon, String label, Chapter? target) {
    final enabled = target != null;
    return GestureDetector(
      onTap: enabled ? () => _navigateToChapter(target.id) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  void _openChapterModal() {
    final searchCtrl = TextEditingController();
    String query = '';
    bool newestFirst = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      isScrollControlled: true,
      builder: (_) {
        final h = MediaQuery.of(context).size.height * 0.65;
        return StatefulBuilder(builder: (ctx, setModalState) {
          final filtered = query.isEmpty
              ? List<Chapter>.from(_allChapters)
              : _allChapters.where((c) {
                  final q = query.toLowerCase();
                  final title = (c.title ?? '').toLowerCase();
                  final number = c.chapterNumber.toString();
                  return title.contains(q) || number.contains(q);
                }).toList();
          filtered.sort((a, b) => newestFirst
              ? b.chapterNumber.compareTo(a.chapterNumber)
              : a.chapterNumber.compareTo(b.chapterNumber));

          return Container(
            height: h,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(15, 15, 15, 12),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.card, width: 1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Chapters',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                    '${filtered.length}/${_allChapters.length}',
                                    style: const TextStyle(
                                        color: AppColors.textDim,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setModalState(
                                    () => newestFirst = !newestFirst),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        newestFirst
                                            ? Ionicons.arrow_down
                                            : Ionicons.arrow_up,
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        newestFirst ? 'Newest' : 'Oldest',
                                        style: const TextStyle(
                                            color: AppColors.textBright,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Ionicons.close_circle,
                                    size: 26, color: AppColors.textSubtle),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 40,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Ionicons.search,
                                size: 18, color: AppColors.textSubtle),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: searchCtrl,
                                onChanged: (v) => setModalState(
                                    () => query = v.trim()),
                                style: const TextStyle(
                                    color: AppColors.textBright,
                                    fontSize: 14),
                                cursorColor: AppColors.primary,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText:
                                      'Search chapter number or title',
                                  hintStyle: TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                            if (query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  searchCtrl.clear();
                                  setModalState(() => query = '');
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Ionicons.close_circle,
                                      size: 18,
                                      color: AppColors.textSubtle),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No chapters match your search.',
                            style: TextStyle(
                                color: AppColors.textSubtle, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 40, left: 10, right: 10),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final isCurrent = item.id == _chapter!.id;
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                if (!isCurrent) _navigateToChapter(item.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.primary
                                          .withValues(alpha: 0.1)
                                      : null,
                                  border: const Border(
                                      bottom: BorderSide(
                                          color: AppColors.card, width: 1)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Chapter ${item.chapterNumber}: ${item.title ?? ''}',
                                        style: TextStyle(
                                          color: isCurrent
                                              ? AppColors.primary
                                              : AppColors.textMuted,
                                          fontSize: 15,
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (item.isVip)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppColors.gold
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: const Text('VIP',
                                            style: TextStyle(
                                                color: AppColors.gold,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

/// Renders a full-width page image whose height is derived from the image's
/// intrinsic aspect ratio.
class _AutoHeightImage extends StatefulWidget {
  final String url;
  const _AutoHeightImage({required this.url});

  @override
  State<_AutoHeightImage> createState() => _AutoHeightImageState();
}

class _AutoHeightImageState extends State<_AutoHeightImage> {
  double? _ratio;

  @override
  void initState() {
    super.initState();
    final stream = CachedNetworkImageProvider(widget.url)
        .resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (w > 0 && mounted) setState(() => _ratio = w / h);
      stream.removeListener(listener);
    }, onError: (_, _) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = _ratio != null ? width / _ratio! : width * 1.5;
    return SizedBox(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: widget.url,
        width: width,
        height: height,
        fit: BoxFit.fitWidth,
        placeholder: (_, _) => const ColoredBox(color: Colors.black),
        errorWidget: (_, _, _) => const ColoredBox(color: Colors.black),
      ),
    );
  }
}
