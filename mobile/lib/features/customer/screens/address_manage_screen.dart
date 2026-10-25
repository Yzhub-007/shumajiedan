import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 地址管理：增删改、默认地址、定位取坐标（TODO(2.2.5) 接高德地图选点页）。
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
    if (!mounted) return;
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
  late final TextEditingController _lngCtrl;
  late final TextEditingController _latCtrl;
  bool _isDefault = false;
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?['label']?.toString());
    _province = TextEditingController(text: e?['province']?.toString());
    _city = TextEditingController(text: e?['city']?.toString());
    _district = TextEditingController(text: e?['district']?.toString());
    _detail = TextEditingController(text: e?['detail']?.toString());
    final lng = (e?['lng'] as num?)?.toDouble();
    final lat = (e?['lat'] as num?)?.toDouble();
    _lngCtrl = TextEditingController(
        text: lng == null || lng == 0 ? '' : lng.toStringAsFixed(6));
    _latCtrl = TextEditingController(
        text: lat == null || lat == 0 ? '' : lat.toStringAsFixed(6));
    _isDefault = e?['isDefault'] == true;
  }

  @override
  void dispose() {
    _label.dispose();
    _province.dispose();
    _city.dispose();
    _district.dispose();
    _detail.dispose();
    _lngCtrl.dispose();
    _latCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        _askOpen(() => Geolocator.openLocationSettings(), '定位服务未开启',
            '请在系统设置中打开定位服务后重试');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _toast('未授予定位权限，可重试授权或使用手动填写坐标');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _askOpen(() => Geolocator.openAppSettings(), '定位权限被永久拒绝',
            '请在应用设置中允许"机器报修"使用位置信息');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _fillCoords(position.longitude, position.latitude);
      _toast('定位成功');
    } catch (_) {
      _toast('定位超时（室内信号弱）。可再试一次，或展开下方手动填写坐标');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _fillCoords(double lng, double lat) {
    _lngCtrl.text = lng.toStringAsFixed(6);
    _latCtrl.text = lat.toStringAsFixed(6);
  }

  void _askOpen(Future<void> Function() open, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              open();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final detail = _detail.text.trim();
    final lng = double.tryParse(_lngCtrl.text.trim());
    final lat = double.tryParse(_latCtrl.text.trim());
    if (detail.isEmpty) {
      _toast('请填写详细地址');
      return;
    }
    if (lng == null || lat == null) {
      _toast('缺少坐标：请先定位成功，或展开"手动填写坐标"输入');
      return;
    }
    setState(() => _saving = true);
    final body = {
      'label': _label.text.trim(),
      'province': _province.text.trim(),
      'city': _city.text.trim(),
      'district': _district.text.trim(),
      'detail': detail,
      'lng': lng,
      'lat': lat,
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
      _toast('保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message)));
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.gps_fixed, size: 18),
                  label: Text(_locating
                      ? '定位中...'
                      : (_lngCtrl.text.isEmpty ? '使用当前位置' : '重新定位')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('设为默认'),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
              ),
            ]),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('手动填写坐标（定位不可用时）', style: TextStyle(fontSize: 13)),
              children: [
                Row(children: [
                  Expanded(child: TextField(
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '经度', hintText: '如 121.473700'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '纬度', hintText: '如 31.230400'))),
                ]),
                const SizedBox(height: 4),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('取消')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('保存'),
        ),
      ],
    );
  }
}
