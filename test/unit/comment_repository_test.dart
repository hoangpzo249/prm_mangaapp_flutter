import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:mangaflutter/core/errors/app_exceptions.dart';
import 'package:mangaflutter/core/networks/api_client.dart';
import 'package:mangaflutter/features/data/repositories/comment_repository.dart';
import 'package:mangaflutter/features/domain/entities/comment_item.dart';

class MockApiClient extends Mock implements ApiClient {}

/// Tạo HTTP response JSON với UTF-8 để hỗ trợ tiếng Việt.
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
  late CommentRepository commentRepository;

  setUp(() {
    mockApi = MockApiClient();
    commentRepository = CommentRepository(api: mockApi);
  });

  group('CommentRepository Unit Tests', () {
    final mockCommentMap = <String, dynamic>{
      '_id': 'comment-123',
      'storyId': 'story-123',
      'chapterId': null,
      'parentId': null,
      'content': 'Truyện rất hay',
      'userId': {
        '_id': 'user-123',
        'username': 'testuser',
        'fullName': 'Test User',
        'avatar': null,
      },
      'createdAt': '2026-07-20T00:00:00.000Z',
      'updatedAt': '2026-07-20T00:00:00.000Z',
      'replies': <dynamic>[],
    };

    group('getByStory', () {
      test('Lấy danh sách bình luận theo truyện thành công', () async {
        // Arrange
        final responseData = [
          mockCommentMap,
          {
            ...mockCommentMap,
            '_id': 'comment-456',
            'content': 'Mong sớm có chương mới',
          },
        ];

        when(
          () => mockApi.get(any()),
        ).thenAnswer(
          (_) async => jsonResponse(responseData, 200),
        );

        // Act
        final result = await commentRepository.getByStory('story-123');

        // Assert
        expect(result, isA<List<CommentItem>>());
        expect(result, hasLength(2));

        verify(
          () => mockApi.get(
            '/comments/story/story-123?page=1&limit=20',
          ),
        ).called(1);
      });

      test('Lấy danh sách với page và limit tùy chỉnh', () async {
        // Arrange
        when(
          () => mockApi.get(any()),
        ).thenAnswer(
          (_) async => jsonResponse([mockCommentMap], 200),
        );

        // Act
        final result = await commentRepository.getByStory(
          'story-123',
          page: 3,
          limit: 10,
        );

        // Assert
        expect(result, hasLength(1));

        verify(
          () => mockApi.get(
            '/comments/story/story-123?page=3&limit=10',
          ),
        ).called(1);
      });

      test('Không có bình luận thì trả về danh sách rỗng', () async {
        // Arrange
        when(
          () => mockApi.get(any()),
        ).thenAnswer(
          (_) async => jsonResponse([], 200),
        );

        // Act
        final result = await commentRepository.getByStory('story-123');

        // Assert
        expect(result, isEmpty);

        verify(
          () => mockApi.get(
            '/comments/story/story-123?page=1&limit=20',
          ),
        ).called(1);
      });

      test('Bỏ qua phần tử không phải Map trong response', () async {
        // Arrange
        final responseData = [
          mockCommentMap,
          'invalid-comment',
          123,
          null,
          true,
        ];

        when(
          () => mockApi.get(any()),
        ).thenAnswer(
          (_) async => jsonResponse(responseData, 200),
        );

        // Act
        final result = await commentRepository.getByStory('story-123');

        // Assert
        expect(result, hasLength(1));
        expect(result.first, isA<CommentItem>());
      });

      test('Lấy danh sách thất bại thì ném ApiException', () async {
        // Arrange
        when(
          () => mockApi.get(any()),
        ).thenAnswer(
          (_) async => jsonResponse(
            {
              'message': 'Không thể lấy danh sách bình luận',
            },
            500,
          ),
        );

        // Act & Assert
        await expectLater(
          commentRepository.getByStory('story-123'),
          throwsA(isA<ApiException>()),
        );

        verify(
          () => mockApi.get(
            '/comments/story/story-123?page=1&limit=20',
          ),
        ).called(1);
      });
    });

    group('create', () {
      test('Tạo bình luận thành công và trim nội dung', () async {
        // Arrange
        when(
          () => mockApi.post(
            any(),
            body: any(named: 'body'),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(mockCommentMap, 201),
        );

        // Act
        final result = await commentRepository.create(
          storyId: 'story-123',
          content: '   Truyện rất hay   ',
        );

        // Assert
        expect(result, isA<CommentItem>());

        final verification = verify(
          () => mockApi.post(
            '/comments',
            body: captureAny(named: 'body'),
            auth: true,
          ),
        );

        verification.called(1);

        final capturedBody =
            verification.captured.single as Map<String, dynamic>;

        expect(capturedBody['storyId'], 'story-123');
        expect(capturedBody['content'], 'Truyện rất hay');
        expect(capturedBody.containsKey('chapterId'), isFalse);
        expect(capturedBody.containsKey('parentId'), isFalse);
      });

      test('Tạo bình luận chương truyện thì gửi chapterId', () async {
        // Arrange
        final responseData = {
          ...mockCommentMap,
          'chapterId': 'chapter-123',
          'content': 'Bình luận chương truyện',
        };

        when(
          () => mockApi.post(
            any(),
            body: any(named: 'body'),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(responseData, 201),
        );

        // Act
        final result = await commentRepository.create(
          storyId: 'story-123',
          content: 'Bình luận chương truyện',
          chapterId: 'chapter-123',
        );

        // Assert
        expect(result, isA<CommentItem>());

        final verification = verify(
          () => mockApi.post(
            '/comments',
            body: captureAny(named: 'body'),
            auth: true,
          ),
        );

        verification.called(1);

        final capturedBody =
            verification.captured.single as Map<String, dynamic>;

        expect(capturedBody['storyId'], 'story-123');
        expect(capturedBody['content'], 'Bình luận chương truyện');
        expect(capturedBody['chapterId'], 'chapter-123');
        expect(capturedBody.containsKey('parentId'), isFalse);
      });

      test('Tạo reply thì gửi parentId', () async {
        // Arrange
        final responseData = {
          ...mockCommentMap,
          '_id': 'reply-123',
          'parentId': 'comment-parent-123',
          'content': 'Nội dung trả lời',
        };

        when(
          () => mockApi.post(
            any(),
            body: any(named: 'body'),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(responseData, 201),
        );

        // Act
        final result = await commentRepository.create(
          storyId: 'story-123',
          content: 'Nội dung trả lời',
          parentId: 'comment-parent-123',
        );

        // Assert
        expect(result, isA<CommentItem>());

        final verification = verify(
          () => mockApi.post(
            '/comments',
            body: captureAny(named: 'body'),
            auth: true,
          ),
        );

        verification.called(1);

        final capturedBody =
            verification.captured.single as Map<String, dynamic>;

        expect(capturedBody['storyId'], 'story-123');
        expect(capturedBody['content'], 'Nội dung trả lời');
        expect(capturedBody['parentId'], 'comment-parent-123');
        expect(capturedBody.containsKey('chapterId'), isFalse);
      });

      test('Tạo reply trong chapter thì gửi chapterId và parentId', () async {
        // Arrange
        final responseData = {
          ...mockCommentMap,
          '_id': 'reply-456',
          'chapterId': 'chapter-123',
          'parentId': 'comment-parent-123',
          'content': 'Trả lời bình luận',
        };

        when(
          () => mockApi.post(
            any(),
            body: any(named: 'body'),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(responseData, 201),
        );

        // Act
        final result = await commentRepository.create(
          storyId: 'story-123',
          content: 'Trả lời bình luận',
          chapterId: 'chapter-123',
          parentId: 'comment-parent-123',
        );

        // Assert
        expect(result, isA<CommentItem>());

        final verification = verify(
          () => mockApi.post(
            '/comments',
            body: captureAny(named: 'body'),
            auth: true,
          ),
        );

        verification.called(1);

        final capturedBody =
            verification.captured.single as Map<String, dynamic>;

        expect(capturedBody['storyId'], 'story-123');
        expect(capturedBody['content'], 'Trả lời bình luận');
        expect(capturedBody['chapterId'], 'chapter-123');
        expect(capturedBody['parentId'], 'comment-parent-123');
      });

      test('Không gửi chapterId và parentId khi là chuỗi rỗng', () async {
        // Arrange
        when(
          () => mockApi.post(
            any(),
            body: any(named: 'body'),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(mockCommentMap, 201),
        );

        // Act
        await commentRepository.create(
          storyId: 'story-123',
          content: 'Comment test',
          chapterId: '',
          parentId: '',
        );

        // Assert
        final verification = verify(
          () => mockApi.post(
            '/comments',
            body: captureAny(named: 'body'),
            auth: true,
          ),
        );

        verification.called(1);

        final capturedBody =
            verification.captured.single as Map<String, dynamic>;

        expect(capturedBody['storyId'], 'story-123');
        expect(capturedBody['content'], 'Comment test');
        expect(capturedBody.containsKey('chapterId'), isFalse);
        expect(capturedBody.containsKey('parentId'), isFalse);
      });

      test('Tạo bình luận thất bại thì ném ApiException', () async {
        // Arrange
        when(
          () => mockApi.post(
            any(),
            body: any(named: 'body'),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(
            {
              'message': 'Bạn cần đăng nhập để bình luận',
            },
            401,
          ),
        );

        // Act & Assert
        await expectLater(
          commentRepository.create(
            storyId: 'story-123',
            content: 'Comment test',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('Nội dung không hợp lệ thì ném ApiException', () async {
        // Arrange
        when(
          () => mockApi.post(
            any(),
            body: any(named: 'body'),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(
            {
              'message': 'Nội dung bình luận không được để trống',
            },
            400,
          ),
        );

        // Act & Assert
        await expectLater(
          commentRepository.create(
            storyId: 'story-123',
            content: '',
          ),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('deleteComment', () {
      test('Xóa bình luận thành công không ném ngoại lệ', () async {
        // Arrange
        when(
          () => mockApi.delete(
            any(),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(
            {
              'message': 'Xóa bình luận thành công',
            },
            200,
          ),
        );

        // Act
        await commentRepository.deleteComment('comment-123');

        // Assert
        verify(
          () => mockApi.delete(
            '/comments/comment-123',
            auth: true,
          ),
        ).called(1);
      });

      test('Xóa bình luận không tồn tại thì ném ApiException', () async {
        // Arrange
        when(
          () => mockApi.delete(
            any(),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(
            {
              'message': 'Không tìm thấy bình luận',
            },
            404,
          ),
        );

        // Act & Assert
        await expectLater(
          commentRepository.deleteComment('comment-not-found'),
          throwsA(isA<ApiException>()),
        );

        verify(
          () => mockApi.delete(
            '/comments/comment-not-found',
            auth: true,
          ),
        ).called(1);
      });

      test('Không có quyền xóa bình luận thì ném ApiException', () async {
        // Arrange
        when(
          () => mockApi.delete(
            any(),
            auth: any(named: 'auth'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse(
            {
              'message': 'Bạn không có quyền xóa bình luận này',
            },
            403,
          ),
        );

        // Act & Assert
        await expectLater(
          commentRepository.deleteComment('comment-123'),
          throwsA(isA<ApiException>()),
        );

        verify(
          () => mockApi.delete(
            '/comments/comment-123',
            auth: true,
          ),
        ).called(1);
      });
    });
  });
}
