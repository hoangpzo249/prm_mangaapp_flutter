import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/vip_package.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _auth = AuthRepository.instance;
  final _payment = PaymentRepository.instance;
  
  bool _loading = true;
  AppUser? _user;
  List<VipPackage> _packages = [];

  final List<Map<String, dynamic>> _depositOptions = [
    {'coins': 50, 'money': 50000},
    {'coins': 100, 'money': 100000},
    {'coins': 200, 'money': 200000},
    {'coins': 500, 'money': 500000},
    {'coins': 1000, 'money': 1000000},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.fetchMe();
      final packages = await _payment.getPackages();
      if (mounted) {
        setState(() {
          _user = user;
          _packages = packages;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deposit(num coins, num money) async {
    setState(() => _loading = true);
    try {
      await _payment.deposit(money, coins);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Successfully topped up $coins Coins!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buyVip(VipPackage pkg) async {
    final balance = _user?.wallet?.balance ?? 0;
    if (balance < pkg.priceCoins) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Insufficient balance! Please top up more coins.'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Confirm VIP purchase', style: TextStyle(color: Colors.white)),
        content: Text('${pkg.priceCoins} Coins will be deducted to buy ${pkg.name}. Current balance: $balance Coins.', style: const TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _payment.buyVipPackage(pkg.id);
      await _loadData();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Congratulations!', style: TextStyle(color: Colors.white)),
            content: const Text('You have successfully purchased the VIP membership package!', style: TextStyle(color: AppColors.textLight)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Awesome'))],
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Ionicons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Coins & VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSubtle,
            tabs: [
              Tab(text: 'TOP UP', icon: Icon(Ionicons.cash_outline)),
              Tab(text: 'BUY VIP', icon: Icon(Ionicons.star)),
            ],
          ),
        ),
        body: _loading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildWalletBanner(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDepositTab(),
                      _buildVipTab(),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildWalletBanner() {
    final balance = _user?.wallet?.balance ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.background,
      child: Row(
        children: [
          const Icon(Ionicons.wallet_outline, color: AppColors.textLight),
          const SizedBox(width: 10),
          const Text('Current balance:', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
          const Spacer(),
          Text('${NumberFormat('#,###').format(balance)} Coins', style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDepositTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _depositOptions.length,
      itemBuilder: (context, index) {
        final opt = _depositOptions[index];
        final coins = opt['coins'];
        final money = opt['money'];

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: const Icon(Ionicons.logo_bitcoin, color: Colors.orange, size: 30),
            title: Text('$coins Coins', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: const Text('Pay via MoMo', style: TextStyle(color: AppColors.textDim)),
            trailing: ElevatedButton(
              onPressed: () => _deposit(coins, money),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('${NumberFormat('#,###').format(money)} VND'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVipTab() {
    if (_packages.isEmpty) {
      return const Center(child: Text('No VIP packages available', style: TextStyle(color: AppColors.textDim)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final pkg = _packages[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.card, Color(0xFF2A2D3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.star.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Ionicons.star, color: AppColors.star),
                    const SizedBox(width: 10),
                    Expanded(child: Text(pkg.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Duration: ${pkg.durationDays} days', style: const TextStyle(color: AppColors.textLight)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _buyVip(pkg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Buy package (${pkg.priceCoins} Coins)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
