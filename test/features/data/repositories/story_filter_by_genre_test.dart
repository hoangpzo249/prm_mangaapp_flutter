import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangaflutter/core/networks/api_client.dart';
import 'package:mangaflutter/features/data/repositories/story_repository.dart';

// ============================================================
// Helpers
// ============================================================

/// Tạo `StoryRepository` với `ApiClient` inject `MockClient`.
StoryRepository _buildRepo(
  Future<http.Response> Function(http.Request req) handler,
) {
  final api = ApiClient(
    baseUrl: 'http://test.local/api',
    tokenProvider: () async => 'test-token',
    httpClient: MockClient(handler),
  );
  return StoryRepository.forTesting(api);
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
// Mock Data
// ============================================================

/// Danh sách truyện giả lập có nhiều thể loại.
/// Backend trả `genres` dưới dạng array of string hoặc array of object
/// tùy query (populate hay không). Flutter `Story.fromJson` xử lý cả hai.
final _mockStories = [
  {
    '_id': 's1',
    'title': 'Naruto',
    'slug': 'naruto',
    'thumbnail': 'http://img.com/naruto.jpg',
    'author': 'Kishimoto',
    'status': 'Complete',
    'views': 5000,
    'chapterCount': 700,
    'genres': ['Hành động', 'Phiêu lưu'],
  },
  {
    '_id': 's2',
    'title': 'One Piece',
    'slug': 'one-piece',
    'thumbnail': 'http://img.com/op.jpg',
    'author': 'Oda',
    'status': 'Ongoing',
    'views': 10000,
    'chapterCount': 1100,
    'genres': ['Hành động', 'Hài hước'],
  },
  {
    '_id': 's3',
    'title': 'Your Name',
    'slug': 'your-name',
    'thumbnail': 'http://img.com/yn.jpg',
    'author': 'Shinkai',
    'status': 'Complete',
    'views': 3000,
    'chapterCount': 5,
    'genres': ['Tình cảm', 'Đời thường'],
  },
  {
    '_id': 's4',
    'title': 'Dragon Ball',
    'slug': 'dragon-ball',
    'thumbnail': 'http://img.com/db.jpg',
    'author': 'Toriyama',
    'status': 'Complete',
    'views': 8000,
    'chapterCount': 520,
    'genres': ['Hành động'],
  },
];

// ============================================================
// Tests
// ============================================================

void main() {
  // ── 1. Lọc truyện theo genre — Có data ────────────────────
  group('StoryFilterByGenre — Trường hợp có data', () {
    test('Tải danh sách truyện thành công và lọc client-side theo genre "Hành động"',
        () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(jsonEncode(_mockStories), 200),
      );

      // Act — tải tất cả truyện rồi lọc client-side
      final allStories = await repo.fetchStories();
      final filtered = allStories
          .where((s) => s.genres.contains('Hành động'))
          .toList();

      // Assert
      expect(allStories, hasLength(4));
      expect(filtered, hasLength(3)); // Naruto, One Piece, Dragon Ball
      expect(filtered.map((s) => s.title), containsAll(['Naruto', 'One Piece', 'Dragon Ball']));
    });

    test('Lọc theo genre "Tình cảm" chỉ trả về truyện thuộc thể loại đó',
        () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(jsonEncode(_mockStories), 200),
      );

      // Act
      final allStories = await repo.fetchStories();
      final filtered = allStories
          .where((s) => s.genres.contains('Tình cảm'))
          .toList();

      // Assert
      expect(filtered, hasLength(1));
      expect(filtered.first.title, 'Your Name');
      expect(filtered.first.genres, contains('Tình cảm'));
    });

    test('Lọc theo genre "Hài hước" chỉ trả về truyện có genre đó', () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(jsonEncode(_mockStories), 200),
      );

      // Act
      final allStories = await repo.fetchStories();
      final filtered = allStories
          .where((s) => s.genres.contains('Hài hước'))
          .toList();

      // Assert
      expect(filtered, hasLength(1));
      expect(filtered.first.title, 'One Piece');
    });

    test('Truyện có nhiều genre thì vẫn xuất hiện khi lọc theo bất kỳ genre nào',
        () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(jsonEncode(_mockStories), 200),
      );

      // Act
      final allStories = await repo.fetchStories();
      final naruto = allStories.firstWhere((s) => s.title == 'Naruto');

      // Assert — Naruto thuộc cả "Hành động" và "Phiêu lưu"
      expect(naruto.genres, contains('Hành động'));
      expect(naruto.genres, contains('Phiêu lưu'));
      expect(naruto.genres, hasLength(2));
    });
  });

  // ── 2. Lọc truyện theo genre — Không có data ─────────────
  group('StoryFilterByGenre — Trường hợp không có data', () {
    test('Lọc theo genre không tồn tại thì trả về list rỗng (không crash)',
        () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes(jsonEncode(_mockStories), 200),
      );

      // Act
      final allStories = await repo.fetchStories();
      final filtered = allStories
          .where((s) => s.genres.contains('Khoa học viễn tưởng'))
          .toList();

      // Assert
      expect(filtered, isEmpty);
    });

    test('Server trả về danh sách truyện rỗng thì filter cũng trả về rỗng',
        () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes('[]', 200),
      );

      // Act
      final allStories = await repo.fetchStories();
      final filtered = allStories
          .where((s) => s.genres.contains('Hành động'))
          .toList();

      // Assert
      expect(allStories, isEmpty);
      expect(filtered, isEmpty);
    });

    test('Truyện không có genres (mảng rỗng) thì không bị filter lọc vào',
        () async {
      // Arrange
      final storiesWithEmptyGenre = [
        {
          '_id': 's5',
          'title': 'Truyện không thể loại',
          'slug': 'truyen-khong-the-loai',
          'status': 'Ongoing',
          'views': 10,
          'chapterCount': 1,
          'genres': <String>[],
        },
        ..._mockStories,
      ];

      final repo = _buildRepo(
        (_) async => _jsonRes(jsonEncode(storiesWithEmptyGenre), 200),
      );

      // Act
      final allStories = await repo.fetchStories();
      final filtered = allStories
          .where((s) => s.genres.contains('Hành động'))
          .toList();

      // Assert — truyện không có genre sẽ không nằm trong kết quả
      expect(allStories, hasLength(5));
      expect(filtered, hasLength(3));
      expect(
        filtered.every((s) => s.title != 'Truyện không thể loại'),
        isTrue,
      );
    });

    test('Server lỗi 500 thì StoryRepository trả về list rỗng (do catch bên trong)',
        () async {
      // Arrange
      final repo = _buildRepo(
        (_) async => _jsonRes('{"message":"Internal Server Error"}', 500),
      );

      // Act — StoryRepository._stories() bắt mọi exception, trả về []
      final allStories = await repo.fetchStories();

      // Assert
      expect(allStories, isEmpty);
    });
  });

  // ── 3. Parse genres — Backend trả genres dạng Object ──────
  group('StoryFilterByGenre — Parse genres khi backend populate', () {
    test('Backend trả genres dưới dạng array of objects thì parse ra tên đúng',
        () async {
      // Arrange — giả lập backend populate genres thành object
      final storiesWithGenreObjects = [
        {
          '_id': 's1',
          'title': 'Naruto',
          'slug': 'naruto',
          'status': 'Complete',
          'views': 5000,
          'chapterCount': 700,
          'genres': [
            {'_id': 'g1', 'name': 'Hành động', 'slug': 'hanh-dong'},
            {'_id': 'g2', 'name': 'Phiêu lưu', 'slug': 'phieu-luu'},
          ],
        },
      ];

      final repo = _buildRepo(
        (_) async => _jsonRes(jsonEncode(storiesWithGenreObjects), 200),
      );

      // Act
      final stories = await repo.fetchStories();

      // Assert — Story.fromJson xử lý cả Map genre (lấy 'name')
      expect(stories, hasLength(1));
      expect(stories.first.genres, ['Hành động', 'Phiêu lưu']);
    });
  });
}
