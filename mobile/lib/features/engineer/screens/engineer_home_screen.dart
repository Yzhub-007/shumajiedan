import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 工程师端首页：接单开关 + 工单池 + 我的工单入口（计划书 3.2.1 / 3.2.2）。
/// 上线期间每 15 秒上报一次 GPS（后端 GEO 每次写、DB 节流 60s）。
/// TODO(3.2.1) Android 前台服务保活 / iOS "始终"定位权限，避免退后台后上报中断。
class EngineerHomeScreen extends ConsumerStatefulWidget {
  const EngineerHomeScreen({super.key});

  @override
  ConsumerState<EngineerHomeScreen> createState() => _EngineerHomeScreenState();
}

class _EngineerHomeScreenState extends ConsumerState<EngineerHomeScreen> {
  bool _online = false;
  bool _toggling = false;
  Timer? _locationTimer;
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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      await ref.read(apiClientProvider).put('/api/engineer/online', data: {
        'online': value,
        'lng': position.longitude,
        'lat': position.latitude,
      });
      setState(() => _online = value);
      if (value) {
        _startLocationTimer();
      } else {
        _locationTimer?.cancel();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().contains('permission')
                ? '定位权限未授权，上线需要定位'
                : e.toString())));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  void _startLocationTimer() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        await ref.read(apiClientProvider).post('/api/engineer/location', data: {
          'lng': position.longitude,
          'lat': position.latitude,
        });
      } catch (_) {
        // 定位失败静默跳过，下个周期重试
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LargeTitleHeader(
              title: '接单大厅',
              subtitle: '附近工单实时推送',
              actions: IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                onPressed: () => context.go('/engineer/notifications'),
              ),
            ),
            // 接单状态卡：iOS 开关 + 状态点
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _online ? const Color(0xFF34C759) : scheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_online ? '接单中' : '已下线',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                            _toggling ? '正在更新状态…' : '上线后才能收到附近工单推送',
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (_toggling)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    Switch(
                      value: _online,
                      onChanged: _toggleOnline,
                    ),
                ],
              ),
            ),
            // 工单池标题行
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('可抢工单',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                  ),
                  IconButton(
                      onPressed: _loadPool,
                      icon: const Icon(Icons.refresh, size: 20)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPool,
                child: _loadingPool
                    ? const Center(child: CircularProgressIndicator())
                    : _pool.isEmpty
                        ? ListView(children: const [
                            SizedBox(height: 140),
                            EmptyView(
                                icon: Icons.handyman_outlined,
                                text: '附近暂无可抢工单'),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 116),
                            itemCount: _pool.length,
                            itemBuilder: (context, index) {
                              final order = _pool[index] as Map<String, dynamic>;
                              final distance = order['distanceM'];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${order['deviceCategoryName'] ?? "设备维修"}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(
                                              order['faultDesc']?.toString() ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: scheme
                                                      .onSurfaceVariant)),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: scheme
                                                      .onSurfaceVariant
                                                      .withAlpha(16),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                    '${distance == null ? "距离未知" : "${(distance as num).toStringAsFixed(0)}m"}'
                                                    '${order['urgencyLabel'] == null ? "" : " · ${order['urgencyLabel']}"}',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: scheme
                                                            .onSurfaceVariant)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      height: 36,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets
                                              .symmetric(horizontal: 18),
                                          textStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        onPressed: _online
                                            ? () => _grab(order)
                                            : null,
                                        child: const Text('抢单'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
