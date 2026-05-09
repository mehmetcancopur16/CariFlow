import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../transactions/presentation/providers/dashboard_provider.dart';
import '../../data/models/client_model.dart';
import '../providers/clients_provider.dart';

enum _BalanceFilter { all, receivable, debt, zero }

enum _SortMode { nameAsc, nameDesc, balanceHigh, balanceLow }

/// Full directory of customers with search, filters, sort, and delete actions.
class RegisteredClientsScreen extends ConsumerStatefulWidget {
  const RegisteredClientsScreen({super.key});

  @override
  ConsumerState<RegisteredClientsScreen> createState() =>
      _RegisteredClientsScreenState();
}

class _RegisteredClientsScreenState
    extends ConsumerState<RegisteredClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _BalanceFilter _balanceFilter = _BalanceFilter.all;
  _SortMode _sortMode = _SortMode.nameAsc;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺ ',
      decimalDigits: 2,
    ).format(amount);
  }

  Color _balanceColor(double balance) {
    if (balance > 0) return AppColors.successColor;
    if (balance < 0) return AppColors.dangerColor;
    return AppColors.textColor;
  }

  List<ClientModel> _filterAndSort(List<ClientModel> clients) {
    var list = clients;

    if (_searchQuery.isNotEmpty) {
      list = list.where((client) {
        final name = client.name.toLowerCase();
        final phone = (client.phone ?? '').toLowerCase();
        final email = (client.email ?? '').toLowerCase();
        final address = (client.address ?? '').toLowerCase();
        return name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            address.contains(_searchQuery);
      }).toList();
    }

    switch (_balanceFilter) {
      case _BalanceFilter.receivable:
        list = list.where((c) => c.currentBalance > 0).toList();
      case _BalanceFilter.debt:
        list = list.where((c) => c.currentBalance < 0).toList();
      case _BalanceFilter.zero:
        list = list.where((c) => c.currentBalance == 0).toList();
      case _BalanceFilter.all:
        break;
    }

    final sorted = List<ClientModel>.from(list);
    switch (_sortMode) {
      case _SortMode.nameAsc:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _SortMode.nameDesc:
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
      case _SortMode.balanceHigh:
        sorted.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
      case _SortMode.balanceLow:
        sorted.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
    }
    return sorted;
  }

  Future<void> _confirmDelete(ClientModel client) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.dangerColor),
            SizedBox(width: 8),
            Text('Musteriyi sil'),
          ],
        ),
        content: Text(
          '"${client.name}" kalici olarak silinsin mi? Bu islem geri alinamaz.',
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
      await ref.read(clientsNotifierProvider.notifier).deleteClient(client.id);
      ref.invalidate(dashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${client.name}" silindi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiErrorMapper.toMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientsNotifierProvider);
    final theme = Theme.of(context);

    Future<void> onRefresh() async {
      ref.invalidate(clientsNotifierProvider);
      ref.invalidate(dashboardProvider);
      await ref.read(clientsNotifierProvider.future);
      await ref.read(dashboardProvider.future);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 118,
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: const Text('Kayitli Musteriler'),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.successColor.withAlpha(22),
                        Colors.white,
                        AppColors.primaryColor.withAlpha(18),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Yenile',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ara: ad, telefon, e-posta, adres...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        AppColors.primaryColor.withAlpha(12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primaryColor.withAlpha(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: AppColors.primaryColor.withAlpha(220),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filtrele ve sirala',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'Tumu',
                                icon: Icons.all_inbox_rounded,
                                selected: _balanceFilter == _BalanceFilter.all,
                                onTap: () => setState(
                                  () => _balanceFilter = _BalanceFilter.all,
                                ),
                              ),
                              _FilterChip(
                                label: 'Alacak',
                                icon: Icons.trending_up_rounded,
                                selected:
                                    _balanceFilter == _BalanceFilter.receivable,
                                onTap: () => setState(
                                  () => _balanceFilter =
                                      _BalanceFilter.receivable,
                                ),
                              ),
                              _FilterChip(
                                label: 'Borc',
                                icon: Icons.trending_down_rounded,
                                selected: _balanceFilter == _BalanceFilter.debt,
                                onTap: () => setState(
                                  () => _balanceFilter = _BalanceFilter.debt,
                                ),
                              ),
                              _FilterChip(
                                label: 'Sifir bakiye',
                                icon: Icons.balance_rounded,
                                selected: _balanceFilter == _BalanceFilter.zero,
                                onTap: () => setState(
                                  () => _balanceFilter = _BalanceFilter.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Siralama',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.sort_rounded),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<_SortMode>(
                              isExpanded: true,
                              value: _sortMode,
                              items: const [
                                DropdownMenuItem(
                                  value: _SortMode.nameAsc,
                                  child: Text('Ad (A → Z)'),
                                ),
                                DropdownMenuItem(
                                  value: _SortMode.nameDesc,
                                  child: Text('Ad (Z → A)'),
                                ),
                                DropdownMenuItem(
                                  value: _SortMode.balanceHigh,
                                  child: Text('Bakiye (once yuksek)'),
                                ),
                                DropdownMenuItem(
                                  value: _SortMode.balanceLow,
                                  child: Text('Bakiye (once dusuk)'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _sortMode = v);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _balanceFilter = _BalanceFilter.all;
                                _sortMode = _SortMode.nameAsc;
                              });
                            },
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('Sifirla'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            clientsState.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.dangerColor,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ApiErrorMapper.toMessage(e),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (clients) {
                final visible = _filterAndSort(clients);
                if (visible.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: AppColors.textColor.withAlpha(120),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            clients.isEmpty
                                ? 'Henuz musteri yok'
                                : 'Filtreye uygun musteri yok',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          if (clients.isEmpty)
                            FilledButton.icon(
                              onPressed: () => context.go('/clients/new'),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Musteri ekle'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
                  sliver: SliverList.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final client = visible[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 160 + index * 28),
                        curve: Curves.easeOut,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 8),
                            child: child,
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.primaryColor.withAlpha(22),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryColor.withAlpha(
                                28,
                              ),
                              child: Text(
                                client.name.isNotEmpty
                                    ? client.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              client.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if ((client.phone ?? '').trim().isNotEmpty)
                                  client.phone!.trim(),
                                if ((client.email ?? '').trim().isNotEmpty)
                                  client.email!.trim(),
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatCurrency(client.currentBalance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _balanceColor(client.currentBalance),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded),
                                  onSelected: (v) {
                                    if (v == 'detail') {
                                      context.go('/client/${client.id}');
                                    } else if (v == 'delete') {
                                      _confirmDelete(client);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'detail',
                                      child: ListTile(
                                        leading: Icon(Icons.visibility_rounded),
                                        title: Text('Detay'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
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
                              ],
                            ),
                            onTap: () => context.go('/client/${client.id}'),
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? AppColors.primaryColor.withAlpha(36)
            : Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? AppColors.primaryColor
                      : AppColors.textColor.withAlpha(160),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primaryColor
                        : AppColors.textColor.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
