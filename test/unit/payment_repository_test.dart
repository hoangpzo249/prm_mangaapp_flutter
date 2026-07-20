import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mangaflutter/core/networks/api_client.dart';
import 'package:mangaflutter/features/data/repositories/payment_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late PaymentRepository paymentRepository;
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
    paymentRepository = PaymentRepository.forTesting(mockApi);
  });

  group('PaymentRepository VIP Packages Tests', () {
    test('Tạo gói VIP thành công', () async {
      // Arrange
      final newPackage = {
        'name': 'Gói VIP 1 Tháng',
        'priceCoins': 100,
        'durationDays': 30,
      };

      when(() => mockApi.post(any(), body: any(named: 'body'), auth: any(named: 'auth')))
          .thenAnswer((_) async => http.Response(jsonEncode({'message': 'Created successfully'}), 201));

      // Act
      await paymentRepository.createPackage(newPackage);

      // Assert
      verify(() => mockApi.post(
        '/vip/packages',
        body: newPackage,
        auth: true,
      )).called(1);
    });

    test('Chỉnh sửa gói VIP thành công', () async {
      // Arrange
      const packageId = 'pkg-123';
      final updatedData = {
        'name': 'Gói VIP 1 Tháng (Update)',
        'priceCoins': 120,
        'durationDays': 30,
      };

      when(() => mockApi.put(any(), body: any(named: 'body'), auth: any(named: 'auth')))
          .thenAnswer((_) async => http.Response(jsonEncode({'message': 'Updated successfully'}), 200));

      // Act
      await paymentRepository.updatePackage(packageId, updatedData);

      // Assert
      verify(() => mockApi.put(
        '/vip/packages/$packageId',
        body: updatedData,
        auth: true,
      )).called(1);
    });
    
    test('Xóa gói VIP thành công', () async {
      // Arrange
      const packageId = 'pkg-123';

      when(() => mockApi.delete(any(), auth: any(named: 'auth')))
          .thenAnswer((_) async => http.Response(jsonEncode({'message': 'Deleted successfully'}), 200));

      // Act
      await paymentRepository.deletePackage(packageId);

      // Assert
      verify(() => mockApi.delete(
        '/vip/packages/$packageId',
        auth: true,
      )).called(1);
    });
  });
}
