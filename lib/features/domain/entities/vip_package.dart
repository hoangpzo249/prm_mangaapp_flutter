class VipPackage {
  final String id;
  final String name;
  final num durationDays;
  final num priceCoins;
  final bool isActive;

  VipPackage({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.priceCoins,
    this.isActive = true,
  });

  factory VipPackage.fromJson(Map<String, dynamic> json) => VipPackage(
        id: (json['_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        durationDays: json['durationDays'] is num ? json['durationDays'] : 0,
        priceCoins: json['priceCoins'] is num ? json['priceCoins'] : 0,
        isActive: json['isActive'] == true,
      );
}
