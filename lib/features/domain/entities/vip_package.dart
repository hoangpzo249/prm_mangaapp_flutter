class VipPackage {
  final String id;
  final String name;
  final num durationDays;
  final num priceCoins;
  final String description;
  final bool isActive;

  VipPackage({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.priceCoins,
    this.description = '',
    this.isActive = true,
  });

  factory VipPackage.fromJson(Map<String, dynamic> json) => VipPackage(
        id: (json['_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        durationDays: json['durationDays'] is num ? json['durationDays'] : 0,
        priceCoins: json['priceCoins'] is num ? json['priceCoins'] : 0,
        description: (json['description'] ?? '').toString(),
        isActive: json['isActive'] == true,
      );
}
