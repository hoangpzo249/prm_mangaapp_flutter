class AppUser {
  final String? id;
  final String username;
  final String? email;
  final String? fullName;
  final String? role;
  final bool isVip;
  final DateTime? vipUntil;
  final bool isBanned;
  final Wallet? wallet;

  AppUser({
    this.id,
    required this.username,
    this.email,
    this.fullName,
    this.role,
    this.isVip = false,
    this.vipUntil,
    this.isBanned = false,
    this.wallet,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        username: (json['username'] ?? '').toString(),
        email: json['email']?.toString(),
        fullName: json['fullName']?.toString(),
        role: json['role']?.toString(),
        isVip: json['isVip'] == true,
        vipUntil: json['vipUntil'] != null
            ? DateTime.tryParse(json['vipUntil'].toString())
            : null,
        isBanned: json['isBanned'] == true,
        wallet: json['wallet'] is Map<String, dynamic>
            ? Wallet.fromJson(json['wallet'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': role,
        'isVip': isVip,
        'vipUntil': vipUntil?.toIso8601String(),
        'isBanned': isBanned,
        'wallet': wallet?.toJson(),
      };

  AppUser copyWith({
    String? email,
    String? fullName,
    String? role,
    bool? isVip,
    DateTime? vipUntil,
    bool? isBanned,
    Wallet? wallet,
  }) =>
      AppUser(
        id: id,
        username: username,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        isVip: isVip ?? this.isVip,
        vipUntil: vipUntil ?? this.vipUntil,
        isBanned: isBanned ?? this.isBanned,
        wallet: wallet ?? this.wallet,
      );
}

class Wallet {
  final num balance;
  final bool isLocked;

  Wallet({this.balance = 0, this.isLocked = false});

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        balance: json['balance'] is num ? json['balance'] as num : 0,
        isLocked: json['isLocked'] == true,
      );

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'isLocked': isLocked,
      };
}
