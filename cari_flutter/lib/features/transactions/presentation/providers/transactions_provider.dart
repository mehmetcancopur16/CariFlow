import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/transaction_model.dart';
import '../../data/transaction_repository.dart';

final transactionsProvider =
    FutureProvider.family<List<TransactionModel>, String>((ref, clientId) {
      return ref
          .read(transactionRepositoryProvider)
          .getClientTransactions(clientId);
    });
