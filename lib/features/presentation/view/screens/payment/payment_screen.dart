import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../application/services/storage_service.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/entities/app_user.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _auth = AuthRepository.instance;
  final _storage = StorageService.instance;
  bool _loading = false;

  static const _benefits = [
    (Ionicons.book, 'Read latest premium chapters'),
    (Ionicons.shield_checkmark, 'No ads or interruptions'),
  ];

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      await _auth.upgradeToVip();
      final user = await _storage.getUser();
      if (user != null) {
        await _storage.setUserInfo(AppUser(
            id: user.id, username: user.username, isVip: true));
      }
      if (!mounted) return;
      _alert('Success', 'You are now a VIP member!',
          onOk: () => Navigator.pop(context));
    } catch (e) {
      _alert('Payment Failed', e.toString().replaceFirst('Exception: ', ''));
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _icon(),
                    const SizedBox(height: 20),
                    const Text('VIP Access',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textBright,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Elevate your manga reading experience with exclusive features and unlimited access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 15,
                            height: 1.47),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _priceCard(),
                    const SizedBox(height: 30),
                    _benefitsList(),
                    const Spacer(),
                    _payButton(),
                    const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.card, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Ionicons.arrow_back, size: 24, color: Colors.white),
            ),
          ),
          const Expanded(
            child: Text('Unlock Premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _icon() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: 144,
        height: 144,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.8),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            const Icon(Ionicons.diamond, size: 90, color: AppColors.gold),
          ],
        ),
      ),
    );
  }

  Widget _priceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.15),
            AppColors.goldDeep.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('MONTHLY PLAN',
              style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
              children: const [
                TextSpan(text: '\$2.00'),
                TextSpan(
                  text: ' / month',
                  style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitsList() {
    return Column(
      children: [
        for (final b in _benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(b.$1, size: 18, color: AppColors.gold),
                ),
                const SizedBox(width: 12),
                Text(b.$2,
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _payButton() {
    return GestureDetector(
      onTap: _loading ? null : _pay,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gold, AppColors.goldDeep],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldDeep.withValues(alpha: 0.4),
              offset: const Offset(0, 8),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Upgrade Now',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    SizedBox(width: 8),
                    Icon(Ionicons.arrow_forward,
                        size: 20, color: Colors.white),
                  ],
                ),
        ),
      ),
    );
  }
}
