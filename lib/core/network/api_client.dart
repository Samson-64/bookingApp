import 'dart:async';
import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(_authInterceptor());
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Dio get dio => _dio;

  Interceptor _authInterceptor() => InterceptorsWrapper(
        onRequest: (opts, handler) async {
          final token = await TokenStorage.instance.readToken();
          if (token != null) opts.headers['Authorization'] = 'Bearer $token';
          handler.next(opts);
        },
        onError: (err, handler) async {
          final detail = err.response?.data;
          String? message;
          if (detail is Map) {
            message = detail['detail']?.toString() ?? detail['error']?.toString();
          } else if (detail is String) {
            message = detail;
          }
          if (err.response?.statusCode == 401) {
            await TokenStorage.instance.clear();
          }
          handler.next(
            DioException(
              requestOptions: err.requestOptions,
              response: err.response,
              type: err.type,
              error: ApiException(
                message: message ?? 'Something went wrong. Please try again.',
                statusCode: err.response?.statusCode,
              ),
            ),
          );
        },
      );

  /// Convenience wrapper: throws [ApiException] on failure.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters).catchError(_handle);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data).catchError(_handle);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data).catchError(_handle);

  Never _handle(Object e) {
    if (e is DioException && e.error is ApiException) {
      throw e.error as ApiException;
    }
    throw const ApiException(message: 'Unexpected error. Please try again.');
  }
}
