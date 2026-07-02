import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/story_repository.dart';
import '../../../../domain/entities/story.dart';
import '../../widgets/net_image.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialSort;
  const ExploreScreen({super.key, this.initialSort});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _stories = StoryRepository.instance;
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  static const int itemsPerPage = 20;

  List<Story> _all = [];
  List<Story> _displayed = [];
  bool _loading = true;
  String _query = '';
  int _page = 1;
  late String _sortBy = widget.initialSort == 'latest' ? 'latest' : 'views';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSort != null &&
        widget.initialSort != oldWidget.initialSort) {
      setState(
          () => _sortBy = widget.initialSort == 'latest' ? 'latest' : 'views');
      _applySort();
    }
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

  void _applySort() {
    final sorted = [..._all];
    sorted.sort((a, b) {
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
    setState(() => _displayed = sorted.take(_page * itemsPerPage).toList());
  }

  void _loadMore() {
    if (_displayed.length < _all.length) {
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

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(color: AppColors.textSubtle, fontSize: 14),
              children: [
                TextSpan(
                  text: '${_all.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const TextSpan(text: ' mangas'),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(15),
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

    final hasMore = _displayed.length < _all.length;
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
