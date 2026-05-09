import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    return 'http://10.0.2.2:3000/api';
  }

  /// Origin without `/api` (e.g. health + Swagger live on the root server).
  static String get serverOrigin => Uri.parse(baseUrl).origin;

  static String get healthUrl => '$serverOrigin/health';

  static String get swaggerUrl => '$serverOrigin/api-docs/';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';

  static const String userMe = '/users/me';
  static const String userChangePassword = '/users/change-password';

  static const String clients = '/clients';
  static const String clientTransactions = '/clients/{id}/transactions';

  static const String transactions = '/transactions';
  static const String dashboardSummary = '/transactions/dashboard/summary';
}
