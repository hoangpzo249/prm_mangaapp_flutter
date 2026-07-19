import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangaflutter/core/networks/api_client.dart';
import 'package:mangaflutter/features/data/repositories/admin_repository.dart';

/// Build `AdminRepository` giả với `ApiClient` được inject `MockClient` để
/// mọi HTTP call bị chặn và trả về response test-defined.
AdminRepository buildRepo(
  Future<http.Response> Function(http.Request req) handler,
) {
  final api = ApiClient(
    baseUrl: 'http://test.local/api',
    tokenProvider: () async => 'admintoken',
    httpClient: MockClient(handler),
  );
  return AdminRepository.forTesting(api);
}

/// Build `http.Response` JSON có `charset=utf-8` để `res.body` decode đúng
/// ký tự tiếng Việt (mặc định `http.Response` dùng Latin-1).
http.Response jsonRes(String body, int status) {
  return http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('AdminRepository.createStory Tests', () {
    test('Đăng truyện với payload đầy đủ thì body được serialize JSON đúng nguyên vẹn',
        () async {
      // Arrange
      http.Request? captured;
      final repo = buildRepo((req) async {
        captured = req;
        return http.Response('{}', 201);
      });
      final payload = {
        'title': 'Naruto',
        'author': 'Kishimoto',
        'thumbnail': 'http://img.com/n.jpg',
        'description': 'Ninja story',
        'genres': ['g1', 'g2'],
        'status': 'Ongoing',
      };

      // Act
      await repo.createStory(payload);

      // Assert
      expect(jsonDecode(captured!.body), payload);
    });

    test('Đăng truyện với genres và số chương thì gửi đúng kiểu dữ liệu',
        () async {
      // Arrange
      String? body;
      final repo = buildRepo((req) async {
        body = req.body;
        return http.Response('{}', 201);
      });

      // Act
      await repo.createStory({
        'title': 'One Piece',
        'genres': ['action', 'adventure'],
        'chapterCount': 1000,
        'status': 'Ongoing',
      });

      // Assert
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['title'], 'One Piece');
      expect(decoded['genres'], ['action', 'adventure']);
      expect(decoded['chapterCount'], 1000);
      expect(decoded['status'], 'Ongoing');
    });

    test('Đăng truyện thành công (backend trả 200) thì không ném exception',
        () async {
      // Arrange
      final repo = buildRepo((_) async => http.Response('{}', 200));

      // Act & Assert
      await repo.createStory({'title': 'x'});
    });

    test('Đăng truyện thành công (backend trả 201) thì không ném exception',
        () async {
      // Arrange
      final repo = buildRepo((_) async => http.Response('{}', 201));

      // Act & Assert
      await repo.createStory({'title': 'x'});
    });

    test('Đăng truyện bị backend trả 400 thì ném exception chứa message backend',
        () async {
      // Arrange
      final repo = buildRepo(
        (_) async => jsonRes('{"message":"Tiêu đề đã tồn tại"}', 400),
      );

      // Act & Assert
      expect(
        () => repo.createStory({'title': 'dup'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Tiêu đề đã tồn tại'),
          ),
        ),
      );
    });

    test('Đăng truyện bị backend trả 401 thì ném exception Unauthorized',
        () async {
      // Arrange
      final repo = buildRepo(
        (_) async => http.Response('{"message":"Unauthorized"}', 401),
      );

      // Act & Assert
      expect(
        () => repo.createStory({'title': 'x'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Unauthorized'),
          ),
        ),
      );
    });

    test('Đăng truyện bị backend trả 403 thì ném exception Forbidden', () async {
      // Arrange
      final repo = buildRepo(
        (_) async => http.Response('{"message":"Forbidden"}', 403),
      );

      // Act & Assert
      expect(
        () => repo.createStory({'title': 'x'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Forbidden'),
          ),
        ),
      );
    });

    test('Đăng truyện bị backend trả 422 validation thì ném exception Validation failed',
        () async {
      // Arrange
      final repo = buildRepo(
        (_) async => jsonRes(
          '{"message":"Validation failed","errors":['
          '{"field":"title","message":"Bắt buộc"}'
          ']}',
          422,
        ),
      );

      // Act & Assert
      expect(
        () => repo.createStory({'title': ''}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Validation failed'),
          ),
        ),
      );
    });

    test('Đăng truyện bị backend trả 5xx body rỗng thì ném exception Request failed',
        () async {
      // Arrange
      final repo = buildRepo((_) async => http.Response('{}', 500));

      // Act & Assert
      expect(
        () => repo.createStory({'title': 'x'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Request failed'),
          ),
        ),
      );
    });
  });

  group('AdminRepository.createChapter Tests', () {
    test('Đăng chapter với payload đầy đủ thì body được serialize JSON đúng nguyên vẹn',
        () async {
      // Arrange
      http.Request? captured;
      final repo = buildRepo((req) async {
        captured = req;
        return http.Response('{}', 201);
      });
      final payload = {
        'storyId': 's1',
        'chapterNumber': 5,
        'chapterTitle': 'Bí ẩn',
        'image': [
          'http://img.com/1.jpg',
          'http://img.com/2.jpg',
        ],
        'isVip': false,
      };

      // Act
      await repo.createChapter(payload);

      // Assert
      expect(jsonDecode(captured!.body), payload);
    });

    test('Đăng chapter với số thập phân (1.5) thì gửi đúng chapterNumber',
        () async {
      // Arrange
      String? body;
      final repo = buildRepo((req) async {
        body = req.body;
        return http.Response('{}', 201);
      });

      // Act
      await repo.createChapter({
        'storyId': 's1',
        'chapterNumber': 1.5,
        'chapterTitle': 'Extra',
        'image': <String>[],
        'isVip': false,
      });

      // Assert
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['chapterNumber'], 1.5);
    });

    test('Đăng chapter với 20 URL ảnh thì giữ đúng thứ tự khi gửi lên', () async {
      // Arrange
      String? body;
      final repo = buildRepo((req) async {
        body = req.body;
        return http.Response('{}', 201);
      });
      final urls = List.generate(20, (i) => 'http://img.com/page_$i.jpg');

      // Act
      await repo.createChapter({
        'storyId': 's1',
        'chapterNumber': 10,
        'image': urls,
        'isVip': false,
      });

      // Assert
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['image'], urls);
    });

    test('Đăng chapter bật VIP thì isVip = true trong body', () async {
      // Arrange
      String? body;
      final repo = buildRepo((req) async {
        body = req.body;
        return http.Response('{}', 201);
      });

      // Act
      await repo.createChapter({
        'storyId': 's1',
        'chapterNumber': 1,
        'image': ['http://img.com/1.jpg'],
        'isVip': true,
      });

      // Assert
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['isVip'], true);
    });

    test('Đăng chapter không nhập URL ảnh thì image là mảng rỗng trong body',
        () async {
      // Arrange
      String? body;
      final repo = buildRepo((req) async {
        body = req.body;
        return http.Response('{}', 201);
      });

      // Act
      await repo.createChapter({
        'storyId': 's1',
        'chapterNumber': 1,
        'chapterTitle': '',
        'image': <String>[],
        'isVip': false,
      });

      // Assert
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['image'], isEmpty);
      expect(decoded['image'], isA<List<dynamic>>());
    });

    test('Đăng chapter thành công (backend trả 200) thì không ném exception',
        () async {
      // Arrange
      final repo = buildRepo((_) async => http.Response('{}', 200));

      // Act & Assert
      await repo.createChapter({'storyId': 's1', 'chapterNumber': 1});
    });

    test('Đăng chapter thành công (backend trả 201) thì không ném exception',
        () async {
      // Arrange
      final repo = buildRepo((_) async => http.Response('{}', 201));

      // Act & Assert
      await repo.createChapter({'storyId': 's1', 'chapterNumber': 1});
    });

    test('Đăng chapter bị trùng số (backend 400) thì ném exception chứa message backend',
        () async {
      // Arrange
      final repo = buildRepo(
        (_) async => jsonRes('{"message":"Chapter số 5 đã tồn tại"}', 400),
      );

      // Act & Assert
      expect(
        () => repo.createChapter({'storyId': 's1', 'chapterNumber': 5}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Chapter số 5 đã tồn tại'),
          ),
        ),
      );
    });

    test('Đăng chapter với storyId không tồn tại (404) thì ném exception Story not found',
        () async {
      // Arrange
      final repo = buildRepo(
        (_) async => http.Response('{"message":"Story not found"}', 404),
      );

      // Act & Assert
      expect(
        () => repo.createChapter({'storyId': 'invalid', 'chapterNumber': 1}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Story not found'),
          ),
        ),
      );
    });

    test('Đăng chapter chưa đăng nhập (backend 401) thì ném exception Unauthorized',
        () async {
      // Arrange
      final repo = buildRepo(
        (_) async => http.Response('{"message":"Unauthorized"}', 401),
      );

      // Act & Assert
      expect(
        () => repo.createChapter({'storyId': 's1', 'chapterNumber': 1}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Unauthorized'),
          ),
        ),
      );
    });

    test('Đăng chapter bị backend trả 5xx body rỗng thì ném exception Request failed',
        () async {
      // Arrange
      final repo = buildRepo((_) async => http.Response('{}', 500));

      // Act & Assert
      expect(
        () => repo.createChapter({'storyId': 's1', 'chapterNumber': 1}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Request failed'),
          ),
        ),
      );
    });
  });
}
