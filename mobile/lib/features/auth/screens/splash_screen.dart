import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 启动页：登录态恢复期间展示（重定向由 app_router 处理）。
/// TODO(2.2.1) 启动页视觉与首次引导页。
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.brand, Color(0xFF3E7BC8)],
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.build_circle_outlined,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text('机器报修',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text('设备报修 · 工程师接单平台',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
