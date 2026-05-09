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

    return rawList.map((dynamic e) {
      final map = e is Map<String, dynamic>
          ? e
          : Map<String, dynamic>.from(e as Map);
      return TransactionModel.fromJson(map);
    }).toList();
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

  Future<void> deleteTransaction(String transactionId) async {
    await _dio.delete<Map<String, dynamic>>(
      '${ApiConstants.transactions}/$transactionId',
    );
  }

  Future<TransactionModel> updateTransaction(
    String transactionId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '${ApiConstants.transactions}/$transactionId',
      data: body,
    );
    final res = response.data;
    if (res == null || res['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid update transaction response');
    }
    return TransactionModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.read(dioProvider));
});
