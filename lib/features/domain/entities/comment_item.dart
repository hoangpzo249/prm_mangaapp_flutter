class CommentItem {
  final String id;
  final String userId;
  final String displayName;
  final String content;
  final DateTime? createdAt;
  final List<CommentItem> replies;

  const CommentItem({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.content,
    this.createdAt,
    this.replies = const [],
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    final rawUser = json['userId'];
    String userId = '';
    String displayName = 'Người dùng';
    if (rawUser is Map<String, dynamic>) {
      userId = (rawUser['_id'] ?? '').toString();
      final fullName = (rawUser['fullName'] ?? '').toString().trim();
      final username = (rawUser['username'] ?? '').toString().trim();
      displayName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : displayName);
    } else if (rawUser != null) {
      userId = rawUser.toString();
    }

    final rawReplies = json['replies'];
    return CommentItem(
      id: (json['_id'] ?? '').toString(),
      userId: userId,
      displayName: displayName,
      content: (json['content'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      replies: rawReplies is List
          ? rawReplies
              .whereType<Map<String, dynamic>>()
              .map(CommentItem.fromJson)
              .toList()
          : const [],
    );
  }
}
