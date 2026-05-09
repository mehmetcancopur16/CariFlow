import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
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
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'debt';
  String? _clientId;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null || _clientId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Musteri secin')));
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gecerli bir tutar girin')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(transactionRepositoryProvider).createTransaction({
        'clientId': _clientId,
        'type': _selectedType,
        'amount': amount,
        'description': _descriptionController.text.trim(),
      });

      ref.invalidate(clientsNotifierProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Islem kaydedildi')));
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorMapper.toMessage(e))));
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
              AppColors.primaryColor.withAlpha(18),
              AppColors.backgroundColor,
              AppColors.successColor.withAlpha(14),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.96, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(252),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primaryColor.withAlpha(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withAlpha(22),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hizli Islem',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      Text(
                                        'Musteri secin, borclandirma veya odeme girin',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textColor
                                                  .withAlpha(150),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            clientsAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (e, _) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ApiErrorMapper.toMessage(e),
                                    style: const TextStyle(
                                      color: AppColors.dangerColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () => context.go('/'),
                                      icon: const Icon(Icons.dashboard_rounded),
                                      label: const Text('Dashboard'),
                                    ),
                                  ),
                                ],
                              ),
                              data: (clients) {
                                if (clients.isEmpty) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Once bir musteri ekleyin.',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: () =>
                                            context.go('/clients/new'),
                                        icon: const Icon(
                                          Icons.person_add_alt_1_rounded,
                                        ),
                                        label: const Text('Musteri Ekle'),
                                      ),
                                      const SizedBox(height: 20),
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () => context.go('/'),
                                          icon: const Icon(
                                            Icons.dashboard_rounded,
                                          ),
                                          label: const Text('Dashboard'),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final effectiveClientId =
                                    _clientId != null &&
                                        clients.any((c) => c.id == _clientId)
                                    ? _clientId
                                    : null;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Musteri',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.groups_rounded),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          hint: const Text('Musteri secin'),
                                          value: effectiveClientId,
                                          items: clients
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c.id,
                                                  child: Text(
                                                    c.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) => setState(
                                            () => _clientId = v,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment<String>(
                                          value: 'debt',
                                          label: Text('Borclandir'),
                                          icon: Icon(Icons.trending_up_rounded),
                                        ),
                                        ButtonSegment<String>(
                                          value: 'payment',
                                          label: Text('Odeme Al'),
                                          icon: Icon(
                                            Icons.trending_down_rounded,
                                          ),
                                        ),
                                      ],
                                      selected: {_selectedType},
                                      onSelectionChanged: (s) {
                                        setState(() => _selectedType = s.first);
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Tutar',
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
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _descriptionController,
                                      minLines: 2,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: 'Aciklama',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.notes_rounded),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _saving ? null : _submit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        icon: _saving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(Icons.check_rounded),
                                        label: Text(
                                          _saving
                                              ? 'Kaydediliyor...'
                                              : 'Kaydet',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: () => context.go('/'),
                                        icon: const Icon(
                                          Icons.dashboard_rounded,
                                        ),
                                        label: const Text('Dashboard'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
