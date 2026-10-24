import 'package:flutter/material.dart';

/// 启动页：登录态恢复期间展示（重定向由 app_router 处理）。
/// TODO(2.2.1) 启动页视觉与首次引导页。
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_circle_outlined,
                size: 88, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('机器报修', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
