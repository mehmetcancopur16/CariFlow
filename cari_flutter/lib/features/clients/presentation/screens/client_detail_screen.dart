import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../transactions/presentation/providers/dashboard_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../transactions/presentation/widgets/add_transaction_bottom_sheet.dart';
import '../../data/client_repository.dart';
import '../../data/models/client_model.dart';
import '../providers/clients_provider.dart';
import '../widgets/edit_client_bottom_sheet.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({required this.id, super.key});

  final String id;

  String _formatMoney(double amount) {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺ ',
      decimalDigits: 2,
    ).format(amount);
  }

  Color _balanceColor(double amount) {
    if (amount > 0) return AppColors.successColor;
    if (amount < 0) return AppColors.dangerColor;
    return AppColors.textColor;
  }

  Future<void> _showAddTransactionSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddTransactionBottomSheet(clientId: id),
    );
  }

  Future<void> _showEditClientSheet(
    BuildContext context,
    ClientModel client,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditClientBottomSheet(client: client),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    ClientModel client,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Musteri Sil'),
        content: const Text('Bu musteriyi silmek istediginize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Iptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerColor,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (approved != true) return;

    try {
      await ref.read(clientRepositoryProvider).deleteClient(client.id);
      ref.invalidate(clientsNotifierProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(transactionsProvider(id));

      if (!context.mounted) return;
      context.go('/');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorMapper.toMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsState = ref.watch(clientsNotifierProvider);
    final fallbackClientState = ref.watch(clientByIdProvider(id));
    final transactionsState = ref.watch(transactionsProvider(id));

    final selectedFromList = clientsState.when(
      data: (clients) {
        for (final client in clients) {
          if (client.id == id) return client;
        }
        return null;
      },
      loading: () => null,
      error: (_, __) => null,
    );

    final selectedClient =
        selectedFromList ??
        fallbackClientState.when(
          data: (client) => client,
          loading: () => null,
          error: (_, __) => null,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Musteri Detayi'),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (selectedClient != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await _showEditClientSheet(context, selectedClient);
                } else if (value == 'delete') {
                  await _confirmAndDelete(context, ref, selectedClient);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(value: 'edit', child: Text('Duzenle')),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(
                    'Sil',
                    style: TextStyle(color: AppColors.dangerColor),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedClient != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedClient.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatMoney(selectedClient.currentBalance),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _balanceColor(selectedClient.currentBalance),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (fallbackClientState.isLoading)
              const LinearProgressIndicator()
            else
              const Text('Musteri bilgisi bulunamadi'),
            const SizedBox(height: 12),
            const Text(
              'Islem Gecmisi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: transactionsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Islemler yuklenemedi: ${ApiErrorMapper.toMessage(error)}',
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Text('Bu musteri icin henuz islem yok'),
                    );
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isDebt = tx.type == 'debt';
                      final sign = isDebt ? '+' : '-';
                      final color = isDebt
                          ? AppColors.successColor
                          : AppColors.dangerColor;
                      final dateText = DateFormat(
                        'dd.MM.yyyy HH:mm',
                      ).format(tx.date);

                      final description = (tx.description ?? '').trim();
                      final subtitle = description.isEmpty
                          ? dateText
                          : '$description\n$dateText';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withAlpha(20),
                            child: Icon(
                              isDebt ? Icons.trending_up : Icons.trending_down,
                              color: color,
                            ),
                          ),
                          title: Text(
                            '$sign ${_formatMoney(tx.amount)}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(subtitle),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
