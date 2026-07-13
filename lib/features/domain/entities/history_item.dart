class HistoryItem {
  final String storyId;
  final String? storyTitle;
  final String? storyThumbnail;
  final String? chapterId;
  final num? chapterNumber;
  final String? chapterTitle;
  final String? readAt;

  HistoryItem({
    required this.storyId,
    this.storyTitle,
    this.storyThumbnail,
    this.chapterId,
    this.chapterNumber,
    this.chapterTitle,
    this.readAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        storyId: (json['storyId'] ?? '').toString(),
        storyTitle: json['storyTitle'],
        storyThumbnail: _proxyThumb(json['storyThumbnail']),
        chapterId: json['chapterId']?.toString(),
        chapterNumber: json['chapterNumber'] is num
            ? json['chapterNumber']
            : num.tryParse('${json['chapterNumber']}'),
        chapterTitle: json['chapterTitle'],
        readAt: json['readAt'],
      );

  factory HistoryItem.fromServer(Map<String, dynamic> json) {
    final story = json['storyId'];
    final chapter = json['lastChapterId'];
    return HistoryItem(
      storyId: (story is Map ? story['_id'] : story).toString(),
      storyTitle: story is Map ? story['title'] : null,
      storyThumbnail:
          story is Map ? _proxyThumb(story['thumbnail']) : null,
      chapterId: chapter is Map ? chapter['_id']?.toString() : null,
      chapterNumber: chapter is Map ? chapter['chapterNumber'] : null,
      chapterTitle:
          chapter is Map ? (chapter['title'] ?? chapter['chapterTitle']) : null,
      readAt: json['updatedAt'],
    );
  }

  static String? _proxyThumb(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    if (s.startsWith('https://wsrv.nl/')) return s;
    return s.startsWith('http') ? 'https://wsrv.nl/?url=$s' : s;
  }

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'storyTitle': storyTitle,
        'storyThumbnail': storyThumbnail,
        'chapterId': chapterId,
        'chapterNumber': chapterNumber,
        'chapterTitle': chapterTitle,
        'readAt': readAt,
      };
}
