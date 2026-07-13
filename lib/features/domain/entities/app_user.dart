class AppUser {
  final String? id;
  final String username;
  final String? email;
  final String? fullName;
  final String? role;
  final bool isVip;
  final bool isBanned;
  final DateTime? vipUntil;
  final Wallet? wallet;

  AppUser({
    this.id,
    required this.username,
    this.email,
    this.fullName,
    this.role,
    this.isVip = false,
    this.isBanned = false,
    this.vipUntil,
    this.wallet,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['_id'] ?? json['id'])?.toString(),
    username: (json['username'] ?? '').toString(),
    email: json['email']?.toString(),
    fullName: json['fullName']?.toString(),
    role: json['role']?.toString(),
    isVip: json['isVip'] == true,
    isBanned: json['isBanned'] == true,
    vipUntil: json['vipUntil'] != null
        ? DateTime.tryParse(json['vipUntil'].toString())
        : null,
    wallet: json['wallet'] is Map<String, dynamic>
        ? Wallet.fromJson(json['wallet'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'username': username,
    'email': email,
    'fullName': fullName,
    'role': role,
    'isVip': isVip,
    'isBanned': isBanned,
    'vipUntil': vipUntil?.toIso8601String(),
    'wallet': wallet?.toJson(),
  };

  AppUser copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? role,
    bool? isVip,
    bool? isBanned,
    DateTime? vipUntil,
    Wallet? wallet,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isVip: isVip ?? this.isVip,
      isBanned: isBanned ?? this.isBanned,
      vipUntil: vipUntil ?? this.vipUntil,
      wallet: wallet ?? this.wallet,
    );
  }
}

class Wallet {
  final num balance;
  final bool isLocked;

  Wallet({this.balance = 0, this.isLocked = false});

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    balance: json['balance'] is num ? json['balance'] : 0,
    isLocked: json['isLocked'] == true,
  );

  Map<String, dynamic> toJson() => {'balance': balance, 'isLocked': isLocked};
}
