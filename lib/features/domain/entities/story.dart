import 'chapter.dart';

class Story {
  final String id;
  final String title;
  final String? slug;
  final String? thumbnail;
  final String? author;
  final String? description;
  final String? status;
  final num views;
  final num chapterCount;
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
    this.slug,
    this.thumbnail,
    this.author,
    this.description,
    this.status,
    this.views = 0,
    this.chapterCount = 0,
    this.averageRating,
    this.ratingCount = 0,
    this.bookmarkCount = 0,
    this.updatedAt,
    this.genres = const [],
    this.latestChapter,
    this.latestChapters = const [],
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final genresRaw = json['genres'];
    final thumbnail = json['thumbnail']?.toString();
    return Story(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: json['slug']?.toString(),
      thumbnail: thumbnail != null && thumbnail.startsWith('http')
          ? 'https://wsrv.nl/?url=$thumbnail'
          : thumbnail,
      author: json['author']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      views: json['views'] is num ? json['views'] as num : num.tryParse('${json['views']}') ?? 0,
      chapterCount: json['chapterCount'] is num
          ? json['chapterCount'] as num
          : num.tryParse('${json['chapterCount']}') ?? 0,
      averageRating: json['averageRating'] is num
          ? json['averageRating'] as num
          : num.tryParse('${json['averageRating']}'),
      ratingCount: json['ratingCount'] is num
          ? json['ratingCount'] as num
          : num.tryParse('${json['ratingCount']}') ?? 0,
      bookmarkCount: json['bookmarkCount'] is num
          ? json['bookmarkCount'] as num
          : num.tryParse('${json['bookmarkCount']}') ?? 0,
      updatedAt: json['updatedAt']?.toString(),
      genres: genresRaw is List
          ? List<String>.from(
              genresRaw.map((g) => g is Map ? (g['name'] ?? '').toString() : g.toString()),
            )
          : const [],
      latestChapter: json['latestChapter'] is Map<String, dynamic>
          ? Chapter.fromJson(json['latestChapter'] as Map<String, dynamic>)
          : null,
      latestChapters: json['latestChapters'] is List
          ? (json['latestChapters'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Chapter.fromJson)
              .toList()
          : const [],
    );
  }
}
