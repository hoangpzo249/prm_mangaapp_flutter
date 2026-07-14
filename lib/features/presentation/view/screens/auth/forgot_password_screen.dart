import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _auth = AuthRepository.instance;
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _isOtpSent = false;

  Future<void> _sendOtp() async {
    if (_email.text.trim().isEmpty) {
      _alert('Lỗi', 'Vui lòng nhập email.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.forgotPassword(_email.text.trim());
      if (!mounted) return;
      setState(() => _isOtpSent = true);
      _alert('Thành công', 'Mã OTP đã được gửi đến email của bạn.');
    } catch (e) {
      _alert('Lỗi', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_otp.text.trim().isEmpty || _newPassword.text.isEmpty || _confirmPassword.text.isEmpty) {
      _alert('Lỗi', 'Vui lòng nhập đầy đủ OTP và mật khẩu mới.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      _alert('Lỗi', 'Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.resetPassword(_email.text.trim(), _otp.text.trim(), _newPassword.text);
      if (!mounted) return;
      _alert('Thành công', 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.',
          onOk: () => Navigator.pop(context));
    } catch (e) {
      _alert('Lỗi', e.toString().replaceFirst('Exception: ', ''));
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
    _email.dispose();
    _otp.dispose();
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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Ionicons.lock_closed, size: 80, color: AppColors.primary),
                      const SizedBox(height: 20),
                      const Text(
                        'Lấy lại mật khẩu',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Nhập email của bạn để nhận mã OTP',
                        style: TextStyle(color: AppColors.textSubtle, fontSize: 14),
                      ),
                      const SizedBox(height: 40),
                      
                      _input(_email, 'Email', Ionicons.mail_outline, enabled: !_isOtpSent),
                      
                      if (_isOtpSent) ...[
                        const SizedBox(height: 15),
                        _input(_otp, 'Mã OTP', Ionicons.key_outline),
                        const SizedBox(height: 15),
                        _input(_newPassword, 'Mật khẩu mới', Ionicons.lock_closed_outline, obscure: true),
                        const SizedBox(height: 15),
                        _input(_confirmPassword, 'Xác nhận mật khẩu mới', Ionicons.lock_closed_outline, obscure: true),
                      ],
                      
                      const SizedBox(height: 30),
                      _button(),
                    ],
                  ),
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
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: const Icon(Ionicons.arrow_back, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon, {bool obscure = false, bool enabled = true}) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: enabled ? AppColors.card : AppColors.card.withOpacity(0.5),
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
              enabled: enabled,
              cursorColor: AppColors.primary,
              style: TextStyle(color: enabled ? Colors.white : Colors.grey, fontSize: 16),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button() {
    return GestureDetector(
      onTap: _loading ? null : (_isOtpSent ? _resetPassword : _sendOtp),
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
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(_isOtpSent ? 'Đặt lại mật khẩu' : 'Nhận mã OTP',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
