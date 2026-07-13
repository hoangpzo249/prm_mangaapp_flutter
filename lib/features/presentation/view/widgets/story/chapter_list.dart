import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/formatters.dart';
import '../../../../application/services/storage_service.dart';
import '../../../../data/repositories/chapter_repository.dart';
import '../../../../domain/entities/chapter.dart';

class ChapterList extends StatefulWidget {
  final String storyId;
  const ChapterList({super.key, required this.storyId});

  @override
  State<ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  final _chapters = ChapterRepository.instance;
  final _storage = StorageService.instance;
  final _searchController = TextEditingController();

  List<Chapter> _list = [];
  bool _loading = true;
  bool _isVipUser = false;
  bool _newestFirst = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await _storage.getUser();
    _isVipUser = user?.isVip ?? false;
    final data = await _chapters.fetchChaptersByStoryId(widget.storyId);
    if (mounted) {
      setState(() {
        _list = data;
        _loading = false;
      });
    }
  }

  List<Chapter> get _visible {
    final filtered = _query.isEmpty
        ? List<Chapter>.from(_list)
        : _list.where((c) {
            final q = _query.toLowerCase();
            final title = (c.title ?? '').toLowerCase();
            final number = c.chapterNumber.toString();
            return title.contains(q) || number.contains(q);
          }).toList();
    filtered.sort((a, b) => _newestFirst
        ? b.chapterNumber.compareTo(a.chapterNumber)
        : a.chapterNumber.compareTo(b.chapterNumber));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2)),
      );
    }
    if (_list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: Text('No chapters available yet.',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 15)),
        ),
      );
    }

    final visible = _visible;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Chapters',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('${_list.length} total',
                        style: const TextStyle(
                            color: AppColors.textDim, fontSize: 14)),
                  ),
                ],
              ),
              _sortToggle(),
            ],
          ),
          const SizedBox(height: 14),
          _searchField(),
          const SizedBox(height: 6),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No chapters match your search.',
                    style:
                        TextStyle(color: AppColors.textSubtle, fontSize: 14)),
              ),
            )
          else
            for (final chapter in visible) _row(chapter),
        ],
      ),
    );
  }

  Widget _sortToggle() {
    return GestureDetector(
      onTap: () => setState(() => _newestFirst = !_newestFirst),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _newestFirst ? Ionicons.arrow_down : Ionicons.arrow_up,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _newestFirst ? 'Newest' : 'Oldest',
              style: const TextStyle(
                  color: AppColors.textBright,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              style:
                  const TextStyle(color: AppColors.textBright, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search chapter number or title',
                hintStyle:
                    TextStyle(color: AppColors.textDim, fontSize: 14),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Ionicons.close_circle,
                    size: 18, color: AppColors.textSubtle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(Chapter chapter) {
    final isLocked = chapter.isVip && !_isVipUser;
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '${AppRoutes.chapter}/${chapter.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.card, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${chapter.chapterNumber}: ${chapter.title ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLocked
                          ? AppColors.textSubtle
                          : AppColors.textBright,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(Formatters.timeAgo(chapter.updatedAt),
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            if (chapter.isVip)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: const Text('VIP',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            Icon(
              isLocked ? Ionicons.lock_closed : Ionicons.chevron_forward,
              size: 20,
              color: isLocked ? AppColors.gold : AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
