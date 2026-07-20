import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/genre.dart';
import '../../../../domain/entities/story.dart';

class StoryInfo extends StatefulWidget {
  final Story story;
  const StoryInfo({super.key, required this.story});

  @override
  State<StoryInfo> createState() => _StoryInfoState();
}

class _StoryInfoState extends State<StoryInfo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final desc = widget.story.description?.isNotEmpty == true
        ? widget.story.description!
        : 'No summary available for this story yet.';

    final genres = widget.story.genres;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Summary',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Icon(Ionicons.information_circle_outline,
                  size: 20, color: AppColors.textSubtle),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            maxLines: _expanded ? null : 4,
            overflow:
                _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15, height: 1.6, color: AppColors.textMuted),
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_expanded ? 'Show less' : 'Read more',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Ionicons.chevron_up : Ionicons.chevron_down,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Genres',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: genres.isEmpty
                ? [_genreChip(context, null)]
                : [for (final g in genres) _genreChip(context, g)],
          ),
        ],
      ),
    );
  }

  Widget _genreChip(BuildContext context, Genre? genre) {
    final label = genre?.name ?? 'Not updated';
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSubtle,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    if (genre == null || genre.id.isEmpty) return chip;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
          arguments: {'tab': 1, 'genreIds': [genre.id]},
        );
      },
      child: chip,
    );
  }
}
