import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../widgets/logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthRepository.instance;
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      _alert('Error', 'Please enter your username and password.');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _auth.login(_username.text, _password.text);
      if (!mounted) return;
      if (user.role == 'admin') {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (r) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
      }
    } catch (e) {
      _alert('Login Failed', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _alert(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(msg, style: const TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    const Logo(fontSize: 28, align: TextAlign.center),
                    const SizedBox(height: 40),
                    _input(_username, 'Username', Ionicons.person_outline),
                    const SizedBox(height: 15),
                    _passwordInput(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                        child: const Text('Forgot Password?',
                            style: TextStyle(color: AppColors.primary, fontSize: 14)),
                      ),
                    ),
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
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Icon(Ionicons.arrow_back, size: 24, color: Colors.white),
            ),
          ),
          const Text('Login',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon) {
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
              autocorrect: false,
              enableSuggestions: false,
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

  Widget _passwordInput() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Ionicons.lock_closed_outline,
              size: 20, color: AppColors.textSubtle),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _password,
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              cursorColor: AppColors.primary,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Password',
                hintStyle:
                    TextStyle(color: AppColors.textSubtle, fontSize: 16),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Ionicons.eye_off_outline
                  : Ionicons.eye_outline,
              size: 20,
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _button() {
    return GestureDetector(
      onTap: _loading ? null : _login,
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
            : const Text('Login',
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
        const Text("Don't have an account? ",
            style: TextStyle(color: AppColors.textSubtle, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          child: const Text('Sign Up',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
