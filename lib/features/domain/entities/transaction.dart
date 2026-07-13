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
  final String? paymentUrl;

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
    this.paymentUrl,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: (json['_id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        amountCoins: json['amountCoins'] is num ? json['amountCoins'] : 0,
        description: (json['description'] ?? '').toString(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        paymentUrl: json['paymentUrl']?.toString(),
      );
}
