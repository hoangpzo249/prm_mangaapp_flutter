class Transaction {
  final String id;
  final String type;
  final String status;
  final num amountCoins;
  final String description;
  final DateTime? createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amountCoins,
    required this.description,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: (json['_id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        amountCoins: json['amountCoins'] is num ? json['amountCoins'] : 0,
        description: (json['description'] ?? '').toString(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}
