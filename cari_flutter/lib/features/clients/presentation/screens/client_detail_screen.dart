import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../transactions/presentation/providers/dashboard_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../transactions/presentation/widgets/add_transaction_bottom_sheet.dart';
import '../../../transactions/presentation/widgets/edit_transaction_bottom_sheet.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../data/client_repository.dart';
import '../../data/models/client_model.dart';
import '../providers/clients_provider.dart';
import '../widgets/edit_client_bottom_sheet.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  String get id => widget.id;

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

  Future<void> _refresh() async {
    ref.invalidate(clientsNotifierProvider);
    ref.invalidate(clientByIdProvider(id));
    ref.invalidate(transactionsProvider(id));
    ref.invalidate(dashboardProvider);
    await ref.read(transactionsProvider(id).future);
  }

  Future<void> _showAddTransactionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddTransactionBottomSheet(clientId: id),
    );
    if (mounted) await _refresh();
  }

  Future<void> _showEditClientSheet(ClientModel client) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditClientBottomSheet(client: client),
    );
    if (mounted) await _refresh();
  }

  Future<void> _showEditTransaction(TransactionModel tx) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTransactionBottomSheet(clientId: id, transaction: tx),
    );
    if (mounted) await _refresh();
  }

  Future<void> _confirmDeleteTransaction(TransactionModel tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.dangerColor),
            SizedBox(width: 8),
            Text('Islemi sil'),
          ],
        ),
        content: const Text(
          'Bu hareket silinecek ve cari bakiyesi geri alinacak. '
          'Yanlis musteriye veya yanlis tutarda girildiyse bu islemi kullanin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
      if (!mounted) return;
      ref.invalidate(transactionsProvider(id));
      ref.invalidate(clientsNotifierProvider);
      ref.invalidate(dashboardProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Islem silindi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorMapper.toMessage(e))));
    }
  }

  Future<void> _confirmAndDelete(ClientModel client) async {
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

      if (!mounted) return;
      context.go('/');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorMapper.toMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Musteri detayi'),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (selectedClient != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await _showEditClientSheet(selectedClient);
                } else if (value == 'delete') {
                  await _confirmAndDelete(selectedClient);
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: selectedClient != null
                    ? Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppColors.primaryColor.withAlpha(28),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primaryColor
                                    .withAlpha(30),
                                child: Text(
                                  selectedClient.name.isNotEmpty
                                      ? selectedClient.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedClient.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if ((selectedClient.phone ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      Text(
                                        selectedClient.phone!.trim(),
                                        style: TextStyle(
                                          color: AppColors.textColor.withAlpha(
                                            150,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Bakiye',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textColor.withAlpha(140),
                                    ),
                                  ),
                                  Text(
                                    _formatMoney(selectedClient.currentBalance),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: _balanceColor(
                                        selectedClient.currentBalance,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : fallbackClientState.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Musteri bilgisi bulunamadi'),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppColors.primaryColor.withAlpha(220),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Islem gecmisi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            transactionsState.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.dangerColor,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ApiErrorMapper.toMessage(error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.textColor.withAlpha(120),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bu musteri icin henuz islem yok',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Asagidaki + ile borclandirma veya tahsilat ekleyin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textColor.withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.builder(
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
                      ).format(tx.date.toLocal());

                      final description = (tx.description ?? '').trim();
                      final subtitle = description.isEmpty
                          ? dateText
                          : '$description\n$dateText';

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 120 + index * 24),
                        curve: Curves.easeOut,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 6),
                            child: child,
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: color.withAlpha(24),
                              child: Icon(
                                isDebt
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: color,
                              ),
                            ),
                            title: Text(
                              '$sign ${_formatMoney(tx.amount)}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(subtitle),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded),
                              onSelected: (v) {
                                if (v == 'edit') {
                                  _showEditTransaction(tx);
                                } else if (v == 'delete') {
                                  _confirmDeleteTransaction(tx);
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_rounded),
                                    title: Text('Duzenle'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.dangerColor,
                                    ),
                                    title: Text(
                                      'Sil',
                                      style: TextStyle(
                                        color: AppColors.dangerColor,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionSheet,
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Islem'),
      ),
    );
  }
}
