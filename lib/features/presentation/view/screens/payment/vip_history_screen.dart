import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../domain/entities/user_subscription.dart';

class VipHistoryScreen extends StatefulWidget {
  const VipHistoryScreen({super.key});

  @override
  State<VipHistoryScreen> createState() => _VipHistoryScreenState();
}

class _VipHistoryScreenState extends State<VipHistoryScreen> {
  final _payment = PaymentRepository.instance;
  bool _loading = true;
  List<UserSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final subs = await _payment.getMySubscriptions();
      if (mounted) {
        setState(() {
          _subs = subs;
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
        title: const Text('Lịch sử gói VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _subs.isEmpty
              ? const Center(child: Text('Chưa có lịch sử đăng ký VIP', style: TextStyle(color: AppColors.textDim)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _subs.length,
                  itemBuilder: (context, index) {
                    final sub = _subs[index];
                    final name = sub.packageName;
                    final duration = sub.durationDays;
                    final price = sub.priceCoins;
                    
                    final startStr = sub.startDate != null ? DateFormat('dd/MM/yyyy').format(sub.startDate!.toLocal()) : '';
                    final endStr = sub.endDate != null ? DateFormat('dd/MM/yyyy').format(sub.endDate!.toLocal()) : '';

                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name, style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('-$price Xu', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Thời hạn: $duration ngày', style: const TextStyle(color: AppColors.textLight)),
                            const SizedBox(height: 4),
                            Text('Từ: $startStr - Đến: $endStr', style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Trạng thái: ${sub.status}', style: TextStyle(color: sub.status == 'ACTIVE' ? Colors.green : AppColors.textDim, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
