import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/dashboard_summary_model.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSummaryModel> getSummary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.dashboardSummary,
    );

    final body = response.data;
    if (body == null || body['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid dashboard summary response');
    }

    return DashboardSummaryModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(dioProvider));
});
