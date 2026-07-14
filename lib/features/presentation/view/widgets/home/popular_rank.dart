import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/formatters.dart';
import '../../../../domain/entities/story.dart';
import '../../screens/main_tabs.dart';
import '../net_image.dart';

class PopularRank extends StatelessWidget {
  final List<Story> hotStories;
  const PopularRank({super.key, this.hotStories = const []});

  @override
  Widget build(BuildContext context) {
    final rng = Random();
    final mangas = hotStories.take(5).toList().asMap().entries.map((e) {
      final s = e.value;
      return _RankData(
        id: s.id,
        title: s.title,
        views: s.views != 0 ? s.views : rng.nextInt(5000000) + 10000,
        genres: s.genres.isNotEmpty
            ? s.genres.map((g) => g.name).join(', ')
            : 'ACTION, ADVENTURE',
        rank: e.key + 1,
        thumbnail: s.thumbnail,
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 10),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 24),
          for (final m in mangas)
            _RankItem(
              data: m,
              onTap: () =>
                  Navigator.pushNamed(context, '${AppRoutes.story}/${m.id}'),
            ),
          _fullRankButton(context),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Ionicons.flame, size: 28, color: AppColors.flame),
            ),
            SizedBox(width: 8),
            Text('POPULAR',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.flame.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.flame.withValues(alpha: 0.3)),
          ),
          child: const Text('ALL TIME',
              style: TextStyle(
                  color: AppColors.flameLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _fullRankButton(BuildContext context) {
    return GestureDetector(
      onTap: () => TabsScope.of(context).goToTab(1, sort: 'popular'),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.skyLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.skyLight.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('VIEW FULL RANKING',
                style: TextStyle(
                    color: AppColors.skyLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 13)),
            SizedBox(width: 6),
            Icon(Ionicons.chevron_forward, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _RankData {
  final String id;
  final String title;
  final num views;
  final String genres;
  final int rank;
  final String? thumbnail;
  _RankData({
    required this.id,
    required this.title,
    required this.views,
    required this.genres,
    required this.rank,
    this.thumbnail,
  });
}

class _RankItem extends StatefulWidget {
  final _RankData data;
  final VoidCallback onTap;
  const _RankItem({required this.data, required this.onTap});

  @override
  State<_RankItem> createState() => _RankItemState();
}

class _RankItemState extends State<_RankItem> {
  double _scale = 1;

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.rankGold;
      case 2:
        return AppColors.rankSilver;
      case 3:
        return AppColors.rankBronze;
      default:
        return AppColors.textFaint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.data;
    final isTop3 = m.rank <= 3;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${m.rank}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _rankColor(m.rank),
                    fontSize: isTop3 ? 32 : 24,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 2),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NetImage(
                      url: m.thumbnail,
                      width: 64,
                      height: 90,
                      radius: BorderRadius.circular(12),
                      placeholderColor: AppColors.border,
                    ),
                    if (isTop3)
                      Positioned(
                        top: -6,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.flame,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.surface, width: 2),
                          ),
                          child: const Icon(Ionicons.trophy,
                              size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textBright,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.33),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textSubtle.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Ionicons.eye,
                              size: 14, color: AppColors.textSubtle),
                          Text(' ${Formatters.views(m.views)} Views',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.genres.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
