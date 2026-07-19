import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../domain/entities/story.dart';
import '../../../../../app/routers/app_router.dart';

class AdminStoriesListScreen extends StatefulWidget {
  const AdminStoriesListScreen({super.key});

  @override
  State<AdminStoriesListScreen> createState() => _AdminStoriesListScreenState();
}

class _AdminStoriesListScreenState extends State<AdminStoriesListScreen> {
  final _adminRepo = AdminRepository.instance;
  List<Story> _allStories = [];
  List<Story> _filteredStories = [];
  bool _loading = true;
  String? _error;
  bool _showHidden = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stories = _showHidden
          ? await _adminRepo.fetchHiddenStories()
          : await _adminRepo.fetchStories();
      if (mounted) {
        setState(() {
          _allStories = stories;
          _filteredStories = _applyFilter(stories, _searchController.text);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _toggleShowHidden(bool showHidden) {
    if (_showHidden == showHidden) return;
    setState(() {
      _showHidden = showHidden;
    });
    _loadStories();
  }

  List<Story> _applyFilter(List<Story> stories, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return stories;
    return stories.where((s) {
      final titleMatch = s.title.toLowerCase().contains(q);
      final authorMatch = (s.author ?? '').toLowerCase().contains(q);
      return titleMatch || authorMatch;
    }).toList();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredStories = _applyFilter(_allStories, _searchController.text);
    });
  }

  Future<void> _confirmHide(Story story) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Ẩn truyện', style: TextStyle(color: Colors.white)),
        content: Text(
          'Ẩn truyện "${story.title}"? Truyện và tất cả chapter sẽ '
          'không còn hiển thị cho người đọc. Bạn có thể khôi phục lại '
          'trong mục "Đã ẩn".',
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ẩn', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminRepo.deleteStory(story.id);

      if (!mounted) return;

      _snack('Đã ẩn truyện "${story.title}"');
      await _loadStories();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      _snack('Ẩn thất bại: $message');
    }
  }

  Future<void> _confirmRestore(Story story) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Khôi phục truyện',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Khôi phục truyện "${story.title}"? Các chapter bị ẩn cùng truyện '
          'này sẽ được hiện lại. Chapter bị ẩn thủ công trước đó sẽ giữ '
          'nguyên trạng thái.',
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Khôi phục',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminRepo.restoreStory(story.id);
      _snack('Đã khôi phục truyện "${story.title}"');
      _loadStories();
    } catch (e) {
      _snack(
        'Khôi phục thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Quản lý truyện',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh, color: Colors.white),
            onPressed: _loadStories,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildVisibilityToggle(),
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lỗi: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStories,
                          child: const Text('Tải lại'),
                        ),
                      ],
                    ),
                  )
                : _filteredStories.isEmpty
                ? Center(
                    child: Text(
                      _showHidden
                          ? 'Không có truyện nào đang ẩn'
                          : 'Không tìm thấy truyện nào',
                      style: const TextStyle(color: AppColors.textSubtle),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredStories.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, idx) {
                      final story = _filteredStories[idx];
                      return _buildStoryItem(story);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _showHidden
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                final res = await Navigator.pushNamed(
                  context,
                  AppRoutes.adminStoryForm,
                );
                if (res == true) _loadStories();
              },
              child: const Icon(Ionicons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleChip(
              icon: Ionicons.eye_outline,
              label: 'Đang hiển thị',
              selected: !_showHidden,
              onTap: () => _toggleShowHidden(false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildToggleChip(
              icon: Ionicons.eye_off_outline,
              label: 'Đã ẩn',
              selected: _showHidden,
              onTap: () => _toggleShowHidden(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.textSubtle,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.card,
          hintText: 'Tìm kiếm tên truyện, tác giả...',
          hintStyle: const TextStyle(color: AppColors.textSubtle),
          prefixIcon: const Icon(Ionicons.search, color: AppColors.textSubtle),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Ionicons.close_circle,
                    color: AppColors.textSubtle,
                  ),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(Story story) {
    final isComplete = (story.status ?? '').toLowerCase() == 'complete';
    final statusColor = isComplete ? AppColors.online : AppColors.primary;
    final statusText = isComplete ? 'Hoàn thành' : 'Đang tiến hành';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.card.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(story, statusColor, statusText),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Ionicons.person_outline,
                            size: 13,
                            color: AppColors.textSubtle,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              story.author ?? 'Đang cập nhật',
                              style: const TextStyle(
                                color: AppColors.textSubtle,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildStatChip(
                        Ionicons.eye_outline,
                        _formatViews(story.views),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Ionicons.layers_outline,
                  label: 'Chương',
                  color: AppColors.gold,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.adminChapters,
                      arguments: story,
                    );
                  },
                ),
              ),
              Container(
                width: 1,
                height: 22,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildActionButton(
                  icon: Ionicons.create_outline,
                  label: 'Sửa',
                  color: AppColors.primary,
                  onTap: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.adminStoryForm,
                      arguments: story,
                    );
                    if (res == true) _loadStories();
                  },
                ),
              ),
              Container(
                width: 1,
                height: 22,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _showHidden
                    ? _buildActionButton(
                        icon: Ionicons.refresh_outline,
                        label: 'Khôi phục',
                        color: AppColors.primary,
                        onTap: () => _confirmRestore(story),
                      )
                    : _buildActionButton(
                        icon: Ionicons.eye_off_outline,
                        label: 'Ẩn',
                        color: AppColors.danger,
                        onTap: () => _confirmHide(story),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(Story story, Color statusColor, String statusText) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 74,
        height: 100,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (story.thumbnail != null && story.thumbnail!.isNotEmpty)
              Image.network(
                story.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _buildThumbFallback(Ionicons.image_outline),
              )
            else
              _buildThumbFallback(Ionicons.book_outline),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbFallback(IconData icon) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.textSubtle, size: 28),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSubtle),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatViews(num v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
