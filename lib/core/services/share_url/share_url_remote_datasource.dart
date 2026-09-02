import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

class ShareUrlRemoteDatasource {
  ShareUrlRemoteDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;
  final _logger = AppLogger('ShareUrlRemoteDatasource');

  /// POST /share with `{ "url": "<long url>" }` and returns `shortUrl`.
  Future<String> shortenUrl(String url) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/share',
        data: {'url': url},
        options: Options(sendTimeout: const Duration(seconds: 10)),
      );

      final statusCode = response.statusCode;
      if (statusCode == 200 || statusCode == 201) {
        final shortUrl = response.data?['shortUrl'];
        if (shortUrl == null || shortUrl.toString().trim().isEmpty) {
          throw const ServerException('Missing or empty shortUrl in response');
        }
        return shortUrl.toString();
      }

      if (statusCode == 404) {
        throw const NotFoundException('Share endpoint not found');
      }
      if (statusCode == 401) {
        throw const AuthenticationException('Unauthorized');
      }
      if (statusCode == 429) {
        throw const RateLimitException('Too many requests');
      }
      if (statusCode != null && statusCode >= 500) {
        throw ServerException('Server error: $statusCode');
      }
      throw ServerException('HTTP error: $statusCode');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.sendTimeout) {
        throw const NetworkException('Request timeout');
      }
      _logger.error('Network error shortening share URL', e);
      throw const NetworkException('Network error');
    }
  }
}
