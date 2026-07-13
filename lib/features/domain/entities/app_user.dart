class AppUser {
  final String? id;
  final String username;
  final String? email;
  final String? fullName;
  final String? role;
  final String? avatar;
  final bool isVip;
  final DateTime? vipUntil;
  final Wallet? wallet;

  AppUser({
    this.id,
    required this.username,
    this.email,
    this.fullName,
    this.role,
    this.avatar,
    this.isVip = false,
    this.vipUntil,
    this.wallet,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['_id']?.toString(),
        username: (json['username'] ?? '').toString(),
        email: json['email']?.toString(),
        fullName: json['fullName']?.toString(),
        role: json['role']?.toString(),
        avatar: json['avatar']?.toString(),
        isVip: json['isVip'] == true,
        vipUntil: json['vipUntil'] != null ? DateTime.tryParse(json['vipUntil']) : null,
        wallet: json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': role,
        'avatar': avatar,
        'isVip': isVip,
        'vipUntil': vipUntil?.toIso8601String(),
        'wallet': wallet?.toJson(),
      };

  AppUser copyWith({
    String? email,
    String? fullName,
    String? avatar,
    bool? isVip,
    DateTime? vipUntil,
    Wallet? wallet,
  }) =>
      AppUser(
        id: id,
        username: username,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        avatar: avatar ?? this.avatar,
        isVip: isVip ?? this.isVip,
        vipUntil: vipUntil ?? this.vipUntil,
        wallet: wallet ?? this.wallet,
      );
}

class Wallet {
  final num balance;
  final bool isLocked;

  Wallet({this.balance = 0, this.isLocked = false});

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        balance: json['balance'] is num ? json['balance'] : 0,
        isLocked: json['isLocked'] == true,
      );

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'isLocked': isLocked,
      };
}
