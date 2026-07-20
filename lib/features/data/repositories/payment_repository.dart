import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/entities/vip_package.dart';

class PaymentRepository {
  PaymentRepository._() : _api = ApiProvider.client;
  static final PaymentRepository instance = PaymentRepository._();

  PaymentRepository.forTesting(this._api);

  final ApiClient _api;

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
      'paymentMethod': 'VNPAY',
      'amountMoney': amountMoney,
      'amountCoins': amountCoins,
    }, auth: true);

    final data = ApiClient.decodeMap(res);
    return Transaction.fromJson(data);
  }



  // --- ADMIN ---
  Future<List<VipPackage>> getAdminPackages() async {
    final res = await _api.get('/vip/admin/packages', auth: true);
    final data = ApiClient.decodeList(res);
    return data.map((e) => VipPackage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createPackage(Map<String, dynamic> body) async {
    await _api.post('/vip/packages', body: body, auth: true);
  }

  Future<void> updatePackage(String id, Map<String, dynamic> body) async {
    await _api.put('/vip/packages/$id', body: body, auth: true);
  }

  Future<void> deletePackage(String id) async {
    await _api.delete('/vip/packages/$id', auth: true);
  }
}
