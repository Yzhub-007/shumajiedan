import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/error/app_error_log.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class RepairHubApp extends ConsumerWidget {
  const RepairHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '机器报修',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          const AppErrorBanner(),
        ],
      ),
    );
  }
}

/// 叠加在所有页面之上的错误横幅：白屏/卡死时，真实报错会显示在这里。
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: AppErrorLog.errors,
      builder: (context, errors, _) {
        if (errors.isEmpty) return const SizedBox.shrink();
        return Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).padding.top,
          child: Material(
            color: Colors.red.shade700,
            child: SafeArea(
              bottom: false,
              child: InkWell(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('最近 ${errors.length} 条错误',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...errors.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SelectableText(e,
                                style: const TextStyle(fontSize: 12, height: 1.4)),
                          )),
                      FilledButton(
                        onPressed: () {
                          AppErrorLog.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('清除'),
                      ),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '⚠ ${errors.first}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
