import 'chapter.dart';

class Story {
  final String id;
  final String title;
  final String? thumbnail;
  final String? author;
  final String? description;
  final String? status;
  final num views;
  final num? rating;
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
    this.rating,
    this.updatedAt,
    this.genres = const [],
    this.latestChapter,
    this.latestChapters = const [],
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final genresRaw = json['genres'];
    return Story(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      thumbnail: json['thumbnail'],
      author: json['author'],
      description: json['description'],
      status: json['status'],
      views: json['views'] is num
          ? json['views']
          : num.tryParse('${json['views']}') ?? 0,
      rating: json['rating'] is num
          ? json['rating']
          : num.tryParse('${json['rating']}'),
      updatedAt: json['updatedAt'],
      genres: genresRaw is List
          ? List<String>.from(genresRaw
              .map((g) => g is Map ? (g['name'] ?? '').toString() : g.toString()))
          : const [],
      latestChapter: json['latestChapter'] is Map<String, dynamic>
          ? Chapter.fromJson(json['latestChapter'])
          : null,
      latestChapters: json['latestChapters'] is List
          ? List<Chapter>.from((json['latestChapters'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Chapter.fromJson))
          : const [],
    );
  }
}
