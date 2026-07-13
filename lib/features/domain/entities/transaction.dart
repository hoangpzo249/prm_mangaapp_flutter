class Transaction {
  final String id;
  final String type;
  final String status;
  final String paymentMethod;
  final num amountMoney;
  final num amountCoins;
  final String description;
  final String? appTransactionId;
  final String? gatewayTransactionId;
  final String? packageName;
  final DateTime? createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amountCoins,
    required this.description,
    this.paymentMethod = '',
    this.amountMoney = 0,
    this.appTransactionId,
    this.gatewayTransactionId,
    this.packageName,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final packageData = json['packageId'];
    return Transaction(
      id: (json['_id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      amountMoney: json['amountMoney'] is num ? json['amountMoney'] as num : 0,
      amountCoins: json['amountCoins'] is num ? json['amountCoins'] as num : 0,
      description: (json['description'] ?? '').toString(),
      appTransactionId: json['appTransactionId']?.toString(),
      gatewayTransactionId: json['gatewayTransactionId']?.toString(),
      packageName: packageData is Map<String, dynamic>
          ? packageData['name']?.toString()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
