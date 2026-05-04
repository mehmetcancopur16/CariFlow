class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    required this.balanceBefore,
    required this.balanceAfter,
  });

  final String id;
  final String type;
  final double amount;
  final String? description;
  final DateTime date;
  final double balanceBefore;
  final double balanceAfter;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString(),
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
    };
  }
}
