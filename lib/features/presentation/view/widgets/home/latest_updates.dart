import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/formatters.dart';
import '../../../../data/repositories/story_repository.dart';
import '../../../../domain/entities/chapter.dart';
import '../../../../domain/entities/story.dart';
import '../../screens/main_tabs.dart';
import '../net_image.dart';

class LatestUpdates extends StatefulWidget {
  const LatestUpdates({super.key});

  @override
  State<LatestUpdates> createState() => _LatestUpdatesState();
}

class _LatestUpdatesState extends State<LatestUpdates> {
  final _stories = StoryRepository.instance;
  List<Story> _updates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _stories.fetchRecentUpdates();
    if (mounted) {
      setState(() {
        _updates = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  for (final item in _updates) _item(item),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Latest Updates',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        GestureDetector(
          onTap: () => TabsScope.of(context).goToTab(1, sort: 'latest'),
          child: const Row(
            children: [
              Text('VIEW ALL ',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Icon(Ionicons.caret_forward, size: 12, color: AppColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item(Story item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (item.id.isNotEmpty) {
                Navigator.pushNamed(context, '${AppRoutes.story}/${item.id}');
              }
            },
            child: NetImage(
              url: item.thumbnail,
              width: 100,
              height: 140,
              radius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (item.id.isNotEmpty) {
                        Navigator.pushNamed(
                            context, '${AppRoutes.story}/${item.id}');
                      }
                    },
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (item.latestChapters.isEmpty)
                    const Text('Updating new chapters...',
                        style: TextStyle(
                            color: AppColors.textSubtle, fontSize: 12))
                  else
                    for (final chap in item.latestChapters) _chapterRow(chap),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chapterRow(Chapter chap) {
    final label = chap.title ?? 'Chapter ${chap.chapterNumber}';
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '${AppRoutes.chapter}/${chap.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (chap.isVip)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Ionicons.lock_closed,
                          size: 14, color: AppColors.gold),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(Formatters.timeAgo(chap.updatedAt),
                style: const TextStyle(
                    color: AppColors.textSubtle, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
