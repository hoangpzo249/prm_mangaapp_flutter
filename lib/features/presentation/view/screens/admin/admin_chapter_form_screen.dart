import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../domain/entities/chapter.dart';

class AdminChapterFormArgs {
  final String storyId;
  final String storyTitle;
  final Chapter? chapter;

  const AdminChapterFormArgs({
    required this.storyId,
    required this.storyTitle,
    this.chapter,
  });
}

class AdminChapterFormScreen extends StatefulWidget {
  final String storyId;
  final String storyTitle;
  final Chapter? chapter;

  const AdminChapterFormScreen({
    super.key,
    required this.storyId,
    required this.storyTitle,
    this.chapter,
  });

  @override
  State<AdminChapterFormScreen> createState() => _AdminChapterFormScreenState();
}

class _AdminChapterFormScreenState extends State<AdminChapterFormScreen> {
  final _adminRepo = AdminRepository.instance;
  final _formKey = GlobalKey<FormState>();

  late bool _isEditing;

  final _chapterNumberController = TextEditingController();
  final _chapterTitleController = TextEditingController();
  final _imagesController = TextEditingController();

  bool _isVip = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.chapter != null;
    if (_isEditing) {
      final chapter = widget.chapter!;
      _chapterNumberController.text = _formatNumber(chapter.chapterNumber);
      _chapterTitleController.text = chapter.title ?? '';
      _imagesController.text = chapter.content
          .map(_stripProxy)
          .where((s) => s.isNotEmpty)
          .join('\n');
      _isVip = chapter.isVip;
    }
    _imagesController.addListener(_onImagesChanged);
  }

  void _onImagesChanged() {
    if (mounted) setState(() {});
  }

  String _formatNumber(num n) {
    if (n == n.toInt()) return n.toInt().toString();
    return n.toString();
  }

  String _stripProxy(String url) {
    const prefix = 'https://wsrv.nl/?url=';
    return url.startsWith(prefix) ? url.substring(prefix.length) : url;
  }

  @override
  void dispose() {
    _imagesController.removeListener(_onImagesChanged);
    _chapterNumberController.dispose();
    _chapterTitleController.dispose();
    _imagesController.dispose();
    super.dispose();
  }

  String _proxyUrl(String url) {
    return url.startsWith('http')
        ? 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}'
        : url;
  }

  List<String> _parseImages(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      final chapterNumber = num.parse(_chapterNumberController.text.trim());
      final title = _chapterTitleController.text.trim();
      final images = _parseImages(_imagesController.text);

      if (_isEditing) {
        final chapterId = widget.chapter?.id;

        if (chapterId == null || chapterId.isEmpty) {
          throw Exception('Không tìm thấy ID chương');
        }

        final payload = <String, dynamic>{
          'chapterNumber': chapterNumber,
          'chapterTitle': title,
          'image': images,
          'isVip': _isVip,
        };

        await _adminRepo.updateChapter(chapterId, payload);

        if (!mounted) return;
        _snack('Cập nhật chương thành công!');
      } else {
        final payload = <String, dynamic>{
          'storyId': widget.storyId,
          'chapterNumber': chapterNumber,
          'chapterTitle': title,
          'image': images,
          'isVip': _isVip,
        };

        await _adminRepo.createChapter(payload);

        if (!mounted) return;
        _snack('Tạo chương mới thành công!');
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Sửa Chương' : 'Thêm Chương',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.storyTitle,
              style: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Thông Tin Chương'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _chapterNumberController,
                labelText: 'Số chương (ví dụ: 1, 1.5)',
                icon: Ionicons.bookmark_outline,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (val) {
                  final value = val?.trim() ?? '';
                  if (value.isEmpty) return 'Số chương là bắt buộc';
                  final parsed = num.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Số chương phải > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _chapterTitleController,
                labelText: 'Tiêu đề chương (tùy chọn)',
                icon: Ionicons.text_outline,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Nội Dung'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _imagesController,
                labelText: 'URL ảnh các trang (mỗi dòng 1 URL)',
                icon: Ionicons.images_outline,
                maxLines: 10,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              _buildImagePreview(),
              const SizedBox(height: 24),
              _buildSectionTitle('Cài Đặt'),
              const SizedBox(height: 12),
              _buildVipToggle(),
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
    List<TextInputFormatter>? inputFormatters,
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
        inputFormatters: inputFormatters,
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

  Widget _buildImagePreview() {
    final urls = _parseImages(_imagesController.text);

    if (urls.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.image_outline, color: AppColors.textSubtle, size: 28),
            SizedBox(height: 6),
            Text(
              'Chưa có ảnh để xem trước',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Ionicons.eye_outline,
              size: 14,
              color: AppColors.textSubtle,
            ),
            const SizedBox(width: 6),
            Text(
              'Xem trước (${urls.length} trang)',
              style: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) => _buildImageThumb(idx + 1, urls[idx]),
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumb(int pageNumber, String rawUrl) {
    final url = _proxyUrl(rawUrl);
    return GestureDetector(
      onTap: () => _openImageDialog(pageNumber, url),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Ionicons.alert_circle_outline,
                        color: AppColors.danger,
                        size: 22,
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Lỗi tải ảnh',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$pageNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImageDialog(int pageNumber, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Ionicons.alert_circle_outline,
                          color: AppColors.danger,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Không tải được ảnh',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Trang $pageNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Ionicons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVipToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: SwitchListTile(
        title: const Text(
          'Chương VIP',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        subtitle: const Text(
          'Chỉ user có VIP mới được đọc chương này',
          style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
        ),
        value: _isVip,
        activeColor: AppColors.gold,
        inactiveThumbColor: AppColors.textSubtle,
        inactiveTrackColor: AppColors.surface,
        onChanged: (val) {
          setState(() => _isVip = val);
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
