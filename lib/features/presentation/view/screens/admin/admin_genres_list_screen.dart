import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/genre_repository.dart';

class AdminGenresListScreen extends StatefulWidget {
  const AdminGenresListScreen({super.key});

  @override
  State<AdminGenresListScreen> createState() => _AdminGenresListScreenState();
}

class _AdminGenresListScreenState extends State<AdminGenresListScreen> {
  final _genreRepo = GenreRepository.instance;

  List<Map<String, dynamic>> _genres = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final genres = await _genreRepo.fetchAllForAdmin();
      if (!mounted) return;
      setState(() {
        _genres = genres;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? genre}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _GenreFormDialog(genre: genre),
    );
    if (result == true) _loadGenres();
  }

  Future<void> _confirmDelete(Map<String, dynamic> genre) async {
    final name = (genre['name'] ?? '').toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Xóa thể loại',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Xóa thể loại "$name"? Truyện đang gắn thể loại này sẽ mất tham chiếu.',
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
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _genreRepo.deleteGenre((genre['_id'] ?? '').toString());
      _snack('Đã xóa thể loại "$name"');
      _loadGenres();
    } catch (e) {
      _snack('Xóa thất bại: ${e.toString().replaceFirst('Exception: ', '')}');
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
          'Quản lý thể loại',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh, color: Colors.white),
            onPressed: _loadGenres,
          ),
        ],
      ),
      body: _loading
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
                    onPressed: _loadGenres,
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            )
          : _genres.isEmpty
          ? const Center(
              child: Text(
                'Chưa có thể loại nào',
                style: TextStyle(color: AppColors.textSubtle),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _genres.length,
              itemBuilder: (_, i) => _buildItem(_genres[i]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(),
        child: const Icon(Ionicons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> genre) {
    final name = (genre['name'] ?? '').toString();
    final slug = (genre['slug'] ?? '').toString();
    final active = genre['isActive'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Icon(
              Ionicons.pricetag_outline,
              size: 18,
              color: active ? AppColors.primary : AppColors.textSubtle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (!active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Ẩn',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  slug,
                  style: const TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Ionicons.create_outline,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () => _openForm(genre: genre),
          ),
          IconButton(
            icon: const Icon(
              Ionicons.trash_outline,
              color: AppColors.danger,
              size: 20,
            ),
            onPressed: () => _confirmDelete(genre),
          ),
        ],
      ),
    );
  }
}

class _GenreFormDialog extends StatefulWidget {
  final Map<String, dynamic>? genre;
  const _GenreFormDialog({this.genre});

  @override
  State<_GenreFormDialog> createState() => _GenreFormDialogState();
}

class _GenreFormDialogState extends State<_GenreFormDialog> {
  final _genreRepo = GenreRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.genre != null;

  @override
  void initState() {
    super.initState();
    final g = widget.genre;
    if (g != null) {
      _nameController.text = (g['name'] ?? '').toString();
      _isActive = g['isActive'] != false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'isActive': _isActive,
      };

      if (_isEditing) {
        await _genreRepo.updateGenre(
          (widget.genre!['_id'] ?? '').toString(),
          payload,
        );
      } else {
        await _genreRepo.createGenre(payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Sửa thể loại' : 'Thêm thể loại',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _nameController,
                label: 'Tên thể loại',
                icon: Ionicons.pricetag_outline,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Đang hiển thị',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: const Text(
                  'Tắt để ẩn khỏi client mà không xóa',
                  style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
                ),
                value: _isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: AppColors.textSubtle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Lưu' : 'Tạo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSubtle),
          icon: Icon(icon, color: AppColors.textSubtle, size: 18),
        ),
        validator: validator,
      ),
    );
  }
}
