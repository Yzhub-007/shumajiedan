import 'package:flutter/foundation.dart';

/// 全局错误收集：测试期让白屏/静默异常"显形"——
/// 异常内容会以红色横幅形式叠加显示在任意页面上方（正式版可移除）。
class AppErrorLog {
  AppErrorLog._();

  static final ValueNotifier<List<String>> errors = ValueNotifier<List<String>>([]);

  static void record(Object error, [StackTrace? stack]) {
    final line = '[${DateTime.now().toString().substring(11, 19)}] $error'
        '${stack == null ? "" : "\n${stack.toString().split("\n").take(4).join("\n")}"}';
    final list = List<String>.from(errors.value)..insert(0, line);
    if (list.length > 8) list.removeLast();
    errors.value = list;
    debugPrint('APP ERROR: $error');
  }

  static void clear() => errors.value = [];
}
