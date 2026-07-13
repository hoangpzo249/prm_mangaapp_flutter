import 'chapter.dart';

class Story {
  final String id;
  final String title;
  final String? thumbnail;
  final String? author;
  final String? description;
  final String? status;
  final num views;
  final num? averageRating;
  final num ratingCount;
  final num bookmarkCount;
  final String? updatedAt;
  final List<String> genres;
  final Chapter? latestChapter;
  final List<Chapter> latestChapters;

  Story({
    required this.id,
    required this.title,
    this.thumbnail,
    this.author,
    this.description,
    this.status,
    this.views = 0,
    this.averageRating,
    this.ratingCount = 0,
    this.bookmarkCount = 0,
    this.updatedAt,
    this.genres = const [],
    this.latestChapter,
    this.latestChapters = const [],
  });

  static String? _cleanPlaceholder(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    if (s == 'Đang cập nhật' || s == 'Đang cập nhật...') return null;
    return s;
  }

  factory Story.fromJson(Map<String, dynamic> json) {
    final genresRaw = json['genres'];
    return Story(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      thumbnail: json['thumbnail'] != null && json['thumbnail'].toString().startsWith('http')
          ? 'https://wsrv.nl/?url=${json['thumbnail']}'
          : json['thumbnail'],
      author: _cleanPlaceholder(json['author']),
      description: _cleanPlaceholder(json['description']),
      status: json['status'],
      views: json['views'] is num ? json['views'] : num.tryParse('${json['views']}') ?? 0,
      averageRating: json['averageRating'] is num ? json['averageRating'] : num.tryParse('${json['averageRating']}'),
      ratingCount: json['ratingCount'] is num ? json['ratingCount'] : num.tryParse('${json['ratingCount']}') ?? 0,
      bookmarkCount: json['bookmarkCount'] is num ? json['bookmarkCount'] : num.tryParse('${json['bookmarkCount']}') ?? 0,
      updatedAt: json['updatedAt'],
      genres: genresRaw is List ? List<String>.from(genresRaw.map((g) => g is Map ? (g['name'] ?? '').toString() : g.toString())) : const [],
      latestChapter: json['latestChapter'] is Map<String, dynamic> ? Chapter.fromJson(json['latestChapter']) : null,
      latestChapters: json['latestChapters'] is List ? List<Chapter>.from((json['latestChapters'] as List).whereType<Map<String, dynamic>>().map(Chapter.fromJson)) : const [],
    );
  }
}
