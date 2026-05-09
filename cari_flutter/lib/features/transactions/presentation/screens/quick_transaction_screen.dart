import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../clients/presentation/providers/clients_provider.dart';
import '../../data/transaction_repository.dart';
import '../providers/dashboard_provider.dart';

class QuickTransactionScreen extends ConsumerStatefulWidget {
  const QuickTransactionScreen({super.key});

  @override
  ConsumerState<QuickTransactionScreen> createState() =>
      _QuickTransactionScreenState();
}

class _QuickTransactionScreenState
    extends ConsumerState<QuickTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _documentRefController = TextEditingController();

  String _searchQuery = '';
  String? _clientId;
  ClientModel? _selectedClient;
  String _selectedType = 'debt';
  bool _saving = false;

  static const _quickAmounts = [100.0, 500.0, 1000.0, 2500.0, 5000.0, 10000.0];

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
    _amountController.dispose();
    _descriptionController.dispose();
    _documentRefController.dispose();
    super.dispose();
  }

  String _formatMoney(double amount) {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺ ',
      decimalDigits: 2,
    ).format(amount);
  }

  Color _balanceColor(double b) {
    if (b > 0) return AppColors.successColor;
    if (b < 0) return AppColors.dangerColor;
    return AppColors.textColor;
  }

  List<ClientModel> _filterClients(List<ClientModel> clients) {
    if (_searchQuery.isEmpty) return clients;
    return clients.where((c) {
      final n = c.name.toLowerCase();
      final p = (c.phone ?? '').toLowerCase();
      final e = (c.email ?? '').toLowerCase();
      return n.contains(_searchQuery) ||
          p.contains(_searchQuery) ||
          e.contains(_searchQuery);
    }).toList();
  }

  void _selectClient(ClientModel c) {
    setState(() {
      _clientId = c.id;
      _selectedClient = c;
    });
  }

  String _buildDescription() {
    final doc = _documentRefController.text.trim();
    final desc = _descriptionController.text.trim();
    if (doc.isEmpty) return desc;
    if (desc.isEmpty) return 'Belge/Fis: $doc';
    return 'Belge/Fis: $doc\n$desc';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null || _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listeden bir musteri secin'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gecerli bir tutar girin'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(transactionRepositoryProvider).createTransaction({
        'clientId': _clientId,
        'type': _selectedType,
        'amount': amount,
        'description': _buildDescription(),
      });

      ref.invalidate(clientsNotifierProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedType == 'debt'
                ? 'Borclandirma kaydedildi'
                : 'Odeme kaydedildi',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiErrorMapper.toMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withAlpha(24),
              AppColors.backgroundColor,
              AppColors.successColor.withAlpha(18),
            ],
          ),
        ),
        child: SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.96, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => context.go('/'),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Dashboard',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cari islem',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    'Borclandirma veya tahsilat; bakiye aninda guncellenir.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textColor.withAlpha(145),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: clientsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => _ErrorCard(
                            message: ApiErrorMapper.toMessage(e),
                            onRetry: () =>
                                ref.invalidate(clientsNotifierProvider),
                          ),
                          data: (clients) {
                            if (clients.isEmpty) {
                              return _EmptyClientsCard(
                                onAdd: () => context.go('/clients/new'),
                                onHome: () => context.go('/'),
                              );
                            }

                            final filtered = _filterClients(clients);

                            return Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _GlassCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_search_rounded,
                                              color: AppColors.primaryColor
                                                  .withAlpha(230),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '1. Musteri secimi',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Musteri ara (ad, telefon, e-posta)',
                                            prefixIcon: const Icon(
                                              Icons.search_rounded,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 220,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(
                                                245,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: AppColors.primaryColor
                                                    .withAlpha(26),
                                              ),
                                            ),
                                            child: filtered.isEmpty
                                                ? Center(
                                                    child: Text(
                                                      'Eslesen musteri yok',
                                                      style: theme
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .textColor
                                                                .withAlpha(140),
                                                          ),
                                                    ),
                                                  )
                                                : ListView.separated(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    itemCount: filtered.length,
                                                    separatorBuilder: (_, __) =>
                                                        const Divider(
                                                          height: 1,
                                                        ),
                                                    itemBuilder: (ctx, i) {
                                                      final c = filtered[i];
                                                      final sel =
                                                          _clientId == c.id;
                                                      return AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 200,
                                                            ),
                                                        curve: Curves.easeOut,
                                                        decoration: BoxDecoration(
                                                          color: sel
                                                              ? AppColors
                                                                    .primaryColor
                                                                    .withAlpha(
                                                                      28,
                                                                    )
                                                              : Colors
                                                                    .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundColor:
                                                                AppColors
                                                                    .primaryColor
                                                                    .withAlpha(
                                                                      32,
                                                                    ),
                                                            child: Text(
                                                              c.name.isNotEmpty
                                                                  ? c.name[0]
                                                                        .toUpperCase()
                                                                  : '?',
                                                              style: const TextStyle(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ),
                                                          title: Text(
                                                            c.name,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                          subtitle: Text(
                                                            [
                                                              if ((c.phone ??
                                                                      '')
                                                                  .trim()
                                                                  .isNotEmpty)
                                                                c.phone!.trim(),
                                                              if ((c.email ??
                                                                      '')
                                                                  .trim()
                                                                  .isNotEmpty)
                                                                c.email!.trim(),
                                                            ].join(' · '),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          trailing: sel
                                                              ? const Icon(
                                                                  Icons
                                                                      .check_circle_rounded,
                                                                  color: AppColors
                                                                      .successColor,
                                                                )
                                                              : const Icon(
                                                                  Icons
                                                                      .chevron_right_rounded,
                                                                ),
                                                          onTap: () =>
                                                              _selectClient(c),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedClient != null) ...[
                                    const SizedBox(height: 16),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.94, end: 1),
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutBack,
                                      builder: (context, v, child) => Opacity(
                                        opacity: v.clamp(0.0, 1.0),
                                        child: Transform.translate(
                                          offset: Offset(0, (1 - v) * 12),
                                          child: child,
                                        ),
                                      ),
                                      child: _GlassCard(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _selectedClient!.name,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Guncel bakiye',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: AppColors
                                                              .textColor
                                                              .withAlpha(140),
                                                        ),
                                                  ),
                                                  Text(
                                                    _formatMoney(
                                                      _selectedClient!
                                                          .currentBalance,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 26,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: _balanceColor(
                                                        _selectedClient!
                                                            .currentBalance,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton.filledTonal(
                                              tooltip: 'Secimi kaldir',
                                              onPressed: () {
                                                setState(() {
                                                  _clientId = null;
                                                  _selectedClient = null;
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  _GlassCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.swap_vert_rounded,
                                              color: AppColors.primaryColor
                                                  .withAlpha(230),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '2. Islem turu',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        LayoutBuilder(
                                          builder: (context, c) {
                                            final row = c.maxWidth >= 520;
                                            final debtCard = _TypePickCard(
                                              title: 'Borclandir',
                                              subtitle:
                                                  'Musteri borcu / satis alacagi artar',
                                              icon: Icons.trending_up_rounded,
                                              color: AppColors.successColor,
                                              selected: _selectedType == 'debt',
                                              onTap: () => setState(
                                                () => _selectedType = 'debt',
                                              ),
                                            );
                                            final payCard = _TypePickCard(
                                              title: 'Odeme / Tahsilat',
                                              subtitle:
                                                  'Tahsilat; alacak bakiyesi azalir',
                                              icon: Icons.trending_down_rounded,
                                              color: AppColors.dangerColor,
                                              selected:
                                                  _selectedType == 'payment',
                                              onTap: () => setState(
                                                () => _selectedType = 'payment',
                                              ),
                                            );
                                            if (row) {
                                              return Row(
                                                children: [
                                                  Expanded(child: debtCard),
                                                  const SizedBox(width: 12),
                                                  Expanded(child: payCard),
                                                ],
                                              );
                                            }
                                            return Column(
                                              children: [
                                                debtCard,
                                                const SizedBox(height: 12),
                                                payCard,
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _GlassCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.payments_rounded,
                                              color: AppColors.primaryColor
                                                  .withAlpha(230),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '3. Tutar ve aciklama',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _amountController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[\d.,]'),
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Tutar (₺)',
                                            hintText: '0,00',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(
                                              Icons.attach_money_rounded,
                                            ),
                                          ),
                                          validator: (v) {
                                            if ((v ?? '').trim().isEmpty) {
                                              return 'Tutar zorunlu';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Hizli tutar',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _quickAmounts.map((a) {
                                            return ActionChip(
                                              avatar: Icon(
                                                Icons.add_rounded,
                                                size: 18,
                                                color: AppColors.primaryColor
                                                    .withAlpha(220),
                                              ),
                                              label: Text(_formatMoney(a)),
                                              onPressed: () {
                                                _amountController.text = a
                                                    .toStringAsFixed(2)
                                                    .replaceAll('.', ',');
                                                setState(() {});
                                              },
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _documentRefController,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Belge / fis no (opsiyonel)',
                                            hintText: 'Fatura no, makbuz...',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(
                                              Icons.receipt_long_rounded,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _descriptionController,
                                          minLines: 2,
                                          maxLines: 5,
                                          decoration: const InputDecoration(
                                            labelText: 'Aciklama',
                                            hintText:
                                                'Islem detayi, urun, donem...',
                                            alignLabelWithHint: true,
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(
                                              Icons.notes_rounded,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  FilledButton.icon(
                                    onPressed: _saving ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 3,
                                      shadowColor: AppColors.primaryColor
                                          .withAlpha(90),
                                    ),
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_circle_rounded,
                                          ),
                                    label: Text(
                                      _saving
                                          ? 'Kaydediliyor...'
                                          : 'Islemi kaydet',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(252),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryColor.withAlpha(26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withAlpha(18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TypePickCard extends StatelessWidget {
  const _TypePickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? color : color.withAlpha(50),
          width: selected ? 2.5 : 1,
        ),
        color: selected ? color.withAlpha(22) : Colors.white.withAlpha(248),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withAlpha(55),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.textColor.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: color, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyClientsCard extends StatelessWidget {
  const _EmptyClientsCard({required this.onAdd, required this.onHome});

  final VoidCallback onAdd;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 56,
            color: AppColors.textColor.withAlpha(120),
          ),
          const SizedBox(height: 16),
          const Text(
            'Islem icin once musteri ekleyin',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Yeni musteri'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.dashboard_rounded),
            label: const Text('Dashboard'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.dangerColor,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}
