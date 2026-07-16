import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/entities/app_user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = AuthRepository.instance;
  final _fullName = TextEditingController();
  final _picker = ImagePicker();
  
  bool _loading = false;
  bool _uploadingAvatar = false;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _auth.getUserData();
    if (user != null) {
      setState(() {
        _user = user;
        _fullName.text = user.fullName ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    String tempUrl = '';
    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Nhập đường dẫn ảnh', style: TextStyle(color: Colors.white)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: AppColors.textSubtle),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          onChanged: (val) => tempUrl = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (submit == true && tempUrl.trim().isNotEmpty) {
      setState(() => _uploadingAvatar = true);
      try {
        final updatedUser = await _auth.updateProfile(_fullName.text, avatarUrl: tempUrl.trim());
        setState(() => _user = updatedUser);
        _alert('Thành công', 'Cập nhật ảnh đại diện thành công.');
      } catch (e) {
        _alert('Lỗi', e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _uploadingAvatar = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_fullName.text.isEmpty) {
      _alert('Lỗi', 'Vui lòng nhập họ và tên.');
      return;
    }

    setState(() => _loading = true);
    try {
      final updatedUser = await _auth.updateProfile(_fullName.text);
      if (!mounted) return;
      setState(() => _user = updatedUser);
      _alert('Thành công', 'Cập nhật thông tin thành công.', onOk: () {
        Navigator.pop(context);
      });
    } catch (e) {
      _alert('Cập nhật thất bại', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _alert(String title, String msg, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(msg, style: const TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onOk?.call();
            },
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _avatarSection(),
                    const SizedBox(height: 40),
                    _input(_fullName, 'Họ và tên', Ionicons.person_outline),
                    const SizedBox(height: 30),
                    _button(),
                  ],
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
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.card, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Icon(Ionicons.arrow_back, size: 24, color: Colors.white),
            ),
          ),
          const Text('Cập nhật thông tin',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _avatarSection() {
    final avatarUrl = _user!.avatar;
    return GestureDetector(
      onTap: _uploadingAvatar ? null : _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: _uploadingAvatar
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : (avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Ionicons.person, size: 50, color: Colors.grey),
                        )
                      : const Icon(Ionicons.person, size: 50, color: Colors.grey)),
            ),
          ),
          if (!_uploadingAvatar)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Ionicons.camera, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            hint,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSubtle),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: c,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Nhập $hint',
                    hintStyle: const TextStyle(
                        color: AppColors.textSubtle, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _button() {
    return GestureDetector(
      onTap: _loading ? null : _submit,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Lưu thay đổi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }
}
