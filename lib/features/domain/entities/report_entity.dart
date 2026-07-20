class ReportEntity {
  final String id;
  final String status; // 'pending' | 'resolved' | 'dismissed'
  final String targetType; // 'comment' | 'story'
  final String targetId;
  final String reason;
  final String adminNote;
  final DateTime? createdAt;

  // Reporter info (populated)
  final String reporterId;
  final String reporterName;

  // Target info (populated from backend)
  final Map<String, dynamic>? target;

  const ReportEntity({
    required this.id,
    required this.status,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.adminNote = '',
    this.createdAt,
    this.reporterId = '',
    this.reporterName = '',
    this.target,
  });

  factory ReportEntity.fromJson(Map<String, dynamic> json) {
    final rawReporter = json['reporterId'];
    String reporterId = '';
    String reporterName = 'Unknown';
    if (rawReporter is Map<String, dynamic>) {
      reporterId = (rawReporter['_id'] ?? '').toString();
      final fullName = (rawReporter['fullName'] ?? '').toString().trim();
      final username = (rawReporter['username'] ?? '').toString().trim();
      reporterName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : 'Unknown');
    } else if (rawReporter != null) {
      reporterId = rawReporter.toString();
    }

    return ReportEntity(
      id: (json['_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      targetType: (json['targetType'] ?? '').toString(),
      targetId: (json['targetId'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      adminNote: (json['adminNote'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      reporterId: reporterId,
      reporterName: reporterName,
      target: json['target'] is Map<String, dynamic>
          ? json['target'] as Map<String, dynamic>
          : null,
    );
  }

  /// Tên/title của nội dung bị báo cáo
  String get targetDisplayName {
    if (target == null) return targetId;
    if (targetType == 'story') {
      return (target!['title'] ?? 'Truyện không xác định').toString();
    }
    if (targetType == 'comment') {
      return (target!['content'] ?? 'Bình luận không xác định').toString();
    }
    return targetId;
  }

  /// Người viết nội dung bị báo cáo (comment author)
  String get targetAuthorName {
    if (target == null) return '';
    final rawUser = target!['userId'];
    if (rawUser is Map<String, dynamic>) {
      final fullName = (rawUser['fullName'] ?? '').toString().trim();
      final username = (rawUser['username'] ?? '').toString().trim();
      return fullName.isNotEmpty ? fullName : username;
    }
    return '';
  }
}
