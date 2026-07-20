import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../domain/entities/user_subscription.dart';

class AccountActivityScreen extends StatefulWidget {
  const AccountActivityScreen({super.key});

  @override
  State<AccountActivityScreen> createState() => _AccountActivityScreenState();
}

class _AccountActivityScreenState extends State<AccountActivityScreen> {
  final _repo = PaymentRepository.instance;
  List<Transaction> _transactions = [];
  List<UserSubscription> _subscriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await Future.wait<dynamic>([
        _repo.getTransactions(),
        _repo.getMySubscriptions(),
      ]);
      if (!mounted) return;
      setState(() {
        _transactions = result[0] as List<Transaction>;
        _subscriptions = result[1] as List<UserSubscription>;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể tải lịch sử: $error')));
      }
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
          foregroundColor: Colors.white,
          title: const Text('Giao dịch & VIP'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSubtle,
            tabs: [
              Tab(text: 'GIAO DỊCH'),
              Tab(text: 'GÓI VIP ĐÃ MUA'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  RefreshIndicator(onRefresh: _load, child: _transactionList()),
                  RefreshIndicator(onRefresh: _load, child: _subscriptionList()),
                ],
              ),
      ),
    );
  }

  Widget _transactionList() {
    if (_transactions.isEmpty) return _empty('Chưa có giao dịch');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final tx = _transactions[index];
        final success = tx.status == 'SUCCESS';
        final pending = tx.status == 'PENDING';
        final amountText = '${tx.amountCoins > 0 ? '+' : ''}${tx.amountCoins} Xu';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(
                tx.type == 'DEPOSIT'
                    ? Ionicons.cash_outline
                    : tx.type == 'REFUND_CHAPTER_HIDE'
                        ? Ionicons.return_down_back_outline
                        : Ionicons.star_outline,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.description.isEmpty ? tx.type : tx.description, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(
                      '${tx.paymentMethod}${tx.createdAt != null ? ' • ${DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt!.toLocal())}' : ''}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amountText, style: TextStyle(color: tx.amountCoins >= 0 ? AppColors.online : AppColors.star, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                    tx.status,
                    style: TextStyle(color: success ? AppColors.online : (pending ? AppColors.star : AppColors.danger), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _subscriptionList() {
    if (_subscriptions.isEmpty) return _empty('Chưa mua gói VIP nào');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final sub = _subscriptions[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sub.status == 'ACTIVE' ? AppColors.star : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Ionicons.star, color: AppColors.star),
                  const SizedBox(width: 10),
                  Expanded(child: Text(sub.packageName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
                  Text(sub.status, style: TextStyle(color: sub.status == 'ACTIVE' ? AppColors.online : AppColors.textDim)),
                ],
              ),
              const SizedBox(height: 10),
              Text('${sub.durationDays} ngày • ${sub.priceCoins} Xu', style: const TextStyle(color: AppColors.textLight)),
              if (sub.startDate != null && sub.endDate != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(sub.startDate!.toLocal())} - ${DateFormat('dd/MM/yyyy').format(sub.endDate!.toLocal())}',
                  style: const TextStyle(color: AppColors.textDim),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _empty(String text) => ListView(
        children: [
          const SizedBox(height: 180),
          const Icon(Ionicons.file_tray_outline, size: 56, color: AppColors.textDim),
          const SizedBox(height: 12),
          Center(child: Text(text, style: const TextStyle(color: AppColors.textDim))),
        ],
      );
}
