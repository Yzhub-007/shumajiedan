import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/common_widgets.dart';

/// 客户端首页：快捷发单入口 + 进行中工单卡片（计划书 2.2.2）。
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('机器报修'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 快捷发单入口
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/customer/create-order'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('设备故障？立即报修',
                            style: TextStyle(color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('附近工程师快速响应，全程可追踪',
                            style: TextStyle(color: Colors.white.withAlpha(200))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '进行中工单',
            trailing: TextButton(
              onPressed: () => context.push('/customer/orders'),
              child: const Text('全部'),
            ),
            child: const Text('首页进行中工单卡片列表',
                style: TextStyle(color: Colors.grey)),
            // TODO(2.2.2) GET /api/orders 拉取进行中工单，展示状态与工程师进度
          ),
          SectionCard(
            title: '常用功能',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(icon: Icons.receipt_long, label: '我的工单',
                    onTap: () => context.push('/customer/orders')),
                _QuickAction(icon: Icons.location_on_outlined, label: '地址管理',
                    onTap: () {/* TODO(2.2.5) 地址管理页 */}),
                _QuickAction(icon: Icons.business_outlined, label: '企业信息',
                    onTap: () => context.push('/customer/profile')),
                _QuickAction(icon: Icons.person_outline, label: '我的',
                    onTap: () => context.push('/customer/profile')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
