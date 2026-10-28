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
    final scheme = Theme.of(context).colorScheme;
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
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 116),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index] as Map<String, dynamic>;
                      final unread = item['read'] != true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: unread
                                  ? scheme.primary.withAlpha(22)
                                  : scheme.onSurfaceVariant.withAlpha(14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_outlined,
                              size: 20,
                              color: unread
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(item['title']?.toString() ?? '',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: unread
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(item['body']?.toString() ?? '',
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          trailing: unread
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: scheme.primary,
                                      shape: BoxShape.circle))
                              : null,
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
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
