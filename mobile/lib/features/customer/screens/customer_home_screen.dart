import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 客户端首页：快捷发单入口 + 进行中工单卡片（计划书 2.2.2）。
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            LargeTitleHeader(
              title: '机器报修',
              subtitle: '设备故障，一键找工程师',
              actions: IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                onPressed: () => context.push('/notifications'),
              ),
            ),
            // 快捷发单入口
            GestureDetector(
              onTap: () => context.push('/customer/create-order'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.brand, Color(0xFF3E7BC8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withAlpha(70),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('设备故障？立即报修',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('附近工程师快速响应，全程可追踪',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 13)),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(46),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: 15, color: Colors.white),
                                SizedBox(width: 3),
                                Text('发布维修工单',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.handyman_outlined,
                        size: 76, color: Colors.white.withAlpha(52)),
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
              child: Column(
                children: [
                  Icon(Icons.schedule,
                      size: 30, color: scheme.onSurfaceVariant.withAlpha(120)),
                  const SizedBox(height: 8),
                  Text('暂无进行中工单',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text('发布工单后可在这里实时查看维修进度',
                      style: TextStyle(
                          fontSize: 11, color: scheme.outline)),
                ],
              ),
              // TODO(2.2.2) GET /api/orders 拉取进行中工单，展示状态与工程师进度
            ),
            SectionCard(
              title: '常用功能',
              child: Row(
                children: [
                  _QuickAction(
                      icon: Icons.receipt_long,
                      label: '我的工单',
                      onTap: () => context.push('/customer/orders')),
                  _QuickAction(
                      icon: Icons.location_on_outlined,
                      label: '地址管理',
                      onTap: () => context.push('/customer/addresses')),
                  _QuickAction(
                      icon: Icons.notifications_none,
                      label: '消息中心',
                      onTap: () => context.push('/notifications')),
                  _QuickAction(
                      icon: Icons.person_outline,
                      label: '个人中心',
                      onTap: () => context.push('/customer/profile')),
                ],
              ),
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: scheme.primary),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
