import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../providers/dashboard_provider.dart';

class DashboardSummaryCard extends ConsumerWidget {
  const DashboardSummaryCard({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺ ',
      decimalDigits: 2,
    ).format(amount);
  }

  Widget _summaryColumn({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textColor.withAlpha(150),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dashboardProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: summaryState.when(
          loading: () => const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 72,
            child: Center(
              child: Text(
                'Ozet yuklenemedi: ${ApiErrorMapper.toMessage(error)}',
                style: const TextStyle(color: AppColors.dangerColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (summary) {
            return Row(
              children: [
                _summaryColumn(
                  title: 'Toplam Alacak',
                  value: _formatCurrency(summary.totalReceivables),
                  valueColor: AppColors.successColor,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.successColor,
                ),
                Container(
                  width: 1,
                  height: 56,
                  color: AppColors.textColor.withAlpha(30),
                ),
                const SizedBox(width: 14),
                _summaryColumn(
                  title: 'Toplam Borc',
                  value: _formatCurrency(summary.totalDebt),
                  valueColor: AppColors.dangerColor,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.dangerColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
