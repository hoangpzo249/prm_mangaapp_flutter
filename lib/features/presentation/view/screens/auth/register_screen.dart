import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../widgets/logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthRepository.instance;
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _isOtpSent = false;

  Future<void> _register() async {
    if (_fullName.text.isEmpty ||
        _email.text.isEmpty ||
        _username.text.isEmpty ||
        _password.text.isEmpty ||
        _confirm.text.isEmpty) {
      _alert('Lỗi', 'Vui lòng điền đầy đủ thông tin.');
      return;
    }
    if (_password.text != _confirm.text) {
      _alert('Lỗi', 'Mật khẩu không khớp.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(_username.text, _email.text, _password.text, _fullName.text);
      if (!mounted) return;
      _alert('Thành công', 'Đăng ký thành công! Vui lòng đăng nhập.',
          onOk: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.login));
    } catch (e) {
      _alert(
          'Đăng ký thất bại', e.toString().replaceFirst('Exception: ', ''));
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
    _fullName.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    _otp.dispose();
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
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                    const Logo(fontSize: 28, align: TextAlign.center),
                    const SizedBox(height: 40),
                    _input(_fullName, 'Họ và tên', Ionicons.person_circle_outline),
                    const SizedBox(height: 15),
                    _input(_email, 'Địa chỉ Email', Ionicons.mail_outline),
                    const SizedBox(height: 15),
                    _input(_username, 'Tên đăng nhập', Ionicons.person_outline),
                    const SizedBox(height: 15),
                    _input(_password, 'Mật khẩu', Ionicons.lock_closed_outline,
                        obscure: true),
                    const SizedBox(height: 15),
                    _input(_confirm, 'Xác nhận mật khẩu',
                        Ionicons.lock_closed_outline,
                        obscure: true),
                    const SizedBox(height: 25),
                    _button(),
                    const SizedBox(height: 25),
                    _footer(),
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
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.home, (r) => false),
            child: const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Icon(Ionicons.arrow_back, size: 24, color: Colors.white),
            ),
          ),
          const Text('Đăng ký tài khoản',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon,
      {bool obscure = false}) {
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
      onTap: _loading ? null : _register,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.logo,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Đăng ký',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Đã có tài khoản? ',
            style: TextStyle(color: AppColors.textSubtle, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.login),
          child: const Text('Đăng nhập',
              style: TextStyle(
                  color: AppColors.logo,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
