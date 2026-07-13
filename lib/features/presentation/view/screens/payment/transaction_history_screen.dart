import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../domain/entities/transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _payment = PaymentRepository.instance;
  bool _loading = true;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final txs = await _payment.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = txs;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Lịch sử giao dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _transactions.isEmpty
              ? const Center(child: Text('Chưa có giao dịch nào', style: TextStyle(color: AppColors.textDim)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final isDeposit = tx.type == 'DEPOSIT';
                    final color = isDeposit ? Colors.green : Colors.red;
                    final sign = isDeposit ? '+' : '';
                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(
                          isDeposit ? Ionicons.arrow_down_circle : Ionicons.arrow_up_circle,
                          color: color,
                          size: 32,
                        ),
                        title: Text(tx.description, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          tx.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt!.toLocal()) : '',
                          style: const TextStyle(color: AppColors.textDim),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$sign${tx.amountCoins} Xu', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(tx.status, style: TextStyle(color: _getStatusColor(tx.status), fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return AppColors.textDim;
    }
  }
}
