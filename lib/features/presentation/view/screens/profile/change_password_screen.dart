import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
 
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
 
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
 
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}
 
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _auth = AuthRepository.instance;
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
 
  Future<void> _submit() async {
    if (_oldPassword.text.isEmpty ||
        _newPassword.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      _alert('Lỗi', 'Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      _alert('Lỗi', 'Mật khẩu mới nhập lại không khớp.');
      return;
    }
 
    setState(() => _loading = true);
    try {
      await _auth.changePassword(_oldPassword.text, _newPassword.text);
      if (!mounted) return;
      _alert('Thành công', 'Đổi mật khẩu thành công.', onOk: () {
        Navigator.pop(context);
      });
    } catch (e) {
      _alert('Đổi mật khẩu thất bại',
          e.toString().replaceFirst('Exception: ', ''));
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
            child: const Text('OK',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
 
  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _input(_oldPassword, 'Mật khẩu hiện tại',
                        Ionicons.lock_closed_outline),
                    const SizedBox(height: 15),
                    _input(_newPassword, 'Mật khẩu mới',
                        Ionicons.key_outline),
                    const SizedBox(height: 15),
                    _input(_confirmPassword, 'Nhập lại mật khẩu mới',
                        Ionicons.key_outline),
                    const SizedBox(height: 8),
                    const Text(
                      'Mật khẩu mới tối thiểu 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                    const SizedBox(height: 25),
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
          const Text('Đổi mật khẩu',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
 
  Widget _input(TextEditingController c, String hint, IconData icon,
      {bool obscure = true}) {
    return Container(
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
              obscureText: obscure,
              autocorrect: false,
              enableSuggestions: !obscure,
              textCapitalization: TextCapitalization.none,
              cursorColor: AppColors.primary,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textSubtle, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
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
            : const Text('Xác nhận đổi mật khẩu',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }
}