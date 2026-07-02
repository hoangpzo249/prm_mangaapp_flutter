class Formatters {
  Formatters._();

  static String timeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Just now';
    final date = DateTime.tryParse(dateString);
    if (date == null) return 'Just now';
    final diff = DateTime.now().difference(date).inSeconds;

    if (diff < 60) return 'Just now';

    final minutes = diff ~/ 60;
    if (minutes < 60) return '$minutes minute${minutes != 1 ? 's' : ''} ago';

    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hour${hours != 1 ? 's' : ''} ago';

    final days = hours ~/ 24;
    if (days < 30) return '$days day${days != 1 ? 's' : ''} ago';

    final months = days ~/ 30;
    if (months < 12) return '$months month${months != 1 ? 's' : ''} ago';

    final years = months ~/ 12;
    return '$years year${years != 1 ? 's' : ''} ago';
  }

  static String timeAgoOrEmpty(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    return timeAgo(dateString);
  }

  static String views(num v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  static String withCommas(num v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
