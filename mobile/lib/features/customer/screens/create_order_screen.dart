import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 发布工单（计划书 2.2.3，完整实现 4 人天）：
/// 设备类型选择器、故障描述、拍照/相册/视频上传（压缩、进度）、地图选点、
/// 时间选择、紧急程度。
class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _descController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  int? _categoryId;
  String _urgency = 'NORMAL';
  int? _addressId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    _descController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ref.read(apiClientProvider).get('/api/device-categories') as List<dynamic>;
      setState(() {
        _categories = data.cast<Map<String, dynamic>>();
        if (_categories.isNotEmpty) _categoryId = _categories.first['id'] as int;
      });
    } catch (_) {/* 空态由下拉框展示 */}
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final data = await ref.read(apiClientProvider).get('/api/customer/addresses') as List<dynamic>;
      final list = data.cast<Map<String, dynamic>>();
      if (list.isEmpty) return;
      final first = list.firstWhere((a) => a['isDefault'] == true, orElse: () => list.first);
      setState(() => _addressId = first['id'] as int);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_categoryId == null || _addressId == null ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请完善设备类型、服务地址与故障描述')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/api/orders', data: {
        'deviceCategoryId': _categoryId,
        'deviceBrand': _brandController.text.trim(),
        'deviceModel': _modelController.text.trim(),
        'faultDesc': _descController.text.trim(),
        'mediaUrls': <String>[],
        'addressId': _addressId,
        'urgency': _urgency,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('发布成功，等待工程师接单')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发布维修工单')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: _categoryId,
            decoration: const InputDecoration(labelText: '设备类型'),
            items: _categories
                .map((c) => DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(c['name']?.toString() ?? ''),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: '品牌（选填）'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: '型号（选填）'))),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
                labelText: '故障描述', alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          // TODO(2.2.3) 拍照/相册/视频上传：image_picker + OSS 预签名直传（/api/upload/presign）
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('添加故障照片/视频'),
          ),
          const SizedBox(height: 12),
          // TODO(2.2.3) 地图选点页（高德），当前仅用默认地址
          DropdownButtonFormField<int>(
            value: _addressId,
            decoration: const InputDecoration(labelText: '服务地址'),
            items: const [],
            onChanged: (value) => setState(() => _addressId = value),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'NORMAL', label: Text('普通')),
              ButtonSegment(value: 'URGENT', label: Text('紧急')),
              ButtonSegment(value: 'CRITICAL', label: Text('特急')),
            ],
            selected: {_urgency},
            onSelectionChanged: (s) => setState(() => _urgency = s.first),
          ),
          const SizedBox(height: 12),
          // TODO(2.2.3) 期望上门时间选择器
          const SizedBox(height: 16),
          PrimaryButton(label: '提交工单', onPressed: _submit, loading: _submitting),
        ],
      ),
    );
  }
}
