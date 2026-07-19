import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../data/repositories/genre_repository.dart';
import '../../../../domain/entities/genre.dart';
import '../../../../domain/entities/story.dart';

class AdminStoryFormScreen extends StatefulWidget {
  final Story? story;
  const AdminStoryFormScreen({super.key, this.story});

  @override
  State<AdminStoryFormScreen> createState() => _AdminStoryFormScreenState();
}

class _AdminStoryFormScreenState extends State<AdminStoryFormScreen> {
  final _adminRepo = AdminRepository.instance;
  final _genreRepo = GenreRepository.instance;
  final _formKey = GlobalKey<FormState>();

  late bool _isEditing;

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = 'Ongoing';
  List<Genre> _availableGenres = [];
  final Set<String> _selectedGenreIds = <String>{};
  bool _loadingGenres = true;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.story != null;
    if (_isEditing) {
      final story = widget.story!;
      _titleController.text = story.title;
      _authorController.text = story.author ?? '';
      _thumbnailController.text = _stripProxy(story.thumbnail);
      _descriptionController.text = story.description ?? '';
      _selectedGenreIds.addAll(story.genres.map((g) => g.id));
      _status = (story.status == 'Complete') ? 'Complete' : 'Ongoing';
    }
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _genreRepo.fetchGenres();
      if (!mounted) return;
      setState(() {
        _availableGenres = genres;
        _loadingGenres = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGenres = false);
    }
  }

  String _stripProxy(String? url) {
    if (url == null || url.isEmpty) return '';
    const prefix = 'https://wsrv.nl/?url=';
    return url.startsWith(prefix) ? url.substring(prefix.length) : url;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _thumbnailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim().isEmpty
            ? 'Đang cập nhật'
            : _authorController.text.trim(),
        'thumbnail': _thumbnailController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? 'Đang cập nhật...'
            : _descriptionController.text.trim(),
        'genres': _selectedGenreIds.toList(),
        'status': _status,
      };

      if (_isEditing) {
        final storyId = widget.story?.id;

        if (storyId == null || storyId.isEmpty) {
          throw Exception('Không tìm thấy ID truyện');
        }

        await _adminRepo.updateStory(storyId, payload);

        if (!mounted) return;
        _snack('Cập nhật truyện thành công!');
      } else {
        await _adminRepo.createStory(payload);

        if (!mounted) return;
        _snack('Tạo truyện mới thành công!');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      final message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiException: ', '');

      _snack('Lỗi: $message');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
        title: Text(
          _isEditing ? 'Sửa Truyện' : 'Thêm Truyện',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Thông Tin Truyện'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                labelText: 'Tên truyện',
                icon: Ionicons.book_outline,
                validator: (val) {
                  if ((val?.trim() ?? '').isEmpty) {
                    return 'Tên truyện là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _authorController,
                labelText: 'Tác giả',
                icon: Ionicons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _thumbnailController,
                labelText: 'URL ảnh bìa',
                icon: Ionicons.image_outline,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              _buildGenrePicker(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                labelText: 'Mô tả',
                icon: Ionicons.document_text_outline,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Trạng Thái'),
              const SizedBox(height: 12),
              _buildStatusSelector(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? AppColors.card : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        style: TextStyle(
          color: enabled ? Colors.white : AppColors.textSubtle,
          fontSize: 16,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: labelText,
          labelStyle: const TextStyle(
            color: AppColors.textSubtle,
            fontSize: 14,
          ),
          icon: Icon(icon, color: AppColors.textSubtle, size: 20),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildGenrePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Ionicons.pricetags_outline,
                color: AppColors.textSubtle,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Thể loại',
                style: TextStyle(color: AppColors.textSubtle, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingGenres)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_availableGenres.isEmpty)
            const Text(
              'Chưa có thể loại nào. Hãy tạo thể loại trước.',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableGenres.map((g) {
                final selected = _selectedGenreIds.contains(g.id);
                return FilterChip(
                  label: Text(g.name),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedGenreIds.add(g.id);
                      } else {
                        _selectedGenreIds.remove(g.id);
                      }
                    });
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSubtle,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: _status,
        dropdownColor: AppColors.card,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'Trạng thái',
          labelStyle: TextStyle(color: AppColors.textSubtle, fontSize: 14),
          icon: Icon(
            Ionicons.flag_outline,
            color: AppColors.textSubtle,
            size: 20,
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'Ongoing', child: Text('Đang tiến hành')),
          DropdownMenuItem(value: 'Complete', child: Text('Hoàn thành')),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _status = val);
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'LƯU THAY ĐỔI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
