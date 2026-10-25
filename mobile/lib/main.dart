import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/server_config.dart';
import 'core/error/app_error_log.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  // 测试期全局错误可视化：任何同步/异步异常都会记录并以横幅显示在页面上。
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await TokenStorage.init();
    await ServerConfig.load();
    FlutterError.onError = (details) {
      AppErrorLog.record(details.exception, details.stack);
      FlutterError.presentError(details);
    };
    runApp(const ProviderScope(child: RepairHubApp()));
  }, (error, stack) => AppErrorLog.record(error, stack));
}
