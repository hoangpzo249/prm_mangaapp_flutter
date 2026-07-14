class Genre {
  final String id;
  final String name;
  final String? slug;

  const Genre({
    required this.id,
    required this.name,
    this.slug,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: json['slug']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Genre && other.id == id && id.isNotEmpty;

  @override
  int get hashCode => id.hashCode;
}
