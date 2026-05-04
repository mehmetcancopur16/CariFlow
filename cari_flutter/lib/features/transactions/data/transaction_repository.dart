import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository(this._dio);

  final Dio _dio;

  Future<List<TransactionModel>> getClientTransactions(String clientId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.clients}/$clientId/transactions',
    );

    final data = response.data;
    if (data == null) return const [];

    final rawList = data['data'];
    if (rawList is! List) return const [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(TransactionModel.fromJson)
        .toList();
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.transactions,
      data: data,
    );

    final body = response.data;
    if (body == null || body['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid create transaction response');
    }

    return TransactionModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.read(dioProvider));
});
