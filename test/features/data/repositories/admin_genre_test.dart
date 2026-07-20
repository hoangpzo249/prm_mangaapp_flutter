import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangaflutter/core/networks/api_client.dart';
import 'package:mangaflutter/features/data/repositories/genre_repository.dart';

// ============================================================
// Helpers
// ============================================================

/// Tạo `GenreRepository` với `ApiClient` inject `MockClient`.
GenreRepository _buildRepo(
  Future<http.Response> Function(http.Request req) handler,
) {
  final api = ApiClient(
    baseUrl: 'http://test.local/api',
    tokenProvider: () async => 'admin-token',
    httpClient: MockClient(handler),
  );
  return GenreRepository.forTesting(api);
}

/// Build `http.Response` JSON với `charset=utf-8`.
http.Response _jsonRes(String body, int status) {
  return http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

// ============================================================
// Tests
// ============================================================

void main() {
  // ── 1. Tạo thể loại (Create Genre) ───────────────────────
  group('AdminGenre — Tạo thể loại', () {
    test('Tạo thể loại thành công thì gửi đúng payload lên API', () async {
      // Arrange
      http.Request? captured;
      final repo = _buildRepo((req) async {
        captured = req;
        return _jsonRes(
          jsonEncode({
            '_id': 'genre-001',
            'name': 'Hành động',
            'slug': 'hanh-dong',
            'isActive': true,
          }),
          201,
        );
      });

      final payload = {'name': 'Hành động', 'slug': 'hanh-dong'};

      // Act
      await repo.createGenre(payload);

      // Assert — kiểm tra request gửi đúng endpoint và body
      expect(captured, isNotNull);
      expect(captured!.url.path, '/api/genres');
      expect(captured!.method, 'POST');

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['name'], 'Hành động');
      expect(body['slug'], 'hanh-dong');
    });

    test('Tạo thể loại không gửi name thì backend trả 400 và ném exception',
        () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(
          '{"message":"Tên thể loại là bắt buộc"}',
          400,
        ),
      );

      // Act & Assert
      expect(
        () => repo.createGenre({}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Tên thể loại là bắt buộc'),
          ),
        ),
      );
    });

    test('Tạo thể loại trùng tên thì backend trả 400 và ném exception',
        () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(
          '{"message":"Tên thể loại đã tồn tại"}',
          400,
        ),
      );

      // Act & Assert
      expect(
        () => repo.createGenre({'name': 'Hành động'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Tên thể loại đã tồn tại'),
          ),
        ),
      );
    });
  });

  // ── 2. Cập nhật thể loại (Update Genre) ──────────────────
  group('AdminGenre — Cập nhật thể loại', () {
    test('Cập nhật tên thể loại thành công thì gửi đúng ID và data', () async {
      // Arrange
      http.Request? captured;
      final repo = _buildRepo((req) async {
        captured = req;
        return _jsonRes(
          jsonEncode({
            '_id': 'genre-001',
            'name': 'Hành động mới',
            'slug': 'hanh-dong-moi',
            'isActive': true,
          }),
          200,
        );
      });

      final updateData = {'name': 'Hành động mới'};

      // Act
      await repo.updateGenre('genre-001', updateData);

      // Assert
      expect(captured, isNotNull);
      expect(captured!.url.path, '/api/genres/genre-001');
      expect(captured!.method, 'PUT');

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['name'], 'Hành động mới');
    });

    test('Cập nhật trạng thái isActive thì gửi đúng giá trị boolean',
        () async {
      // Arrange
      http.Request? captured;
      final repo = _buildRepo((req) async {
        captured = req;
        return _jsonRes(
          jsonEncode({
            '_id': 'genre-001',
            'name': 'Hành động',
            'slug': 'hanh-dong',
            'isActive': false,
          }),
          200,
        );
      });

      // Act
      await repo.updateGenre('genre-001', {'isActive': false});

      // Assert
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['isActive'], false);
    });

    test('Cập nhật thể loại không tồn tại (404) thì ném exception', () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(
          '{"message":"Thể loại không tồn tại"}',
          404,
        ),
      );

      // Act & Assert
      expect(
        () => repo.updateGenre('invalid-id', {'name': 'Test'}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Thể loại không tồn tại'),
          ),
        ),
      );
    });
  });

  // ── 3. Xóa thể loại (Delete Genre) ───────────────────────
  group('AdminGenre — Xóa thể loại', () {
    test('Xóa thể loại thành công thì gửi DELETE đúng ID', () async {
      // Arrange
      http.Request? captured;
      final repo = _buildRepo((req) async {
        captured = req;
        return _jsonRes(
          '{"message":"Đã xóa thể loại thành công"}',
          200,
        );
      });

      // Act
      await repo.deleteGenre('genre-001');

      // Assert
      expect(captured, isNotNull);
      expect(captured!.url.path, '/api/genres/genre-001');
      expect(captured!.method, 'DELETE');
    });

    test('Xóa thể loại không tồn tại (404) thì ném exception', () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(
          '{"message":"Thể loại không tồn tại"}',
          404,
        ),
      );

      // Act & Assert
      expect(
        () => repo.deleteGenre('invalid-id'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Thể loại không tồn tại'),
          ),
        ),
      );
    });

    test('Xóa thể loại chưa đăng nhập (401) thì ném exception', () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(
          '{"message":"Unauthorized"}',
          401,
        ),
      );

      // Act & Assert
      expect(
        () => repo.deleteGenre('genre-001'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Unauthorized'),
          ),
        ),
      );
    });
  });

  // ── 4. Lấy danh sách thể loại (Admin) ────────────────────
  group('AdminGenre — Lấy danh sách thể loại (Admin)', () {
    test('Lấy tất cả genre bao gồm inactive thì trả về đúng danh sách',
        () async {
      // Arrange
      final mockGenres = [
        {'_id': 'g1', 'name': 'Hành động', 'slug': 'hanh-dong', 'isActive': true},
        {'_id': 'g2', 'name': 'Tình cảm', 'slug': 'tinh-cam', 'isActive': true},
        {'_id': 'g3', 'name': 'Kinh dị', 'slug': 'kinh-di', 'isActive': false},
      ];

      http.Request? captured;
      final repo = _buildRepo((req) async {
        captured = req;
        return _jsonRes(jsonEncode(mockGenres), 200);
      });

      // Act
      final genres = await repo.fetchAllForAdmin();

      // Assert
      expect(captured!.url.path, '/api/genres/admin/all');
      expect(genres, hasLength(3));
      expect(genres[0]['name'], 'Hành động');
      expect(genres[2]['isActive'], false);
    });
  });

  // ── 5. Lấy danh sách thể loại (Public) ───────────────────
  group('AdminGenre — Lấy danh sách thể loại (Public)', () {
    test('Lấy genre active thì chỉ trả về các genre đang hoạt động', () async {
      // Arrange
      final mockGenres = [
        {'_id': 'g1', 'name': 'Hành động', 'slug': 'hanh-dong'},
        {'_id': 'g2', 'name': 'Tình cảm', 'slug': 'tinh-cam'},
      ];

      http.Request? captured;
      final repo = _buildRepo((req) async {
        captured = req;
        return _jsonRes(jsonEncode(mockGenres), 200);
      });

      // Act
      final genres = await repo.fetchGenres();

      // Assert
      expect(captured!.url.path, '/api/genres');
      expect(genres, hasLength(2));
      expect(genres[0].name, 'Hành động');
      expect(genres[0].slug, 'hanh-dong');
      expect(genres[1].name, 'Tình cảm');
    });

    test('Không có genre nào active thì trả về list rỗng', () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes('[]', 200),
      );

      // Act
      final genres = await repo.fetchGenres();

      // Assert
      expect(genres, isEmpty);
    });
  });
}
