import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final status = _profile?['verifyStatus']?.toString() ?? 'PENDING';
    final statusLabel = switch (status) {
      'APPROVED' => '已认证',
      'REJECTED' => '认证未通过',
      _ => '审核中',
    };
    final statusColor = switch (status) {
      'APPROVED' => const Color(0xFF34C759),
      'REJECTED' => const Color(0xFFFF3B30),
      _ => const Color(0xFFFF9500),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 32),
        children: [
          // 资料卡
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E5AA8), Color(0xFF3E7BC8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.engineering, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile?['realName']?.toString() ?? '未认证工程师',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: scheme.outline),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 接单统计
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _stat(context, '累计接单', '${_stats?['totalOrders'] ?? 0}'),
                _divider(scheme),
                _stat(context, '已完成', '${_stats?['completedOrders'] ?? 0}'),
                _divider(scheme),
                _stat(context, '评分', '${_stats?['ratingAvg'] ?? "-"}'),
                _divider(scheme),
                _stat(context, '累计收入', '¥${_stats?['totalIncome'] ?? 0}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GroupCard(
            separatorIndent: 60,
            children: [
              ListTile(
                leading: const TintedIconBox(icon: Icons.badge_outlined, size: 28),
                title: const Text('资质认证'),
                trailing:
                    Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                onTap: () => context.push('/engineer/verify'),
              ),
              ListTile(
                leading: TintedIconBox(
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.systemGreen,
                    size: 28),
                title: const Text('我的钱包 / 提现'),
                trailing:
                    Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                onTap: () => context.push('/engineer/wallet'),
              ),
              ListTile(
                leading: TintedIconBox(
                    icon: Icons.notifications_outlined,
                    color: AppTheme.systemOrange,
                    size: 28),
                title: const Text('消息中心'),
                trailing:
                    Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: scheme.error,
                  textStyle:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                },
                child: const Text('退出登录'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme scheme) {
    return Container(width: 0.5, height: 28, color: scheme.outlineVariant);
  }

  Widget _stat(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
