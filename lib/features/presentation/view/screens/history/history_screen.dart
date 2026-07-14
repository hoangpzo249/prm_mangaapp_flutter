import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/formatters.dart';
import '../../../../application/services/storage_service.dart';
import '../../../../data/repositories/history_repository.dart';
import '../../../../domain/entities/history_item.dart';
import '../../widgets/net_image.dart';
import '../main_tabs.dart';

class HistoryScreen extends StatefulWidget {
  final ValueListenable<int>? refreshTrigger;
  const HistoryScreen({super.key, this.refreshTrigger});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _history = HistoryRepository.instance;
  final _storage = StorageService.instance;

  List<HistoryItem> _items = [];
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger?.addListener(_onRefreshTrigger);
    _load();
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  void _onRefreshTrigger() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    final token = await _storage.getToken();
    List<HistoryItem> items;
    if (token != null) {
      _loggedIn = true;
      items = await _history.getReadingHistory();
    } else {
      _loggedIn = false;
      items = await _storage.getLocalHistory();
    }
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _confirmRemove(HistoryItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Remove from history?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${item.storyTitle ?? 'this story'}" from your reading history?',
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await _remove(item.storyId);
  }

  Future<void> _remove(String storyId) async {
    setState(
        () => _items = _items.where((h) => h.storyId != storyId).toList());
    if (_loggedIn) {
      await _history.deleteReadingHistory(storyId);
    }
    final local = await _storage.getLocalHistory();
    await _storage.setLocalHistory(
        local.where((h) => h.storyId != storyId).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.card,
                      onRefresh: _load,
                      child: _items.isEmpty
                          ? ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: _empty(),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(15, 15, 15, 30),
                              itemCount: _items.length,
                              itemBuilder: (_, i) => _card(_items[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.card, width: 1)),
      ),
      child: Column(
        children: [
          const Text('Reading History',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${_items.length} items',
              style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _card(HistoryItem item) {
    return GestureDetector(
      onTap: () {
        if (item.chapterId != null) {
          Navigator.pushNamed(
              context, '${AppRoutes.chapter}/${item.chapterId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            NetImage(
              url: item.storyThumbnail,
              width: 60,
              height: 80,
              radius: BorderRadius.circular(8),
              placeholderColor: AppColors.border,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.storyTitle ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.chapterTitle ?? 'Chapter ${item.chapterNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Read: ${Formatters.timeAgoOrEmpty(item.readAt)}',
                      style: const TextStyle(
                          color: AppColors.textSubtle, fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _confirmRemove(item),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Ionicons.trash_outline,
                    size: 20, color: AppColors.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Ionicons.time_outline, size: 60, color: AppColors.textFaint),
          const SizedBox(height: 15),
          const Text('Your reading history is empty.',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 16)),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: () => TabsScope.of(context).goToTab(1),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Browse Manga',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
