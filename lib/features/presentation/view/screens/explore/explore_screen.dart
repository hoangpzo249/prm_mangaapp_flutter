import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/genre_repository.dart';
import '../../../../data/repositories/story_repository.dart';
import '../../../../domain/entities/genre.dart';
import '../../../../domain/entities/story.dart';
import '../../widgets/net_image.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialSort;
  final List<String>? initialGenreIds;
  const ExploreScreen({super.key, this.initialSort, this.initialGenreIds});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _stories = StoryRepository.instance;
  final _genreRepo = GenreRepository.instance;
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  static const int itemsPerPage = 20;

  List<Story> _all = [];
  List<Story> _displayed = [];
  List<Genre> _availableGenres = [];
  final Set<String> _selectedGenreIds = <String>{};
  bool _loading = true;
  String _query = '';
  int _page = 1;
  late String _sortBy = widget.initialSort == 'latest' ? 'latest' : 'views';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (widget.initialGenreIds != null) {
      _selectedGenreIds.addAll(widget.initialGenreIds!);
    }
    _loadGenres();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    var needsRefilter = false;
    if (widget.initialSort != null &&
        widget.initialSort != oldWidget.initialSort) {
      _sortBy = widget.initialSort == 'latest' ? 'latest' : 'views';
      needsRefilter = true;
    }
    if (widget.initialGenreIds != null &&
        widget.initialGenreIds != oldWidget.initialGenreIds) {
      _selectedGenreIds
        ..clear()
        ..addAll(widget.initialGenreIds!);
      needsRefilter = true;
    }
    if (needsRefilter) _applySort();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _genreRepo.fetchGenres();
      if (!mounted) return;
      setState(() => _availableGenres = genres);
    } catch (_) {}
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value != _query) {
        _query = value;
        _loadData();
      }
      setState(() {});
    });
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = _query.trim().isNotEmpty
        ? await _stories.searchStories(_query)
        : await _stories.fetchStories();
    if (!mounted) return;
    _all = data;
    _page = 1;
    _applySort();
    setState(() => _loading = false);
  }

  List<Story> _applyGenreFilter(List<Story> stories) {
    if (_selectedGenreIds.isEmpty) return stories;
    return stories
        .where((s) => s.genres.any((g) => _selectedGenreIds.contains(g.id)))
        .toList();
  }

  void _applySort() {
    final filtered = _applyGenreFilter(_all);
    filtered.sort((a, b) {
      if (_sortBy == 'A-Z') {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else if (_sortBy == 'latest') {
        final da = DateTime.tryParse(a.updatedAt ?? '')?.millisecondsSinceEpoch ?? 0;
        final db = DateTime.tryParse(b.updatedAt ?? '')?.millisecondsSinceEpoch ?? 0;
        return db.compareTo(da);
      } else {
        return b.views.compareTo(a.views);
      }
    });
    setState(() => _displayed = filtered.take(_page * itemsPerPage).toList());
  }

  int get _filteredCount => _applyGenreFilter(_all).length;

  void _loadMore() {
    if (_displayed.length < _filteredCount) {
      _page++;
      _applySort();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _searchHeader(),
            _filterRow(),
            Expanded(child: _grid()),
          ],
        ),
      ),
    );
  }

  Widget _searchHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 10),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(Ionicons.search, size: 20, color: AppColors.textSubtle),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                cursorColor: AppColors.primary,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search manga...',
                  hintStyle:
                      TextStyle(color: AppColors.textSubtle, fontSize: 15),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: const Icon(Ionicons.close_circle,
                    size: 20, color: AppColors.textSubtle),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGenreSheet() async {
    if (_availableGenres.isEmpty) return;
    final draft = Set<String>.from(_selectedGenreIds);

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollCtrl) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            const Icon(
                              Ionicons.pricetags_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Filter by genre',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (draft.isNotEmpty)
                              TextButton(
                                onPressed: () => setSheet(() => draft.clear()),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _availableGenres.map((g) {
                              final selected = draft.contains(g.id);
                              return _sheetChip(
                                label: g.name,
                                selected: selected,
                                onTap: () {
                                  setSheet(() {
                                    if (selected) {
                                      draft.remove(g.id);
                                    } else {
                                      draft.add(g.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(color: AppColors.border, width: 1),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          12,
                          20,
                          12 + MediaQuery.paddingOf(ctx).bottom,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(ctx, draft),
                            child: Text(
                              draft.isEmpty
                                  ? 'Show all mangas'
                                  : 'Apply · ${draft.length} selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result == null) return;
    setState(() {
      _selectedGenreIds
        ..clear()
        ..addAll(result);
      _page = 1;
    });
    _applySort();
  }

  Widget _sheetChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Ionicons.checkmark, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genreDropdownButton() {
    final count = _selectedGenreIds.length;
    final active = count > 0;
    final label = active
        ? (count == 1
            ? _availableGenres
                .firstWhere(
                  (g) => g.id == _selectedGenreIds.first,
                  orElse: () => Genre(id: '', name: 'Genre'),
                )
                .name
            : '$count genres')
        : 'All genres';

    return Material(
      color: active
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _availableGenres.isEmpty ? null : _openGenreSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Ionicons.filter,
                size: 14,
                color: active ? AppColors.primary : AppColors.textSubtle,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: active ? AppColors.primary : AppColors.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Ionicons.chevron_down,
                size: 14,
                color: active ? AppColors.primary : AppColors.textSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _genreDropdownButton(),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    _sortBtn('Latest', 'latest'),
                    _sortBtn('Popular', 'views'),
                    _sortBtn('A-Z', 'A-Z'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
              children: [
                TextSpan(
                  text: '$_filteredCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const TextSpan(text: ' mangas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortBtn(String label, String key) {
    final active = _sortBy == key;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = key);
        _applySort();
      },
      child: Container(
        color: active ? AppColors.primary : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSubtle,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_displayed.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Text('No mangas found.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim, fontSize: 15)),
      );
    }

    final hasMore = _displayed.length < _filteredCount;
    return GridView.builder(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
      itemCount: _displayed.length + (hasMore ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.52,
      ),
      itemBuilder: (context, i) {
        if (i >= _displayed.length) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2));
        }
        return _card(_displayed[i]);
      },
    );
  }

  Widget _card(Story item) {
    return GestureDetector(
      onTap: () {
        if (item.id.isNotEmpty) {
          Navigator.pushNamed(context, '${AppRoutes.story}/${item.id}');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1 / 1.4,
            child: NetImage(
              url: item.thumbnail,
              radius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textBright,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          if (item.latestChapter != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context,
                    '${AppRoutes.chapter}/${item.latestChapter!.id}'),
                child: Text(
                  'Latest: Chapter ${item.latestChapter!.chapterNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
