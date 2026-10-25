import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../notification/realtime_service.dart';

/// 客户端工单详情：状态时间轴 + 工程师卡片（拨号）+ 报价确认 + 维修报告 + 评价（计划书 3.2.5 / 3.2.6）。
/// 订阅 WebSocket /topic/order/{id}，状态变更自动刷新。
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
    RealtimeService.instance.subscribeOrder(widget.orderId, (_) => _load());
  }

  @override
  void dispose() {
    RealtimeService.instance.unsubscribeOrder(widget.orderId);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ref
          .read(apiClientProvider)
          .get('/api/orders/${widget.orderId}') as Map<String, dynamic>;
      if (mounted) setState(() => _detail = data);
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

  Future<void> _callEngineer(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无联系电话')));
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法发起拨号')));
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showReviewSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(orderId: widget.orderId),
    );
    if (result == true) {
      _toast('评价成功，感谢反馈');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _detail?['order'] as Map<String, dynamic>?;
    final status = order?['status']?.toString() ?? '';
    final logs = (_detail?['statusLogs'] as List<dynamic>? ?? []);
    final engineer = _detail?['engineer'] as Map<String, dynamic>?;
    final report = _detail?['report'] as Map<String, dynamic>?;

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
                if ((order?['mediaUrls'] as List<dynamic>? ?? []).isNotEmpty)
                  SectionCard(
                    title: '故障照片',
                    child: SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: (order?['mediaUrls'] as List).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                              (order!['mediaUrls'] as List)[index].toString(),
                              width: 90, height: 90, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 90, height: 90)),
                        ),
                      ),
                    ),
                  ),
                if (engineer != null)
                  SectionCard(
                    title: '服务工程师',
                    trailing: TextButton.icon(
                      onPressed: () => _callEngineer(engineer['phone']?.toString()),
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: const Text('联系'),
                    ),
                    child: Text(
                        '${engineer['realName'] ?? engineer['phone'] ?? ""}\n'
                        '评分 ${engineer['ratingAvg'] ?? "-"} · 完成 ${engineer['orderCount'] ?? 0} 单'),
                    // TODO(3.2.5) 前往中实时地图（engineer-location 轮询渲染到高德地图）
                  ),
                if (report != null)
                  SectionCard(
                    title: '维修报告',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('诊断：${report['diagnosis'] ?? "-"}'),
                        const SizedBox(height: 4),
                        Text('方案：${report['solution'] ?? "-"}'),
                        const SizedBox(height: 8),
                        _photoGrid('维修后照片', report['afterPhotos']),
                      ],
                    ),
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
                _buildActions(status, order),
              ],
            ),
    );
  }

  Widget _photoGrid(String title, dynamic photos) {
    final list = (photos as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(list[index], width: 90, height: 90, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(String status, Map<String, dynamic>? order) {
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
        final pendingQuotes = quotes.where((q) => q['status'] == 'PENDING').toList();
        if (pendingQuotes.isEmpty) return const SizedBox.shrink();
        final pendingQuote = pendingQuotes.first;
        return SectionCard(
          title: '维修报价（工时+配件）',
          child: Column(children: [
            Text('合计 ¥${pendingQuote['total']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      case 'PENDING_PAYMENT':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: _acting
                ? null
                : () => _action('/pay',
                    body: {'channel': 'MOCK'},
                    successMsg: '支付成功'),
            icon: const Icon(Icons.payment_outlined),
            label: Text('去支付 ¥${order?['finalAmount'] ?? order?['quoteAmount'] ?? ""}'),
          ),
        );
      case 'COMPLETED':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton(
            onPressed: _acting ? null : _showReviewSheet,
            child: const Text('评价本次服务'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 评价面板（计划书 3.2.6）：星级 + 标签 + 文字。
class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.orderId});

  final int orderId;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  static const _tagOptions = ['专业高效', '沟通顺畅', '准时到达', '收费合理', '着装规范'];

  int _score = 5;
  final Set<String> _tags = {};
  final _contentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/api/orders/${widget.orderId}/review', data: {
        'score': _score,
        'tags': _tags.toList(),
        'content': _contentController.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('评价本次服务', style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _score ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => setState(() => _score = index + 1),
              );
            }),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _tagOptions
                .map((tag) => FilterChip(
                      label: Text(tag),
                      selected: _tags.contains(tag),
                      onSelected: (selected) => setState(() {
                        selected ? _tags.add(tag) : _tags.remove(tag);
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
                labelText: '说点什么（选填）', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: '提交评价', onPressed: _submit, loading: _submitting),
        ],
      ),
    );
  }
}
