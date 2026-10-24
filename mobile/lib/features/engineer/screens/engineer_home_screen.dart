import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 工程师端首页：接单开关 + 工单池 + 我的工单入口（计划书 3.2.1 / 3.2.2）。
/// TODO(3.2.1) 后台定位服务（Android 前台服务 / iOS always 权限）+ 定时位置上报。
class EngineerHomeScreen extends ConsumerStatefulWidget {
  const EngineerHomeScreen({super.key});

  @override
  ConsumerState<EngineerHomeScreen> createState() => _EngineerHomeScreenState();
}

class _EngineerHomeScreenState extends ConsumerState<EngineerHomeScreen> {
  bool _online = false;
  bool _toggling = false;
  List<dynamic> _pool = [];
  bool _loadingPool = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadPool();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ref
          .read(apiClientProvider)
          .get('/api/engineer/verify-status') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _online = data['onlineStatus'] == true);
      if (data['verifyStatus'] != 'APPROVED') {
        // TODO(2.2.7) 审核状态页引导：PENDING/REJECTED 提示与重新提交入口
      }
    } catch (_) {}
  }

  Future<void> _loadPool() async {
    setState(() => _loadingPool = true);
    try {
      final data =
          await ref.read(apiClientProvider).get('/api/engineer/orders/pool') as List<dynamic>;
      setState(() => _pool = data);
    } catch (_) {
      setState(() => _pool = []);
    } finally {
      if (mounted) setState(() => _loadingPool = false);
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _toggling = true);
    try {
      // TODO(3.2.1) 用 geolocator 取真实定位替换占位坐标
      await ref.read(apiClientProvider).put('/api/engineer/online', data: {
        'online': value,
        'lng': 121.4737,
        'lat': 31.2304,
      });
      setState(() => _online = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _grab(Map<String, dynamic> order) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/api/engineer/orders/${order['id']}/grab');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('抢单成功！')));
      context.push('/engineer/orders/${order['id']}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      _loadPool();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('接单大厅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            secondary: Icon(_online ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                color: _online ? Colors.green : Colors.grey),
            title: Text(_online ? '接单中' : '已下线'),
            subtitle: const Text('上线后才能收到附近工单推送'),
            value: _online,
            onChanged: _toggling ? null : _toggleOnline,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('可抢工单'),
            trailing: IconButton(onPressed: _loadPool, icon: const Icon(Icons.refresh)),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPool,
              child: _loadingPool
                  ? const Center(child: CircularProgressIndicator())
                  : _pool.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 140),
                          EmptyView(icon: Icons.handyman_outlined, text: '附近暂无可抢工单'),
                        ])
                      : ListView.separated(
                          itemCount: _pool.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final order = _pool[index] as Map<String, dynamic>;
                            final distance = order['distanceM'];
                            return ListTile(
                              title: Text(
                                  '${order['deviceCategoryName'] ?? ""} · ${order['faultDesc'] ?? ""}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${distance == null ? "距离未知" : "${(distance as num).toStringAsFixed(0)}m"}'
                                  '${order['urgencyLabel'] == null ? "" : " · ${order['urgencyLabel']}"}'),
                              trailing: FilledButton(
                                onPressed: _online ? () => _grab(order) : null,
                                child: const Text('抢单'),
                              ),
                              onTap: () => context.push('/engineer/orders/${order['id']}'),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
