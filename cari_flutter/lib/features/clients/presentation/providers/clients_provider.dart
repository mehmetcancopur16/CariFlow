import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/client_repository.dart';
import '../../data/models/client_model.dart';

class ClientsNotifier extends AsyncNotifier<List<ClientModel>> {
  @override
  Future<List<ClientModel>> build() {
    return ref.read(clientRepositoryProvider).getClients();
  }

  Future<void> addClient(Map<String, dynamic> payload) async {
    final previous = state.when(
      data: (value) => value,
      loading: () => const <ClientModel>[],
      error: (_, __) => const <ClientModel>[],
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final created = await ref
          .read(clientRepositoryProvider)
          .createClient(payload);
      return [created, ...previous];
    });
  }

  Future<void> refreshClients() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(clientRepositoryProvider).getClients(),
    );
  }
}

final clientsNotifierProvider =
    AsyncNotifierProvider<ClientsNotifier, List<ClientModel>>(
      ClientsNotifier.new,
    );

final clientByIdProvider = FutureProvider.family<ClientModel, String>((
  ref,
  id,
) {
  return ref.read(clientRepositoryProvider).getClientById(id);
});
