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

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final inner = map[r'$date'];
      if (inner != null) {
        if (inner is int) {
          return DateTime.fromMillisecondsSinceEpoch(inner);
        }
        final s = inner.toString();
        final p = DateTime.tryParse(s);
        if (p != null) return p;
      }
    }
    final s = raw.toString();
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    return DateTime.now();
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString(),
      date: _parseDate(json['date']),
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
