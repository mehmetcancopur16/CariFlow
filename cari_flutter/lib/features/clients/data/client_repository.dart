import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/client_model.dart';

class ClientRepository {
  ClientRepository(this._dio);

  final Dio _dio;

  Future<List<ClientModel>> getClients() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiConstants.clients);
    final data = response.data;
    if (data == null) return const [];

    final rawList = data['data'];
    if (rawList is! List) return const [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ClientModel.fromJson)
        .toList();
  }

  Future<ClientModel> createClient(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.clients,
      data: payload,
    );

    final data = response.data;
    if (data == null || data['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid create client response');
    }

    return ClientModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ClientModel> getClientById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.clients}/$id',
    );

    final data = response.data;
    if (data == null || data['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid client detail response');
    }

    return ClientModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ClientModel> updateClient(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '${ApiConstants.clients}/$id',
      data: payload,
    );

    final data = response.data;
    if (data == null || data['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid update client response');
    }

    return ClientModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteClient(String id) async {
    await _dio.delete<Map<String, dynamic>>('${ApiConstants.clients}/$id');
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.read(dioProvider));
});
