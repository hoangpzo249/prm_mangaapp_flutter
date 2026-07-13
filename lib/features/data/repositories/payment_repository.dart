import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/entities/vip_package.dart';

class PaymentRepository {
  PaymentRepository._();
  static final PaymentRepository instance = PaymentRepository._();

  final ApiClient _api = ApiProvider.client;

  Future<List<VipPackage>> getPackages() async {
    final res = await _api.get('/vip/packages');
    final data = ApiClient.decodeList(res);
    return data
        .whereType<Map<String, dynamic>>()
        .map(VipPackage.fromJson)
        .toList();
  }

  Future<void> buyVipPackage(String packageId) async {
    final res = await _api.post('/vip/buy', body: {'packageId': packageId}, auth: true);
    ApiClient.decodeMap(res);
  }

  Future<List<UserSubscription>> getMySubscriptions() async {
    final res = await _api.get('/vip/my-subscriptions', auth: true);
    return ApiClient.decodeList(res)
        .whereType<Map<String, dynamic>>()
        .map(UserSubscription.fromJson)
        .toList();
  }

  Future<List<Transaction>> getTransactions({int page = 1, int limit = 20}) async {
    final res = await _api.get('/transactions?page=$page&limit=$limit', auth: true);
    return ApiClient.decodeList(res)
        .whereType<Map<String, dynamic>>()
        .map(Transaction.fromJson)
        .toList();
  }

  Future<Transaction> deposit(num amountMoney, num amountCoins) async {
    final res = await _api.post('/transactions/deposit', body: {
      'paymentMethod': 'MOMO',
      'amountMoney': amountMoney,
      'amountCoins': amountCoins,
    }, auth: true);

    final data = ApiClient.decodeMap(res);
    final tx = Transaction.fromJson(data);

    // MOCK: fire callback immediately to simulate success (dev/test only)
    try {
      await _api.post('/transactions/callback/momo', body: {
        'appTransactionId': data['appTransactionId'],
        'gatewayTransactionId': 'DEV_${DateTime.now().millisecondsSinceEpoch}',
        'isSuccess': true,
      });
    } catch (_) {}

    return tx;
  }
}
