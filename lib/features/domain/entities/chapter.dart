class Chapter {
  final String id;
  final String? storyId;
  final num chapterNumber;
  final String? title;
  final bool isVip;
  final String? updatedAt;
  final List<String> content;

  Chapter({
    required this.id,
    this.storyId,
    required this.chapterNumber,
    this.title,
    this.isVip = false,
    this.updatedAt,
    this.content = const [],
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final rawStory = json['storyId'];
    return Chapter(
      id: (json['_id'] ?? '').toString(),
      storyId: rawStory is Map ? rawStory['_id']?.toString() : rawStory?.toString(),
      chapterNumber: json['chapterNumber'] is num
          ? json['chapterNumber']
          : num.tryParse('${json['chapterNumber']}') ?? 0,
      title: json['title'] ?? json['chapterTitle'],
      isVip: json['isVip'] == true,
      updatedAt: json['updatedAt'],
      content: ((json['image'] ?? json['content']) is List)
          ? List<String>.from(((json['image'] ?? json['content']) as List).map((e) {
              final url = e.toString();
              return url.startsWith('http') ? 'https://wsrv.nl/?url=$url' : url;
            }))
          : const [],
    );
  }
}
