class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.totalReceivables,
    required this.totalDebt,
  });

  final double totalReceivables;
  final double totalDebt;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalReceivables:
          (json['totalReceivable'] as num?)?.toDouble() ??
          (json['totalReceivables'] as num?)?.toDouble() ??
          0,
      totalDebt:
          (json['totalPayable'] as num?)?.toDouble() ??
          (json['totalDebt'] as num?)?.toDouble() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'totalReceivables': totalReceivables, 'totalDebt': totalDebt};
  }
}
