import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/chapter.dart';
import '../../../../domain/entities/story.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _repo = AdminRepository.instance;

  List<AppUser> _users = [];
  List<Story> _stories = [];
  List<Chapter> _chapters = [];
  String? _selectedStoryId;
  bool _loadingUsers = true;
  bool _loadingStories = true;
  bool _loadingChapters = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadStories();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final users = await _repo.getUsers();
      if (mounted) setState(() => _users = users);
    } catch (error) {
      _show('Không thể tải user: $error');
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadStories() async {
    setState(() => _loadingStories = true);
    try {
      final stories = await _repo.getStories();
      if (!mounted) return;
      setState(() {
        _stories = stories;
        final selectedStillExists = stories.any((story) => story.id == _selectedStoryId);
        if (!selectedStillExists) {
          _selectedStoryId = stories.isEmpty ? null : stories.first.id;
          if (stories.isEmpty) _chapters = [];
        }
      });
      if (_selectedStoryId != null) await _loadChapters(_selectedStoryId!);
    } catch (error) {
      _show('Không thể tải truyện: $error');
    } finally {
      if (mounted) setState(() => _loadingStories = false);
    }
  }

  Future<void> _loadChapters(String storyId) async {
    setState(() => _loadingChapters = true);
    try {
      final chapters = await _repo.getChapters(storyId);
      if (mounted) setState(() => _chapters = chapters);
    } catch (error) {
      _show('Không thể tải chapter: $error');
    } finally {
      if (mounted) setState(() => _loadingChapters = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(content, style: const TextStyle(color: AppColors.textLight)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xác nhận', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          foregroundColor: Colors.white,
          title: const Text('Quản trị hệ thống'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSubtle,
            tabs: [
              Tab(text: 'USER'),
              Tab(text: 'TRUYỆN'),
              Tab(text: 'CHAPTER'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _usersTab(),
            _storiesTab(),
            _chaptersTab(),
          ],
        ),
      ),
    );
  }

  Widget _usersTab() {
    return Column(
      children: [
        _toolbar('Quản lý tài khoản', 'Thêm user', _showCreateUser),
        Expanded(
          child: _loadingUsers
              ? _loader()
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: _users.isEmpty
                      ? _empty('Chưa có user')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, index) => _userCard(_users[index]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _userCard(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: user.role == 'admin' ? AppColors.star : AppColors.primary,
            child: Text(user.username.isEmpty ? '?' : user.username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName?.isNotEmpty == true ? user.fullName! : user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${user.username} • ${user.email ?? 'không có email'}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                Text('${user.role ?? 'user'}${user.isBanned ? ' • BANNED' : ''}', style: TextStyle(color: user.isBanned ? AppColors.danger : AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          IconButton(onPressed: () => _showEditUser(user), icon: const Icon(Ionicons.create_outline, color: AppColors.primary)),
          IconButton(onPressed: () => _deleteUser(user), icon: const Icon(Ionicons.trash_outline, color: AppColors.danger)),
        ],
      ),
    );
  }

  Future<void> _showCreateUser() async {
    final username = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final fullName = TextEditingController();
    String role = 'user';
    bool banned = false;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Thêm user', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(username, 'Username'),
                _field(email, 'Email', keyboardType: TextInputType.emailAddress),
                _field(password, 'Mật khẩu', obscureText: true),
                _field(fullName, 'Họ tên'),
                _roleDropdown(role, (value) => setDialogState(() => role = value)),
                SwitchListTile(
                  value: banned,
                  onChanged: (value) => setDialogState(() => banned = value),
                  title: const Text('Khóa tài khoản', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
          ],
        ),
      ),
    );

    if (submitted == true) {
      try {
        await _repo.createUser(
          username: username.text,
          email: email.text,
          password: password.text,
          fullName: fullName.text,
          role: role,
          isBanned: banned,
        );
        await _loadUsers();
        _show('Đã tạo user');
      } catch (error) {
        _show('Không thể tạo user: $error');
      }
    }
    username.dispose();
    email.dispose();
    password.dispose();
    fullName.dispose();
  }

  Future<void> _showEditUser(AppUser user) async {
    final fullName = TextEditingController(text: user.fullName ?? '');
    String role = user.role ?? 'user';
    bool banned = user.isBanned;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('Sửa ${user.username}', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(fullName, 'Họ tên'),
              _roleDropdown(role, (value) => setDialogState(() => role = value)),
              SwitchListTile(
                value: banned,
                onChanged: (value) => setDialogState(() => banned = value),
                title: const Text('Khóa tài khoản', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );

    if (submitted == true && user.id != null) {
      try {
        await _repo.updateUser(user.id!, fullName: fullName.text, role: role, isBanned: banned);
        await _loadUsers();
        _show('Đã cập nhật user');
      } catch (error) {
        _show('Không thể cập nhật user: $error');
      }
    }
    fullName.dispose();
  }

  Widget _roleDropdown(String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.card,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Vai trò'),
      items: const [
        DropdownMenuItem(value: 'user', child: Text('user')),
        DropdownMenuItem(value: 'admin', child: Text('admin')),
      ],
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    if (user.id == null || !await _confirm('Xóa user?', 'Xóa tài khoản ${user.username}?')) return;
    try {
      await _repo.deleteUser(user.id!);
      await _loadUsers();
      _show('Đã xóa user');
    } catch (error) {
      _show('Không thể xóa user: $error');
    }
  }

  Widget _storiesTab() {
    return Column(
      children: [
        _toolbar('Quản lý truyện', 'Thêm truyện', () => _showStoryDialog()),
        Expanded(
          child: _loadingStories
              ? _loader()
              : RefreshIndicator(
                  onRefresh: _loadStories,
                  child: _stories.isEmpty
                      ? _empty('Chưa có truyện')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _stories.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, index) => _storyCard(_stories[index]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _storyCard(Story story) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Ionicons.book_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(story.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${story.status ?? 'Ongoing'} • ${story.views} lượt xem', style: const TextStyle(color: AppColors.textDim)),
              ],
            ),
          ),
          IconButton(onPressed: () => _showStoryDialog(story), icon: const Icon(Ionicons.create_outline, color: AppColors.primary)),
          IconButton(onPressed: () => _deleteStory(story), icon: const Icon(Ionicons.trash_outline, color: AppColors.danger)),
        ],
      ),
    );
  }

  Future<void> _showStoryDialog([Story? summary]) async {
    Story? story = summary;
    if (summary != null) {
      try {
        story = await _repo.getStory(summary.id);
      } catch (error) {
        _show('Không thể tải chi tiết truyện: $error');
        return;
      }
    }

    final title = TextEditingController(text: story?.title ?? '');
    final author = TextEditingController(text: story?.author ?? '');
    final thumbnail = TextEditingController(text: _originalImageUrl(story?.thumbnail));
    final description = TextEditingController(text: story?.description ?? '');
    final genres = TextEditingController(text: story?.genres.join(', ') ?? '');
    String status = story?.status ?? 'Ongoing';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(story == null ? 'Thêm truyện' : 'Sửa truyện', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(title, 'Tên truyện'),
                _field(author, 'Tác giả'),
                _field(thumbnail, 'URL ảnh bìa'),
                _field(description, 'Mô tả', maxLines: 3),
                _field(genres, 'Thể loại, cách nhau bằng dấu phẩy'),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                    DropdownMenuItem(value: 'Complete', child: Text('Complete')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => status = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );

    if (submitted == true) {
      final body = <String, dynamic>{
        'title': title.text.trim(),
        'author': author.text.trim(),
        'thumbnail': thumbnail.text.trim(),
        'description': description.text.trim(),
        'genres': genres.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'status': status,
      };
      try {
        if (story == null) {
          await _repo.createStory(body);
        } else {
          await _repo.updateStory(story.id, body);
        }
        await _loadStories();
        _show(story == null ? 'Đã tạo truyện' : 'Đã cập nhật truyện');
      } catch (error) {
        _show('Không thể lưu truyện: $error');
      }
    }

    title.dispose();
    author.dispose();
    thumbnail.dispose();
    description.dispose();
    genres.dispose();
  }

  Future<void> _deleteStory(Story story) async {
    if (!await _confirm('Xóa truyện?', 'Xóa ${story.title} và toàn bộ chapter của truyện?')) return;
    try {
      await _repo.deleteStory(story.id);
      await _loadStories();
      _show('Đã xóa truyện');
    } catch (error) {
      _show('Không thể xóa truyện: $error');
    }
  }

  Widget _chaptersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStoryId,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Chọn truyện'),
                  items: _stories
                      .map((story) => DropdownMenuItem(value: story.id, child: Text(story.title, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStoryId = value);
                    _loadChapters(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _selectedStoryId == null ? null : () => _showChapterDialog(),
                icon: const Icon(Ionicons.add),
                label: const Text('Thêm'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingChapters
              ? _loader()
              : RefreshIndicator(
                  onRefresh: () async {
                    if (_selectedStoryId != null) await _loadChapters(_selectedStoryId!);
                  },
                  child: _chapters.isEmpty
                      ? _empty('Truyện này chưa có chapter')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _chapters.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, index) => _chapterCard(_chapters[index]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _chapterCard(Chapter chapter) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(chapter.isVip ? Ionicons.lock_closed_outline : Ionicons.document_text_outline, color: chapter.isVip ? AppColors.star : AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chapter ${chapter.chapterNumber}${chapter.title?.isNotEmpty == true ? ': ${chapter.title}' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${chapter.content.length} ảnh${chapter.isVip ? ' • VIP' : ''}', style: const TextStyle(color: AppColors.textDim)),
              ],
            ),
          ),
          IconButton(onPressed: () => _showChapterDialog(chapter), icon: const Icon(Ionicons.create_outline, color: AppColors.primary)),
          IconButton(onPressed: () => _deleteChapter(chapter), icon: const Icon(Ionicons.trash_outline, color: AppColors.danger)),
        ],
      ),
    );
  }

  Future<void> _showChapterDialog([Chapter? chapter]) async {
    if (_selectedStoryId == null) return;
    final number = TextEditingController(text: chapter?.chapterNumber.toString() ?? '');
    final title = TextEditingController(text: chapter?.title ?? '');
    final images = TextEditingController(text: chapter?.content.map(_originalImageUrl).join('\n') ?? '');
    bool isVip = chapter?.isVip ?? false;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(chapter == null ? 'Thêm chapter' : 'Sửa chapter', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(number, 'Số chapter', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                _field(title, 'Tiêu đề'),
                _field(images, 'URL ảnh, mỗi dòng một URL', maxLines: 6),
                SwitchListTile(
                  value: isVip,
                  onChanged: (value) => setDialogState(() => isVip = value),
                  title: const Text('Chapter VIP', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );

    if (submitted == true) {
      final chapterNumber = num.tryParse(number.text.trim());
      if (chapterNumber == null || chapterNumber <= 0) {
        _show('Số chapter phải lớn hơn 0');
      } else {
        final body = <String, dynamic>{
          'chapterNumber': chapterNumber,
          'chapterTitle': title.text.trim(),
          'image': images.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'isVip': isVip,
        };
        if (chapter == null) body['storyId'] = _selectedStoryId;
        try {
          if (chapter == null) {
            await _repo.createChapter(body);
          } else {
            await _repo.updateChapter(chapter.id, body);
          }
          await _loadChapters(_selectedStoryId!);
          await _loadStories();
          _show(chapter == null ? 'Đã tạo chapter' : 'Đã cập nhật chapter');
        } catch (error) {
          _show('Không thể lưu chapter: $error');
        }
      }
    }

    number.dispose();
    title.dispose();
    images.dispose();
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    if (!await _confirm('Xóa chapter?', 'Xóa chapter ${chapter.chapterNumber}?')) return;
    try {
      await _repo.deleteChapter(chapter.id);
      if (_selectedStoryId != null) await _loadChapters(_selectedStoryId!);
      await _loadStories();
      _show('Đã xóa chapter');
    } catch (error) {
      _show('Không thể xóa chapter: $error');
    }
  }

  Widget _toolbar(String title, String buttonText, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ElevatedButton.icon(onPressed: onPressed, icon: const Icon(Ionicons.add), label: Text(buttonText)),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSubtle),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator(color: AppColors.primary));

  Widget _empty(String text) => ListView(
        children: [
          const SizedBox(height: 180),
          const Icon(Ionicons.file_tray_outline, size: 54, color: AppColors.textDim),
          const SizedBox(height: 12),
          Center(child: Text(text, style: const TextStyle(color: AppColors.textDim))),
        ],
      );

  String _originalImageUrl(String? value) {
    if (value == null) return '';
    const prefix = 'https://wsrv.nl/?url=';
    return value.startsWith(prefix) ? value.substring(prefix.length) : value;
  }
}
