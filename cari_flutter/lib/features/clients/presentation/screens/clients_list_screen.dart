import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../transactions/presentation/providers/dashboard_provider.dart';
import '../../../transactions/presentation/widgets/dashboard_summary_card.dart';
import '../../data/models/client_model.dart';
import '../providers/clients_provider.dart';

enum _BalanceFilter { all, receivable, debt, zero }

enum _SortMode { nameAsc, nameDesc, balanceHigh, balanceLow }

class ClientsListScreen extends ConsumerStatefulWidget {
  const ClientsListScreen({super.key});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _BalanceFilter _selectedFilter = _BalanceFilter.all;
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
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺ ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Color _balanceColor(double balance) {
    if (balance > 0) return AppColors.successColor;
    if (balance < 0) return AppColors.dangerColor;
    return AppColors.textColor;
  }

  String _subtitle(ClientModel client) {
    if ((client.phone ?? '').trim().isNotEmpty) {
      return client.phone!.trim();
    }
    if ((client.email ?? '').trim().isNotEmpty) {
      return client.email!.trim();
    }
    return 'Iletisim bilgisi yok';
  }

  List<ClientModel> _applyFiltersAndSort(List<ClientModel> clients) {
    var filtered = clients;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        final name = client.name.toLowerCase();
        final phone = (client.phone ?? '').toLowerCase();
        final email = (client.email ?? '').toLowerCase();
        final address = (client.address ?? '').toLowerCase();
        final notes = (client.notes ?? '').toLowerCase();
        return name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            address.contains(_searchQuery) ||
            notes.contains(_searchQuery);
      }).toList();
    }

    switch (_selectedFilter) {
      case _BalanceFilter.receivable:
        filtered = filtered.where((c) => c.currentBalance > 0).toList();
      case _BalanceFilter.debt:
        filtered = filtered.where((c) => c.currentBalance < 0).toList();
      case _BalanceFilter.zero:
        filtered = filtered.where((c) => c.currentBalance == 0).toList();
      case _BalanceFilter.all:
        break;
    }

    final sorted = List<ClientModel>.from(filtered);
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

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedFilter != _BalanceFilter.all ||
      _sortMode != _SortMode.nameAsc;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedFilter = _BalanceFilter.all;
      _sortMode = _SortMode.nameAsc;
    });
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
              expandedHeight: 130,
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: const Text('CariFlow Dashboard'),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withAlpha(24),
                        Colors.white,
                        AppColors.successColor.withAlpha(20),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Kayitli musteriler',
                  onPressed: () => context.go('/clients'),
                  icon: const Icon(Icons.groups_rounded),
                ),
                IconButton(
                  tooltip: 'Yenile',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: DashboardSummaryCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ara: ad, telefon, e-posta, adres, not...',
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        AppColors.primaryColor.withAlpha(14),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primaryColor.withAlpha(30),
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
                              Icons.filter_list_rounded,
                              size: 22,
                              color: AppColors.primaryColor.withAlpha(220),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Gelismis filtreleme',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            if (_hasActiveFilters)
                              TextButton.icon(
                                onPressed: _resetFilters,
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: const Text('Sifirla'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _DashFilterChip(
                                label: 'Tumu',
                                icon: Icons.all_inbox_rounded,
                                selected: _selectedFilter == _BalanceFilter.all,
                                onTap: () => setState(
                                  () => _selectedFilter = _BalanceFilter.all,
                                ),
                              ),
                              _DashFilterChip(
                                label: 'Alacak',
                                icon: Icons.trending_up_rounded,
                                selected:
                                    _selectedFilter ==
                                    _BalanceFilter.receivable,
                                onTap: () => setState(
                                  () => _selectedFilter =
                                      _BalanceFilter.receivable,
                                ),
                              ),
                              _DashFilterChip(
                                label: 'Borc',
                                icon: Icons.trending_down_rounded,
                                selected:
                                    _selectedFilter == _BalanceFilter.debt,
                                onTap: () => setState(
                                  () => _selectedFilter = _BalanceFilter.debt,
                                ),
                              ),
                              _DashFilterChip(
                                label: 'Sifir bakiye',
                                icon: Icons.balance_rounded,
                                selected:
                                    _selectedFilter == _BalanceFilter.zero,
                                onTap: () => setState(
                                  () => _selectedFilter = _BalanceFilter.zero,
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
                                  child: Text('Bakiye (yuksek → dusuk)'),
                                ),
                                DropdownMenuItem(
                                  value: _SortMode.balanceLow,
                                  child: Text('Bakiye (dusuk → yuksek)'),
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
              error: (error, _) => SliverFillRemaining(
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
                          ApiErrorMapper.toMessage(error),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.dangerColor),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (clients) {
                final filteredClients = _applyFiltersAndSort(clients);

                if (filteredClients.isEmpty) {
                  final hasSearchOrFilter = _hasActiveFilters;
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasSearchOrFilter
                                  ? Icons.filter_alt_off_rounded
                                  : Icons.groups_rounded,
                              color: AppColors.textColor.withAlpha(140),
                              size: 42,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              hasSearchOrFilter
                                  ? 'Arama veya filtreye uygun musteri bulunamadi'
                                  : 'Henuz musteri eklenmedi',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            if (hasSearchOrFilter)
                              OutlinedButton.icon(
                                onPressed: _resetFilters,
                                icon: const Icon(
                                  Icons.cleaning_services_rounded,
                                ),
                                label: const Text('Filtreleri temizle'),
                              )
                            else
                              FilledButton.icon(
                                onPressed: () => context.go('/clients/new'),
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                label: const Text('Ilk musteriyi ekle'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
                  sliver: SliverList.builder(
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 180 + (index * 35)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 10),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          elevation: 0.6,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.go('/client/${client.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primaryColor
                                        .withAlpha(28),
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                client.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: client.isActive
                                                    ? AppColors.successColor
                                                          .withAlpha(20)
                                                    : AppColors.dangerColor
                                                          .withAlpha(20),
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                              child: Text(
                                                client.isActive
                                                    ? 'Aktif'
                                                    : 'Pasif',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: client.isActive
                                                      ? AppColors.successColor
                                                      : AppColors.dangerColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _subtitle(client),
                                          style: TextStyle(
                                            color: AppColors.textColor
                                                .withAlpha(150),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatCurrency(client.currentBalance),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _balanceColor(
                                            client.currentBalance,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textColor.withAlpha(
                                          100,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
    );
  }
}

class _DashFilterChip extends StatelessWidget {
  const _DashFilterChip({
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
            ? AppColors.primaryColor.withAlpha(40)
            : Colors.white.withAlpha(245),
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
