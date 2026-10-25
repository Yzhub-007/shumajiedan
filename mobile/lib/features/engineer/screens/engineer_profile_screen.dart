import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/controllers/auth_controller.dart';

/// 工程师个人中心：资质状态、接单统计、提现（展示用）（计划书 2.2.7 / 3.2.4）。
class EngineerProfileScreen extends ConsumerStatefulWidget {
  const EngineerProfileScreen({super.key});

  @override
  ConsumerState<EngineerProfileScreen> createState() =>
      _EngineerProfileScreenState();
}

class _EngineerProfileScreenState extends ConsumerState<EngineerProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ref
          .read(apiClientProvider)
          .get('/api/engineer/verify-status') as Map<String, dynamic>;
      setState(() => _profile = profile);
    } catch (_) {}
    try {
      final stats =
          await ref.read(apiClientProvider).get('/api/engineer/stats') as Map<String, dynamic>;
      setState(() => _stats = stats);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final status = _profile?['verifyStatus']?.toString() ?? 'PENDING';
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.engineering)),
            title: Text(_profile?['realName']?.toString() ?? '未认证工程师'),
            subtitle: Text(switch (status) {
              'APPROVED' => '已认证',
              'REJECTED' => '认证未通过',
              _ => '审核中',
            }),
          ),
          const Divider(),
          SectionCard(
            title: '接单统计',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('累计接单', '${_stats?['totalOrders'] ?? 0}'),
                _stat('已完成', '${_stats?['completedOrders'] ?? 0}'),
                _stat('评分', '${_stats?['ratingAvg'] ?? "-"}'),
                _stat('累计收入', '¥${_stats?['totalIncome'] ?? 0}'),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('资质认证'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/engineer/verify'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('我的钱包 / 提现'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/engineer/wallet'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('消息中心'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
