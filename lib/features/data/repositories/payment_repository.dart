import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/vip_package.dart';

class PaymentRepository {
  PaymentRepository._();
  static final PaymentRepository instance = PaymentRepository._();

  final ApiClient _api = ApiProvider.client;

  Future<List<VipPackage>> getPackages() async {
    final res = await _api.get('/vip/packages');
    final data = ApiClient.decodeList(res);
    return data.map((e) => VipPackage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> buyVipPackage(String packageId) async {
    final res = await _api.post('/vip/buy', body: {'packageId': packageId}, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      ApiClient.decodeMap(res);
    }
  }

  Future<Transaction> deposit(num amountMoney, num amountCoins) async {
    final res = await _api.post('/transactions/deposit', body: {
      'paymentMethod': 'MOMO',
      'amountMoney': amountMoney,
      'amountCoins': amountCoins,
    }, auth: true);
    
    final data = ApiClient.decodeMap(res);
    final tx = Transaction.fromJson(data);

    // BƯỚC MOCK: Gọi callback luôn để giả lập thành công (Chỉ dùng cho dev/test)
    try {
      await _api.post('/transactions/callback/momo', body: {
        'appTransactionId': data['appTransactionId'],
        'isSuccess': true,
      });
    } catch (_) {}

    return tx;
  }
}
