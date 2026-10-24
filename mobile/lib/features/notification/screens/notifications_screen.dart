import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 通知中心（计划书 2.2.7 / 3.2.7：推送点击跳转对应工单）。
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(apiClientProvider).get('/api/notifications') as Map<String, dynamic>;
      setState(() => _items = data['list'] as List<dynamic>? ?? []);
    } catch (_) {
      // 网络错误静默，页面展示空态
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息中心')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 160),
                    EmptyView(text: '暂无消息'),
                  ])
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index] as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(item['title']?.toString() ?? ''),
                        subtitle: Text(item['body']?.toString() ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: (item['read'] == true)
                            ? null
                            : Container(width: 8, height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle)),
                        onTap: () async {
                          // TODO(3.2.7) 按 data.orderId 跳转对应工单详情并标记已读
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
