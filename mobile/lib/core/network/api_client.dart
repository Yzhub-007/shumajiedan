import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// 网络层：dio + token 注入 + 统一 ApiResponse 解包（计划书 1.2.2 脚手架）。
/// TODO(1.2.2) 401 时用 refreshToken 静默续期后重放请求。
class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenStorage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get(path, queryParameters: query);
    return _unwrap(response);
  }

  Future<dynamic> post(String path, {Object? data}) async {
    final response = await _dio.post(path, data: data);
    return _unwrap(response);
  }

  Future<dynamic> put(String path, {Object? data}) async {
    final response = await _dio.put(path, data: data);
    return _unwrap(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _dio.delete(path);
    return _unwrap(response);
  }

  dynamic _unwrap(Response response) {
    final body = response.data;
    if (body is Map && body['code'] is int) {
      final code = body['code'] as int;
      if (code == 0) return body['data'];
      throw ApiException(
        code: code,
        message: body['message']?.toString() ?? '请求失败',
      );
    }
    return body;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
