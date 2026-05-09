import 'package:dio/dio.dart';

class ApiErrorMapper {
  ApiErrorMapper._();

  static String toMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Sunucu yanit vermiyor. Lutfen tekrar deneyin.';
        case DioExceptionType.connectionError:
          return 'Baglanti hatasi. Internetinizi kontrol edin.';
        case DioExceptionType.badResponse:
          return 'Sunucu hatasi olustu.';
        case DioExceptionType.unknown:
          // Web tarafinda CORS/adapter/network sorunlari genelde burada duser.
          return 'Baglanti kurulamadi. Sunucu acik mi ve adres dogru mu kontrol edin.';
        default:
          return 'Beklenmeyen bir hata olustu.';
      }
    }

    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }
}
