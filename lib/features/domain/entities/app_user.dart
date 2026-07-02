class AppUser {
  final String? id;
  final String username;
  final bool isVip;

  AppUser({this.id, required this.username, this.isVip = false});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['_id']?.toString(),
        username: (json['username'] ?? '').toString(),
        isVip: json['isVip'] == true,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'isVip': isVip,
      };

  AppUser copyWith({bool? isVip}) =>
      AppUser(id: id, username: username, isVip: isVip ?? this.isVip);
}
