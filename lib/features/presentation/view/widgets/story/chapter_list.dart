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

  List<Chapter> _list = [];
  bool _loading = true;
  bool _isVipUser = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await _storage.getUser();
    _isVipUser = user?.isVip ?? false;
    final data = await _chapters.fetchChaptersByStoryId(widget.storyId);
    data.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
    if (mounted) {
      setState(() {
        _list = data;
        _loading = false;
      });
    }
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
              const Icon(Ionicons.filter, size: 20, color: AppColors.textSubtle),
            ],
          ),
          const SizedBox(height: 20),
          for (final chapter in _list) _row(chapter),
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
