import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 客户端工单详情：状态时间轴 + 工程师卡片 + 操作按钮（计划书 2.2.4 / 3.2.5 / 3.2.6）。
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(apiClientProvider)
          .get('/api/orders/${widget.orderId}') as Map<String, dynamic>;
      setState(() => _detail = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _action(String path, {Object? body, String? successMsg}) async {
    setState(() => _acting = true);
    try {
      await ref.read(apiClientProvider).post('/api/orders/${widget.orderId}$path',
          data: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMsg ?? '操作成功')));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _detail?['order'] as Map<String, dynamic>?;
    final status = order?['status']?.toString() ?? '';
    final logs = (_detail?['statusLogs'] as List<dynamic>? ?? []);
    final engineer = _detail?['engineer'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: Text(order?['statusLabel']?.toString() ?? '工单详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                SectionCard(
                  title: '故障信息',
                  child: Text(
                      '${order?['deviceCategoryName'] ?? ""} ${order?['deviceBrand'] ?? ""}\n'
                      '${order?['faultDesc'] ?? ""}'),
                ),
                if (engineer != null)
                  SectionCard(
                    title: '服务工程师',
                    trailing: TextButton(
                      onPressed: () {/* TODO(2.2.x) 拨号联系 */},
                      child: const Text('联系'),
                    ),
                    child: Text(
                        '${engineer['realName'] ?? engineer['phone'] ?? ""}\n'
                        '评分 ${engineer['ratingAvg'] ?? "-"} · 完成 ${engineer['orderCount'] ?? 0} 单'),
                    // TODO(3.2.5) 已接单页：拨号、地图实时位置（GET engineer-location 10s 轮询或 WS）
                  ),
                SectionCard(
                  title: '进度',
                  child: Column(
                    children: logs
                        .map((log) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.check_circle_outline, size: 20),
                              title: Text(
                                  '${log['fromStatusLabel'] ?? ""} → ${log['toStatusLabel'] ?? ""}'),
                              subtitle: Text(log['remark']?.toString() ?? ''),
                              trailing: Text(log['createdAt']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                _buildActions(status),
              ],
            ),
    );
  }

  Widget _buildActions(String status) {
    switch (status) {
      case 'PENDING':
      case 'ACCEPTED':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton(
            onPressed: _acting ? null : () => _action('/cancel',
                body: {'reason': '客户主动取消'}, successMsg: '已取消'),
            child: const Text('取消工单'),
          ),
        );
      case 'ARRIVED':
        final quotes = _detail?['quotes'] as List<dynamic>? ?? [];
        final pendingQuote = quotes.isEmpty
            ? null
            : quotes.firstWhere((q) => q['status'] == 'PENDING', orElse: () => null);
        if (pendingQuote == null) return const SizedBox.shrink();
        return SectionCard(
          title: '维修报价（工时+配件）',
          child: Column(children: [
            Text('合计 ¥${pendingQuote['total']}'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton(
                  onPressed: _acting ? null : () =>
                      _action('/quotes/${pendingQuote['id']}/reject',
                          successMsg: '已拒绝，可等待工程师重新报价'),
                  child: const Text('拒绝'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(
                  onPressed: _acting ? null : () =>
                      _action('/quotes/${pendingQuote['id']}/accept',
                          successMsg: '已确认报价，维修开始'),
                  child: const Text('确认报价'))),
            ]),
          ]),
        );
      case 'PENDING_CONFIRM':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: _acting ? null : () => _action('/reject-finish',
                    body: {'reason': '维修未完成'}, successMsg: '已退回返修'),
                child: const Text('验收不通过'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(
                onPressed: _acting ? null : () => _action('/confirm',
                    successMsg: '验收通过'),
                child: const Text('验收通过'))),
          ]),
        );
      case 'COMPLETED':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton(
            onPressed: _acting ? null : () {/* TODO(3.2.6) 评价页：星级+标签+文字 */},
            child: const Text('评价本次服务'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
