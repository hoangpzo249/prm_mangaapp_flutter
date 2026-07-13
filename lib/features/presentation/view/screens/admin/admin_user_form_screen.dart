import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../domain/entities/app_user.dart';

class AdminUserFormScreen extends StatefulWidget {
  final AppUser? user;
  const AdminUserFormScreen({super.key, this.user});

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _adminRepo = AdminRepository.instance;
  final _formKey = GlobalKey<FormState>();

  late bool _isEditing;

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();

  // State values
  String _role = 'user';
  bool _isBanned = false;
  DateTime? _vipUntil;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.user != null;
    if (_isEditing) {
      final user = widget.user!;
      _usernameController.text = user.username;
      _emailController.text = user.email ?? '';
      _fullNameController.text = user.fullName ?? '';
      _role = user.role ?? 'user';
      _isBanned = user.isBanned;
      _vipUntil = user.vipUntil;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _extendVip(int days) async {
    final now = DateTime.now();
    final base = (_vipUntil != null && _vipUntil!.isAfter(now))
        ? _vipUntil!
        : now;
    setState(() {
      _vipUntil = base.add(Duration(days: days));
    });
    _snack('Đã cộng thêm $days ngày VIP (Chưa lưu thay đổi)');
  }

  Future<void> _clearVip() async {
    setState(() {
      _vipUntil = null;
    });
    _snack('Đã xóa thời hạn VIP (Chưa lưu thay đổi)');
  }

  Future<void> _showResetPasswordDialog() async {
    final passC = TextEditingController();
    final localKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Reset Mật Khẩu',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: localKey,
          child: TextFormField(
            controller: passC,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: AppColors.primary,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu mới (Tối thiểu 6 ký tự)',
              labelStyle: TextStyle(color: AppColors.textSubtle),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            validator: (val) {
              if (val == null || val.length < 6)
                return 'Mật khẩu phải từ 6 ký tự';
              return null;
            },
          ),
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
            onPressed: () {
              if (localKey.currentState?.validate() == true) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text(
              'Lưu',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminRepo.resetPassword(widget.user!.id!, passC.text);
        _snack('Reset mật khẩu thành công!');
      } catch (e) {
        _snack(
          'Lỗi reset mật khẩu: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
    passC.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        final userId = widget.user?.id;

        if (userId == null || userId.isEmpty) {
          throw Exception('Không tìm thấy ID người dùng');
        }

        final payload = <String, dynamic>{
          'fullName': _fullNameController.text.trim(),
          'isBanned': _isBanned,
          'vipUntil': _vipUntil?.toIso8601String(),
        };

        await _adminRepo.updateUser(userId, payload);

        if (!mounted) return;
        _snack('Cập nhật người dùng thành công!');
      } else {
        final payload = <String, dynamic>{
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'fullName': _fullNameController.text.trim(),
          'role': 'user',
          'isBanned': _isBanned,
        };

        await _adminRepo.createUser(payload);

        if (!mounted) return;
        _snack('Tạo người dùng mới thành công!');
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
    final isVip = _vipUntil != null && _vipUntil!.isAfter(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _isEditing ? 'Sửa Người Dùng' : 'Thêm Người Dùng',
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
              _buildSectionTitle('Thông Tin Cá Nhân'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _usernameController,
                labelText: 'Username',
                icon: Ionicons.person_outline,
                enabled: !_isEditing,
                validator: (val) {
                  final value = val?.trim() ?? '';
                  if (value.isEmpty) {
                    return 'Username là bắt buộc';
                  }
                  if (value.length < 3) {
                    return 'Username phải từ 3 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!_isEditing) ...[
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  icon: Ionicons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    final value = val?.trim() ?? '';

                    if (value.isEmpty) {
                      return 'Email là bắt buộc';
                    }

                    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

                    if (!emailRegex.hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Mật khẩu',
                  icon: Ionicons.lock_closed_outline,
                  obscure: true,
                  validator: (val) {
                    if (val == null || val.length < 6)
                      return 'Mật khẩu phải từ 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField(
                controller: _fullNameController,
                labelText: 'Họ tên đầy đủ',
                icon: Ionicons.card_outline,
                validator: (val) {
                  if ((val?.trim() ?? '').isEmpty) {
                    return 'Họ tên là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Vai Trò'),
              const SizedBox(height: 12),
              _buildRoleInfo(),
              const SizedBox(height: 20),
              _buildStatusToggles(),
              const SizedBox(height: 30),
              if (_isEditing) ...[
                _buildSectionTitle('Quản Lý VIP'),
                const SizedBox(height: 12),
                _buildVipSection(isVip),
                const SizedBox(height: 30),
                _buildSectionTitle('Bảo Mật'),
                const SizedBox(height: 12),
                _buildSecuritySection(),
                const SizedBox(height: 40),
              ],
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
    bool obscure = false,
    TextInputType? keyboardType,
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
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
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

  Widget _buildRoleInfo() {
    final isAdmin = _role == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isAdmin
                  ? AppColors.star.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isAdmin
                  ? Ionicons.shield_checkmark_outline
                  : Ionicons.person_outline,
              color: isAdmin ? AppColors.star : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin
                      ? 'Quản trị viên (Admin)'
                      : 'Người dùng thường (User)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vai trò chỉ hiển thị và không thể thay đổi tại đây.',
                  style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Ionicons.lock_closed_outline,
            color: AppColors.textDim,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggles() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: SwitchListTile(
        title: const Text(
          'Bị cấm (Ban)',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        subtitle: const Text(
          'Ngăn người dùng này đăng nhập vào hệ thống',
          style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
        ),
        value: _isBanned,
        activeColor: AppColors.danger,
        inactiveThumbColor: AppColors.textSubtle,
        inactiveTrackColor: AppColors.surface,
        onChanged: (val) {
          setState(() => _isBanned = val);
        },
      ),
    );
  }

  Widget _buildVipSection(bool isVip) {
    final displayDate = _vipUntil != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(_vipUntil!)
        : 'Chưa kích hoạt VIP';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Ionicons.star,
                color: isVip ? AppColors.star : AppColors.textDim,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayDate,
                  style: TextStyle(
                    color: isVip ? AppColors.star : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_vipUntil != null)
                IconButton(
                  icon: const Icon(
                    Ionicons.trash_outline,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  onPressed: _clearVip,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Gia hạn VIP:',
            style: TextStyle(color: AppColors.textSubtle, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildVipButton('+30 Ngày', 30)),
              const SizedBox(width: 8),
              Expanded(child: _buildVipButton('+90 Ngày', 90)),
              const SizedBox(width: 8),
              Expanded(child: _buildVipButton('+1 Năm', 365)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVipButton(String label, int days) {
    return OutlinedButton(
      onPressed: () => _extendVip(days),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mật Khẩu Đăng Nhập',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Reset mật khẩu mới cho user này',
                style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _showResetPasswordDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
