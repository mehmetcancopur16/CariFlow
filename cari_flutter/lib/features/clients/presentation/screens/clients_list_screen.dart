import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/client_model.dart';
import '../providers/clients_provider.dart';

class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  Future<void> _showAddClientDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Musteri Ekle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Ad alani bos olamaz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final payload = <String, dynamic>{
                  'name': nameController.text.trim(),
                };
                final phone = phoneController.text.trim();
                if (phone.isNotEmpty) {
                  payload['phone'] = phone;
                }

                await ref
                    .read(clientsNotifierProvider.notifier)
                    .addClient(payload);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsState = ref.watch(clientsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CariFlow'),
        actions: [
          IconButton(
            tooltip: 'Cikis Yap',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: clientsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Bir hata olustu: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.dangerColor),
          ),
        ),
        data: (clients) {
          if (clients.isEmpty) {
            return const Center(child: Text('Henuz musteri eklenmedi'));
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(clientsNotifierProvider.notifier).refreshClients(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Card(
                  child: ListTile(
                    onTap: () => context.go('/client/${client.id}'),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryColor.withAlpha(30),
                      child: Text(
                        client.name.isNotEmpty
                            ? client.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                    title: Text(client.name),
                    subtitle: Text(_subtitle(client)),
                    trailing: Text(
                      _formatCurrency(client.currentBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _balanceColor(client.currentBalance),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClientDialog(context, ref),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
