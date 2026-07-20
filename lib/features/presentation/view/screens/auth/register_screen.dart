import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_exceptions.dart';
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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Per-field inline error messages
  String? _fullNameError;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmError;

  /// Validate all fields locally. Returns true if all pass.
  bool _validateLocally() {
    bool ok = true;

    final fullName = _fullName.text.trim();
    final email = _email.text.trim();
    final username = _username.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;

    setState(() {
      _fullNameError = fullName.isEmpty ? 'Vui lòng nhập họ tên' : null;
      _emailError = email.isEmpty
          ? 'Vui lòng nhập email'
          : !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)
              ? 'Email không đúng định dạng'
              : null;
      _usernameError = username.isEmpty
          ? 'Vui lòng nhập username'
          : !RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)
              ? 'Username 3-20 ký tự, chỉ gồm chữ, số và dấu _'
              : null;
      _passwordError = password.isEmpty
          ? 'Vui lòng nhập mật khẩu'
          : !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,72}$')
                  .hasMatch(password)
              ? 'Tối thiểu 8 ký tự, gồm hoa, thường, số và ký tự đặc biệt'
              : null;
      _confirmError = confirm.isEmpty
          ? 'Vui lòng xác nhận mật khẩu'
          : confirm != password
              ? 'Mật khẩu xác nhận không khớp'
              : null;
    });

    if (_fullNameError != null ||
        _emailError != null ||
        _usernameError != null ||
        _passwordError != null ||
        _confirmError != null) {
      ok = false;
    }

    return ok;
  }

  Future<void> _register() async {
    if (!_validateLocally()) return;

    setState(() => _loading = true);
    try {
      await _auth.register(
        _username.text.trim(),
        _email.text.trim(),
        _password.text,
        _fullName.text.trim(),
      );
      if (!mounted) return;
      _alert('Thành công', 'Đăng ký thành công! Vui lòng đăng nhập.',
          onOk: () => Navigator.pushReplacementNamed(context, AppRoutes.login));
    } on ApiException catch (e) {
      // Show per-field errors from backend if available
      if (e.fieldErrors.isNotEmpty) {
        setState(() {
          _fullNameError = e.fieldErrors['fullName'] ?? _fullNameError;
          _emailError = e.fieldErrors['email'] ?? _emailError;
          _usernameError = e.fieldErrors['username'] ?? _usernameError;
          _passwordError = e.fieldErrors['password'] ?? _passwordError;
        });
      } else {
        // Fallback: show generic error
        _alert('Đăng ký thất bại', e.message);
      }
    } catch (e) {
      _alert('Đăng ký thất bại', e.toString().replaceFirst('Exception: ', ''));
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
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    const Logo(fontSize: 28, align: TextAlign.center),
                    const SizedBox(height: 32),
                    _input(_fullName, 'Họ và tên', Ionicons.person_circle_outline,
                        errorText: _fullNameError,
                        onChanged: (_) => setState(() => _fullNameError = null)),
                    _input(_email, 'Email', Ionicons.mail_outline,
                        errorText: _emailError,
                        onChanged: (_) => setState(() => _emailError = null)),
                    _input(_username, 'Username', Ionicons.person_outline,
                        errorText: _usernameError,
                        onChanged: (_) => setState(() => _usernameError = null)),
                    _passwordInput(
                      controller: _password,
                      hint: 'Mật khẩu',
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      errorText: _passwordError,
                      onChanged: (_) => setState(() => _passwordError = null),
                    ),
                    _passwordInput(
                      controller: _confirm,
                      hint: 'Xác nhận mật khẩu',
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      errorText: _confirmError,
                      onChanged: (_) => setState(() => _confirmError = null),
                    ),
                    const SizedBox(height: 20),
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
          const Text('Tạo tài khoản',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String hint,
    IconData icon, {
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: hasError
                  ? Border.all(color: Colors.redAccent, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: hasError ? Colors.redAccent : AppColors.textSubtle),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: c,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: onChanged,
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
          ),
          if (hasError) _errorText(errorText),
          if (!hasError) const SizedBox(height: 11),
        ],
      ),
    );
  }

  Widget _passwordInput({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: hasError
                  ? Border.all(color: Colors.redAccent, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(Ionicons.lock_closed_outline,
                    size: 20,
                    color: hasError ? Colors.redAccent : AppColors.textSubtle),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: onChanged,
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
                GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    obscure ? Ionicons.eye_off_outline : Ionicons.eye_outline,
                    size: 20,
                    color: hasError ? Colors.redAccent : AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          if (hasError) _errorText(errorText),
          if (!hasError) const SizedBox(height: 11),
        ],
      ),
    );
  }

  Widget _errorText(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 4, bottom: 6),
      child: Row(
        children: [
          const Icon(Ionicons.alert_circle_outline,
              size: 13, color: Colors.redAccent),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
