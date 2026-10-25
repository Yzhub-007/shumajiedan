import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
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
      appBar: AppBar(
        title: const Text('消息中心'),
        actions: [
          TextButton(
            onPressed: _items.isEmpty
                ? null
                : () async {
                    try {
                      await ref.read(apiClientProvider).post('/api/notifications/read-all');
                      _load();
                    } catch (_) {}
                  },
            child: const Text('全部已读'),
          ),
        ],
      ),
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
                          // 计划书 3.2.7：标记已读并按身份跳转对应工单
                          final data = item['data'] as Map<String, dynamic>?;
                          final orderId = data?['orderId'];
                          try {
                            await ref
                                .read(apiClientProvider)
                                .post('/api/notifications/${item['id']}/read');
                          } catch (_) {}
                          if (!context.mounted) return;
                          if (orderId is int) {
                            final isEngineer = TokenStorage.role == 'ENGINEER';
                            context.push(isEngineer
                                ? '/engineer/orders/$orderId'
                                : '/customer/orders/$orderId');
                          } else {
                            _load();
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
