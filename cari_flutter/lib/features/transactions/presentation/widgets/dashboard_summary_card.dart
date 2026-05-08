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

  Color _netColor(double net) {
    if (net > 0) return AppColors.successColor;
    if (net < 0) return AppColors.dangerColor;
    return AppColors.textColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dashboardProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withAlpha(18),
            Colors.white,
            AppColors.successColor.withAlpha(14),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withAlpha(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: summaryState.when(
          loading: () => const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ozet yuklenemedi: ${ApiErrorMapper.toMessage(error)}',
                  style: const TextStyle(color: AppColors.dangerColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
          data: (summary) {
            final net = summary.totalReceivables - summary.totalDebt;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.space_dashboard_rounded,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Finansal Ozet',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textColor.withAlpha(220),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
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
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _netColor(net).withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: _netColor(net),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Net Durum',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        _formatCurrency(net),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _netColor(net),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
