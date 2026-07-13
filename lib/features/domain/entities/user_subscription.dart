class UserSubscription {
  final String id;
  final String packageName;
  final num durationDays;
  final num priceCoins;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  const UserSubscription({
    required this.id,
    required this.packageName,
    required this.durationDays,
    required this.priceCoins,
    required this.status,
    this.startDate,
    this.endDate,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    final pkg = json['packageId'];
    final packageMap = pkg is Map<String, dynamic> ? pkg : <String, dynamic>{};
    return UserSubscription(
      id: (json['_id'] ?? '').toString(),
      packageName: (packageMap['name'] ?? 'Gói VIP').toString(),
      durationDays: packageMap['durationDays'] is num ? packageMap['durationDays'] as num : 0,
      priceCoins: packageMap['priceCoins'] is num ? packageMap['priceCoins'] as num : 0,
      status: (json['status'] ?? '').toString(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
    );
  }
}
