import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 地址管理：增删改、默认地址、地图选点（当前用 GPS 定位占位，TODO(2.2.5) 接高德地图选点页）。
class AddressManageScreen extends ConsumerStatefulWidget {
  const AddressManageScreen({super.key});

  @override
  ConsumerState<AddressManageScreen> createState() => _AddressManageScreenState();
}

class _AddressManageScreenState extends ConsumerState<AddressManageScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          await ref.read(apiClientProvider).get('/api/customer/addresses') as List<dynamic>;
      setState(() => _addresses = data.cast<Map<String, dynamic>>());
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openEditor([Map<String, dynamic>? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AddressEditor(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除地址'),
        content: Text('确定删除「${address['label'] ?? address['detail']}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).delete('/api/customer/addresses/${address['id']}');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地址管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('新增地址'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _addresses.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 160),
                    EmptyView(icon: Icons.location_off_outlined, text: '还没有常用地址'),
                  ])
                : ListView.separated(
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = _addresses[index];
                      final isDefault = a['isDefault'] == true;
                      return ListTile(
                        leading: Icon(
                          isDefault ? Icons.home_outlined : Icons.location_on_outlined,
                          color: isDefault ? Theme.of(context).colorScheme.primary : null,
                        ),
                        title: Text('${a['label'] ?? "地址"}${isDefault ? "（默认）" : ""}'),
                        subtitle: Text(
                          '${a["province"] ?? ""}${a["city"] ?? ""}${a["district"] ?? ""} ${a["detail"] ?? ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'edit') {
                              _openEditor(a);
                            } else if (action == 'default') {
                              try {
                                await ref.read(apiClientProvider).put(
                                      '/api/customer/addresses/${a['id']}',
                                      data: {
                                        'label': a['label'],
                                        'province': a['province'],
                                        'city': a['city'],
                                        'district': a['district'],
                                        'detail': a['detail'],
                                        'lng': a['lng'],
                                        'lat': a['lat'],
                                        'isDefault': true,
                                      },
                                    );
                                _load();
                              } catch (e) {
                                _toast(e.toString());
                              }
                            } else if (action == 'delete') {
                              _delete(a);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('编辑')),
                            PopupMenuItem(value: 'default', child: Text('设为默认')),
                            PopupMenuItem(value: 'delete', child: Text('删除')),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _AddressEditor extends ConsumerStatefulWidget {
  const _AddressEditor({this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends ConsumerState<_AddressEditor> {
  late final TextEditingController _label;
  late final TextEditingController _province;
  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _detail;
  double? _lng;
  double? _lat;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?['label']?.toString());
    _province = TextEditingController(text: e?['province']?.toString());
    _city = TextEditingController(text: e?['city']?.toString());
    _district = TextEditingController(text: e?['district']?.toString());
    _detail = TextEditingController(text: e?['detail']?.toString());
    _lng = (e?['lng'] as num?)?.toDouble();
    _lat = (e?['lat'] as num?)?.toDouble();
    _isDefault = e?['isDefault'] == true;
  }

  @override
  void dispose() {
    _label.dispose();
    _province.dispose();
    _city.dispose();
    _district.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      setState(() {
        _lng = position.longitude;
        _lat = position.latitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已获取定位（${_lng!.toStringAsFixed(5)}, ${_lat!.toStringAsFixed(5)}）')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('定位失败，请检查定位权限')));
      }
    }
  }

  Future<void> _save() async {
    if (_detail.text.trim().isEmpty || _lng == null || _lat == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写详细地址并获取坐标')));
      return;
    }
    setState(() => _saving = true);
    final body = {
      'label': _label.text.trim(),
      'province': _province.text.trim(),
      'city': _city.text.trim(),
      'district': _district.text.trim(),
      'detail': _detail.text.trim(),
      'lng': _lng,
      'lat': _lat,
      'isDefault': _isDefault,
    };
    try {
      final api = ref.read(apiClientProvider);
      final id = widget.existing?['id'];
      if (id == null) {
        await api.post('/api/customer/addresses', data: body);
      } else {
        await api.put('/api/customer/addresses/$id', data: body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '新增地址' : '编辑地址'),
      content: SizedBox(
        width: 320,
        child: ListView(
          shrinkWrap: true,
          children: [
            TextField(controller: _label, decoration: const InputDecoration(labelText: '标签（如：厂区东门）')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _province, decoration: const InputDecoration(labelText: '省'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _city, decoration: const InputDecoration(labelText: '市'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _district, decoration: const InputDecoration(labelText: '区'))),
            ]),
            const SizedBox(height: 8),
            TextField(controller: _detail, decoration: const InputDecoration(labelText: '详细地址')),
            const SizedBox(height: 8),
            Row(children: [
              OutlinedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.gps_fixed, size: 18),
                label: Text(_lng == null ? '使用当前位置' : '已定位'),
              ),
              const Spacer(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('默认地址'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('保存')),
      ],
    );
  }
}
