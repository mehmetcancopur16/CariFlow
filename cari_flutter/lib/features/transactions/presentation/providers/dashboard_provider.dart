import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dashboard_repository.dart';
import '../../data/models/dashboard_summary_model.dart';

final dashboardProvider = FutureProvider<DashboardSummaryModel>((ref) {
  return ref.read(dashboardRepositoryProvider).getSummary();
});
