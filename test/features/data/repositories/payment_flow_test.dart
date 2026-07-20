import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangaflutter/core/networks/api_client.dart';
import 'package:mangaflutter/features/data/repositories/payment_repository.dart';
import 'package:mangaflutter/features/data/repositories/auth_repository.dart';
import 'package:mangaflutter/features/application/services/storage_service.dart';
import 'package:mangaflutter/features/domain/entities/app_user.dart';
import 'package:mocktail/mocktail.dart';

// ============================================================
// Helpers
// ============================================================

/// Tạo `PaymentRepository` với `ApiClient` inject `MockClient` để
/// mọi HTTP request bị chặn và trả về response test-defined.
PaymentRepository _buildPaymentRepo(
  Future<http.Response> Function(http.Request req) handler,
) {
  final api = ApiClient(
    baseUrl: 'http://test.local/api',
    tokenProvider: () async => 'test-token',
    httpClient: MockClient(handler),
  );
  return PaymentRepository.forTesting(api);
}

/// Build `http.Response` JSON với `charset=utf-8` để decode đúng
/// ký tự tiếng Việt.
http.Response _jsonRes(String body, int status) {
  return http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

class MockStorageService extends Mock implements StorageService {}
class FakeAppUser extends Fake implements AppUser {}

// ============================================================
// Tests
// ============================================================

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAppUser());
  });
  // ── 1. Xem danh sách gói khuyến mại ──────────────────────
  group('PaymentFlow — Xem danh sách gói khuyến mại', () {
    test('Tải danh sách gói thành công thì trả về đúng số lượng và nội dung',
        () async {
      // Arrange
      final mockPackages = [
        {
          '_id': 'pkg-1',
          'name': 'Gói VIP 1 Tháng',
          'durationDays': 30,
          'priceCoins': 100,
          'description': 'Truy cập VIP 30 ngày',
          'isActive': true,
        },
        {
          '_id': 'pkg-2',
          'name': 'Gói VIP 1 Năm',
          'durationDays': 365,
          'priceCoins': 1000,
          'description': 'Truy cập VIP 365 ngày',
          'isActive': true,
        },
      ];

      final repo = _buildPaymentRepo(
        (_) async => _jsonRes(jsonEncode(mockPackages), 200),
      );

      // Act
      final packages = await repo.getPackages();

      // Assert
      expect(packages, hasLength(2));
      expect(packages[0].id, 'pkg-1');
      expect(packages[0].name, 'Gói VIP 1 Tháng');
      expect(packages[0].durationDays, 30);
      expect(packages[0].priceCoins, 100);
      expect(packages[1].id, 'pkg-2');
      expect(packages[1].name, 'Gói VIP 1 Năm');
      expect(packages[1].durationDays, 365);
      expect(packages[1].priceCoins, 1000);
    });

    test('Tải danh sách gói khi server trả rỗng thì trả về list rỗng',
        () async {
      // Arrange
      final repo = _buildPaymentRepo(
        (_) async => _jsonRes('[]', 200),
      );

      // Act
      final packages = await repo.getPackages();

      // Assert
      expect(packages, isEmpty);
    });

    test('Tải danh sách gói khi server lỗi 500 thì ném exception', () async {
      // Arrange
      final repo = _buildPaymentRepo(
        (_) async => _jsonRes('{"message":"Internal Server Error"}', 500),
      );

      // Act & Assert
      expect(
        () => repo.getPackages(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── 2. Nạp tiền (Deposit) ────────────────────────────────
  group('PaymentFlow — Nạp tiền', () {
    test('Nạp tiền thành công thì trả về Transaction đúng thông tin',
        () async {
      // Arrange
      final mockTransaction = {
        '_id': 'txn-001',
        'type': 'deposit',
        'status': 'pending',
        'amountCoins': 100,
        'description': 'Nạp 100 Coins',
        'paymentUrl': 'https://vnpay.vn/pay?ref=txn-001',
      };

      http.Request? captured;
      final repo = _buildPaymentRepo((req) async {
        captured = req;
        return _jsonRes(jsonEncode(mockTransaction), 200);
      });

      // Act
      final txn = await repo.deposit(100000, 100);

      // Assert — kiểm tra response parse đúng
      expect(txn.id, 'txn-001');
      expect(txn.type, 'deposit');
      expect(txn.status, 'pending');
      expect(txn.amountCoins, 100);
      expect(txn.paymentUrl, 'https://vnpay.vn/pay?ref=txn-001');

      // Assert — kiểm tra request body gửi lên đúng
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['paymentMethod'], 'VNPAY');
      expect(body['amountMoney'], 100000);
      expect(body['amountCoins'], 100);
    });

    test('Nạp tiền thất bại (400 Bad Request) thì ném exception', () async {
      // Arrange
      final repo = _buildPaymentRepo(
        (_) async => _jsonRes(
          '{"message":"Số tiền không hợp lệ"}',
          400,
        ),
      );

      // Act & Assert
      expect(
        () => repo.deposit(0, 0),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Số tiền không hợp lệ'),
          ),
        ),
      );
    });

    test('Nạp tiền thất bại (500 Server Error) thì ném exception', () async {
      // Arrange
      final repo = _buildPaymentRepo(
        (_) async => _jsonRes('{"message":"Server Error"}', 500),
      );

      // Act & Assert
      expect(
        () => repo.deposit(100000, 100),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Server Error'),
          ),
        ),
      );
    });
  });

  // ── 3. Kiểm tra số dư ────────────────────────────────────
  group('PaymentFlow — Kiểm tra số dư', () {
    late MockStorageService mockStorage;

    setUp(() {
      mockStorage = MockStorageService();
    });

    test('Lấy thông tin user thì wallet.balance khớp số dư giả lập',
        () async {
      // Arrange
      final mockUserJson = {
        '_id': 'user-123',
        'username': 'testuser',
        'email': 'test@example.com',
        'role': 'user',
        'wallet': {
          'balance': 500,
          'isLocked': false,
        },
      };

      final api = ApiClient(
        baseUrl: 'http://test.local/api',
        tokenProvider: () async => 'test-token',
        httpClient: MockClient(
          (_) async => _jsonRes(jsonEncode(mockUserJson), 200),
        ),
      );

      when(() => mockStorage.setUserInfo(any())).thenAnswer((_) async => true);

      final authRepo = AuthRepository.test(api: api, storage: mockStorage);

      // Act
      final user = await authRepo.fetchMe();

      // Assert
      expect(user.wallet, isNotNull);
      expect(user.wallet!.balance, 500);
      expect(user.wallet!.isLocked, false);
    });

    test('User không có wallet thì wallet là null', () async {
      // Arrange
      final mockUserJson = {
        '_id': 'user-456',
        'username': 'nowalletuser',
        'email': 'nowallet@example.com',
        'role': 'user',
      };

      final api = ApiClient(
        baseUrl: 'http://test.local/api',
        tokenProvider: () async => 'test-token',
        httpClient: MockClient(
          (_) async => _jsonRes(jsonEncode(mockUserJson), 200),
        ),
      );

      when(() => mockStorage.setUserInfo(any())).thenAnswer((_) async => true);

      final authRepo = AuthRepository.test(api: api, storage: mockStorage);

      // Act
      final user = await authRepo.fetchMe();

      // Assert
      expect(user.wallet, isNull);
    });
  });

  // ── 4. Mua gói khuyến mại ────────────────────────────────
  group('PaymentFlow — Mua gói khuyến mại', () {
    test('Mua gói VIP thành công thì gửi đúng packageId lên API', () async {
      // Arrange
      http.Request? captured;
      final repo = _buildPaymentRepo((req) async {
        captured = req;
        return _jsonRes('{"message":"Mua gói thành công"}', 200);
      });

      // Act
      await repo.buyVipPackage('pkg-1');

      // Assert — kiểm tra request gọi đúng endpoint và body
      expect(captured, isNotNull);
      expect(captured!.url.path, '/api/vip/buy');
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['packageId'], 'pkg-1');
    });

    test('Mua gói VIP thất bại (không đủ số dư) thì ném exception', () async {
      // Arrange
      final repo = _buildPaymentRepo(
        (_) async => _jsonRes('{"message":"Không đủ số dư"}', 400),
      );

      // Act & Assert
      expect(
        () => repo.buyVipPackage('pkg-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Không đủ số dư'),
          ),
        ),
      );
    });

    test('Mua gói VIP thất bại (chưa đăng nhập) thì ném exception', () async {
      // Arrange
      final repo = _buildPaymentRepo(
        (_) async => _jsonRes('{"message":"Unauthorized"}', 401),
      );

      // Act & Assert
      expect(
        () => repo.buyVipPackage('pkg-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Unauthorized'),
          ),
        ),
      );
    });

    test('Mua gói VIP thất bại (gói không tồn tại) thì ném exception',
        () async {
      // Arrange
      final repo = _buildPaymentRepo(
        (_) async => _jsonRes('{"message":"Package not found"}', 404),
      );

      // Act & Assert
      expect(
        () => repo.buyVipPackage('pkg-invalid'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Package not found'),
          ),
        ),
      );
    });
  });

  // ── 5. Lịch sử giao dịch ─────────────────────────────────
  group('PaymentFlow — Lịch sử giao dịch', () {
    test('Lấy lịch sử giao dịch thành công thì trả về danh sách Transaction',
        () async {
      // Arrange
      final mockTransactions = [
        {
          '_id': 'txn-001',
          'type': 'deposit',
          'status': 'completed',
          'amountCoins': 100,
          'description': 'Nạp 100 Coins',
        },
        {
          '_id': 'txn-002',
          'type': 'purchase',
          'status': 'completed',
          'amountCoins': -50,
          'description': 'Mua gói VIP',
        },
      ];

      final repo = _buildPaymentRepo(
        (_) async => _jsonRes(jsonEncode(mockTransactions), 200),
      );

      // Act
      final transactions = await repo.getTransactions();

      // Assert
      expect(transactions, hasLength(2));
      expect(transactions[0].id, 'txn-001');
      expect(transactions[0].type, 'deposit');
      expect(transactions[1].id, 'txn-002');
      expect(transactions[1].type, 'purchase');
    });

    test('Lấy lịch sử khi không có giao dịch thì trả về list rỗng', () async {
      // Arrange
      final repo = _buildPaymentRepo(
        (_) async => _jsonRes('[]', 200),
      );

      // Act
      final transactions = await repo.getTransactions();

      // Assert
      expect(transactions, isEmpty);
    });
  });
}
