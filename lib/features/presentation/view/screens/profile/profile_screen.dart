import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/entities/app_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthRepository.instance;
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final localData = await _auth.getUserData();
    if (!mounted) return;
    if (localData == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    setState(() {
      _user = localData;
      _loading = false;
    });

    try {
      final latest = await _auth.fetchMe();
      if (mounted) setState(() => _user = latest);
    } catch (_) {}
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Confirm', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _auth.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (r) => false,
                );
              }
            },
            child: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _avatar(),
                    _walletSection(),
                    _menu(),
                    _logoutButton(),
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
              padding: EdgeInsets.all(5),
              child: Icon(Ionicons.arrow_back, size: 24, color: Colors.white),
            ),
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _avatar() {
    final displayName = _user?.fullName?.isNotEmpty == true
        ? _user!.fullName!
        : (_user?.username ?? 'U');
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (_user?.isVip == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.star),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Ionicons.star, size: 12, color: AppColors.star),
                  Text(
                    _user?.vipUntil != null
                        ? ' VIP (Until ${DateFormat('dd/MM/yyyy').format(_user!.vipUntil!)})'
                        : ' VIP',
                    style: const TextStyle(
                      color: AppColors.star,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _walletSection() {
    final balance = _user?.wallet?.balance ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Ionicons.cash_outline, color: Colors.orange),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coin balance',
                style: TextStyle(color: AppColors.textLight, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${NumberFormat('#,###').format(balance)} Coins',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.payment);
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Top up / Buy VIP',
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

  Widget _menu() {
    final isAdmin = _user?.role == 'admin';
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isAdmin)
            _menuItem(
              Ionicons.settings_outline,
              'Trang quản trị (Admin Dashboard)',
              () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
              border: true,
            ),
          _menuItem(
            Ionicons.bookmark_outline,
            'Tủ truyện (Đang theo dõi)',
            () => Navigator.pushNamed(context, AppRoutes.bookmarks),
            border: true,
          ),
          _menuItem(Ionicons.time_outline, 'Lịch sử đọc', () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (r) => false,
              arguments: {'tab': 2},
            );
          }),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool border = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: border
              ? const Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            const Icon(
              Ionicons.chevron_forward,
              size: 20,
              color: AppColors.textDim,
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.danger),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.log_out_outline, size: 20, color: AppColors.danger),
            SizedBox(width: 10),
            Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
