class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';

  static const String clients = '/clients';
  static const String clientTransactions = '/clients/{id}/transactions';

  static const String transactions = '/transactions';
  static const String dashboardSummary = '/transactions/dashboard/summary';
}
