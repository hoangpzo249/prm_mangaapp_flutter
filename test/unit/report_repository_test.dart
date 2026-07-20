import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:mangaflutter/core/networks/api_client.dart';
import 'package:mangaflutter/features/data/repositories/report_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

http.Response jsonResponse(
  Object? data,
  int statusCode,
) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: const {
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

void main() {
  late MockApiClient mockApi;
  late ReportRepository reportRepository;

  setUp(() {
    mockApi = MockApiClient();
    reportRepository = ReportRepository(api: mockApi);
  });

  group('ReportRepository Tests', () {
    test('reportStory gửi payload đã trim và auth=true', () async {
      // Arrange
      when(
        () => mockApi.post(
          any(),
          body: any(named: 'body'),
          auth: any(named: 'auth'),
        ),
      ).thenAnswer((_) async => jsonResponse({'message': 'ok'}, 201));

      // Act
      await reportRepository.reportStory('  story-123  ', '   Truyện có hình ảnh nhạy cảm   ');

      // Assert
      final verification = verify(
        () => mockApi.post(
          '/reports',
          body: captureAny(named: 'body'),
          auth: true,
        ),
      );

      verification.called(1);

      final body = verification.captured.single as Map<String, dynamic>;
      expect(body['targetType'], 'story');
      expect(body['targetId'], 'story-123');
      expect(body['reason'], 'Truyện có hình ảnh nhạy cảm');
    });

    test('reportComment gửi payload đã trim và auth=true', () async {
      // Arrange
      when(
        () => mockApi.post(
          any(),
          body: any(named: 'body'),
          auth: any(named: 'auth'),
        ),
      ).thenAnswer((_) async => jsonResponse({'message': 'ok'}, 200));

      // Act
      await reportRepository.reportComment(
        '  comment-123  ',
        '   Bình luận spam   ',
      );

      // Assert
      final verification = verify(
        () => mockApi.post(
          '/reports',
          body: captureAny(named: 'body'),
          auth: true,
        ),
      );

      verification.called(1);

      final body = verification.captured.single as Map<String, dynamic>;
      expect(body['targetType'], 'comment');
      expect(body['targetId'], 'comment-123');
      expect(body['reason'], 'Bình luận spam');
    });

    test('createReport với targetType rỗng hoặc thiếu dữ liệu thì ném exception', () async {
      // Act & Assert
      await expectLater(
        () => reportRepository.createReport('  ', '   ', '   '),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Target type, target ID and reason are required'),
          ),
        ),
      );
    });

    test('createReport với targetType không hợp lệ thì ném exception', () async {
      // Act & Assert
      await expectLater(
        () => reportRepository.createReport('user', 'story-123', 'spam'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid report target type'),
          ),
        ),
      );
    });

    test('createReport khi backend trả lỗi thì ném message từ backend', () async {
      // Arrange
      when(
        () => mockApi.post(
          any(),
          body: any(named: 'body'),
          auth: any(named: 'auth'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse(
          {'message': 'Bạn đã báo cáo truyện này rồi'},
          400,
        ),
      );

      // Act & Assert
      await expectLater(
        () => reportRepository.createReport('story', 'story-123', 'spam'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Bạn đã báo cáo truyện này rồi'),
          ),
        ),
      );
    });

    test('createReport với statusCode 200 không ném exception', () async {
      // Arrange
      when(
        () => mockApi.post(
          any(),
          body: any(named: 'body'),
          auth: any(named: 'auth'),
        ),
      ).thenAnswer((_) async => jsonResponse({'message': 'ok'}, 200));

      // Act & Assert
      await reportRepository.createReport('story', 'story-123', 'spam');
    });
  });
}
