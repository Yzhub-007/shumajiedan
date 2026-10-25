import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// 网络层：dio + token 注入 + 统一 ApiResponse 解包 + 401 静默续期（计划书 1.2.2）。
class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
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
  bool _refreshing = false;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _runWithRefresh(() => _dio.get(path, queryParameters: query));
  }

  Future<dynamic> post(String path, {Object? data}) {
    return _runWithRefresh(() => _dio.post(path, data: data));
  }

  Future<dynamic> put(String path, {Object? data}) {
    return _runWithRefresh(() => _dio.put(path, data: data));
  }

  Future<dynamic> delete(String path) {
    return _runWithRefresh(() => _dio.delete(path));
  }

  /// 上传文件（开发环境走 /api/upload 本地落盘；生产可切换 OSS 预签名直传）。
  /// 返回可公网访问的绝对 URL。
  Future<String> upload(String filePath, {String? fileName}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _runWithRefresh(() => _dio.post('/api/upload', data: form));
    final relative = response is Map ? (response['url']?.toString() ?? '') : '';
    if (relative.isEmpty) {
      throw const ApiException(code: -1, message: '上传失败');
    }
    if (relative.startsWith('http')) return relative;
    return AppConfig.apiBaseUrl + relative;
  }

  dynamic _runWithRefresh(Future<Response<dynamic>> Function() run) async {
    try {
      return _unwrap(await run());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && TokenStorage.refreshToken != null) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          return _unwrap(await run());
        }
      }
      rethrow;
    }
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final resp = await dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': TokenStorage.refreshToken},
      );
      final body = resp.data;
      if (body is Map && body['code'] == 0 && body['data'] is Map) {
        final data = body['data'] as Map;
        await TokenStorage.save(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
          role: data['role'] as String,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
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
