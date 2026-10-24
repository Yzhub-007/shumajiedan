import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 工单列表：Tab 分状态、下拉刷新、分页（计划书 2.2.4）。
class CustomerOrderListScreen extends ConsumerStatefulWidget {
  const CustomerOrderListScreen({super.key});

  @override
  ConsumerState<CustomerOrderListScreen> createState() =>
      _CustomerOrderListScreenState();
}

class _CustomerOrderListScreenState extends ConsumerState<CustomerOrderListScreen> {
  String _filter = 'all';
  List<OrderModel> _orders = [];
  bool _loading = true;

  static const _filters = <String, String>{
    'all': '全部',
    'in_progress': '进行中',
    'PENDING_CONFIRM': '待验收',
    'COMPLETED': '已完成',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final query = <String, dynamic>{'page': 1, 'size': 20};
      // 进行中 = 后端按状态逐一查，这里简化为全部拉取后本地过滤
      final data = await ref.read(apiClientProvider).get('/api/orders', query: query)
          as Map<String, dynamic>;
      final list = (data['list'] as List<dynamic>? ?? [])
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _orders = _filter == 'all'
          ? list
          : list.where((o) => _matchFilter(o)).toList());
    } catch (_) {
      setState(() => _orders = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _matchFilter(OrderModel o) {
    switch (_filter) {
      case 'in_progress':
        return o.status == 'PENDING' || o.status == 'ACCEPTED' ||
            o.status == 'ON_THE_WAY' || o.status == 'ARRIVED' ||
            o.status == 'REPAIRING';
      default:
        return o.status == _filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的工单')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filters.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _filter == entry.key,
                          onSelected: (_) {
                            setState(() => _filter = entry.key);
                            _load();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 160),
                          EmptyView(text: '暂无工单'),
                        ])
                      : ListView.separated(
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return ListTile(
                              title: Text(
                                  '${order.deviceCategoryName ?? "设备维修"} · ${order.faultDesc}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${order.statusLabel}${order.addressText == null ? "" : " · ${order.addressText}"}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: StatusTag(
                                  text: order.statusLabel,
                                  color: StatusTag.colorOfKind(
                                      order.statusKind.name, context)),
                              onTap: () => context.push('/customer/orders/${order.id}'),
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
