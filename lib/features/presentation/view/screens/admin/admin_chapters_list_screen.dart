import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../domain/entities/chapter.dart';
import '../../../../domain/entities/story.dart';
import 'admin_chapter_form_screen.dart';

class AdminChaptersListScreen extends StatefulWidget {
  final Story story;
  const AdminChaptersListScreen({super.key, required this.story});

  @override
  State<AdminChaptersListScreen> createState() =>
      _AdminChaptersListScreenState();
}

class _AdminChaptersListScreenState extends State<AdminChaptersListScreen> {
  final _adminRepo = AdminRepository.instance;
  final _searchController = TextEditingController();
  List<Chapter> _allChapters = [];
  List<Chapter> _filteredChapters = [];
  bool _loading = true;
  String? _error;
  bool _showHidden = false;

  @override
  void initState() {
    super.initState();
    _loadChapters();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chapters = _showHidden
          ? await _adminRepo.fetchHiddenChaptersByStory(widget.story.id)
          : await _adminRepo.fetchChaptersByStory(widget.story.id);
      chapters.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
      if (mounted) {
        setState(() {
          _allChapters = chapters;
          _filteredChapters = _applyFilter(chapters, _searchController.text);
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
    _loadChapters();
  }

  List<Chapter> _applyFilter(List<Chapter> chapters, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return chapters;
    return chapters.where((c) {
      final numberMatch = c.chapterNumber.toString().contains(q);
      final titleMatch = (c.title ?? '').toLowerCase().contains(q);
      return numberMatch || titleMatch;
    }).toList();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredChapters = _applyFilter(_allChapters, _searchController.text);
    });
  }

  Future<void> _confirmHide(Chapter chapter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Ẩn chương',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Ẩn Chương ${chapter.chapterNumber}? Người đọc sẽ không thấy '
          'chương này. Bạn có thể khôi phục trong mục "Đã ẩn".',
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
              'Ẩn',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminRepo.deleteChapter(chapter.id);
      _snack('Đã ẩn Chương ${chapter.chapterNumber}');
      _loadChapters();
    } catch (e) {
      _snack(
        'Ẩn thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  Future<void> _confirmRestore(Chapter chapter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Khôi phục chương',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Khôi phục Chương ${chapter.chapterNumber}?',
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
      await _adminRepo.restoreChapter(chapter.id);
      _snack('Đã khôi phục Chương ${chapter.chapterNumber}');
      _loadChapters();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý chương',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.story.title,
              style: const TextStyle(
                color: AppColors.textSubtle,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh, color: Colors.white),
            onPressed: _loadChapters,
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
                          onPressed: _loadChapters,
                          child: const Text('Tải lại'),
                        ),
                      ],
                    ),
                  )
                : _allChapters.isEmpty
                ? Center(
                    child: Text(
                      _showHidden
                          ? 'Không có chương nào đang ẩn'
                          : 'Truyện chưa có chương nào',
                      style: const TextStyle(color: AppColors.textSubtle),
                    ),
                  )
                : _filteredChapters.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy chương phù hợp',
                      style: TextStyle(color: AppColors.textSubtle),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredChapters.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, idx) =>
                        _buildChapterItem(_filteredChapters[idx]),
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
                  AppRoutes.adminChapterForm,
                  arguments: AdminChapterFormArgs(
                    storyId: widget.story.id,
                    storyTitle: widget.story.title,
                  ),
                );
                if (res == true) _loadChapters();
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
          hintText: 'Tìm theo số chương hoặc tiêu đề...',
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

  Widget _buildChapterItem(Chapter chapter) {
    final title = (chapter.title ?? '').trim();
    final pageCount = chapter.content.length;
    final accent = chapter.isVip ? AppColors.gold : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.card.withValues(alpha: 0.75),
          ],
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildChapterBadge(chapter, accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title.isEmpty
                                  ? 'Chương ${chapter.chapterNumber}'
                                  : 'Chương ${chapter.chapterNumber}: $title',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chapter.isVip) ...[
                            const SizedBox(width: 6),
                            _buildVipBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStatChip(
                        Ionicons.document_text_outline,
                        '$pageCount trang',
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
                  icon: Ionicons.create_outline,
                  label: 'Sửa',
                  color: AppColors.primary,
                  onTap: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.adminChapterForm,
                      arguments: AdminChapterFormArgs(
                        storyId: widget.story.id,
                        storyTitle: widget.story.title,
                        chapter: chapter,
                      ),
                    );
                    if (res == true) _loadChapters();
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
                        onTap: () => _confirmRestore(chapter),
                      )
                    : _buildActionButton(
                        icon: Ionicons.eye_off_outline,
                        label: 'Ẩn',
                        color: AppColors.danger,
                        onTap: () => _confirmHide(chapter),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterBadge(Chapter chapter, Color accent) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'CH',
            style: TextStyle(
              color: accent.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '${chapter.chapterNumber}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, AppColors.goldDeep],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.star, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'VIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
