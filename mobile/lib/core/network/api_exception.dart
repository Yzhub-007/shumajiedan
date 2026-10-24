/// 后端统一错误：ApiResponse.code != 0。
class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  final int code;
  final String message;

  bool get isUnauthorized => code == 40100;
  bool get isForbidden => code == 40300;

  @override
  String toString() => message;
}
