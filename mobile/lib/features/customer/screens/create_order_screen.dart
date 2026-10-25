import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 发布工单（计划书 2.2.3）：设备类型、故障描述、拍照/相册上传（经 /api/upload）、
/// 服务地址选择、期望上门时间、紧急程度。
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
  List<Map<String, dynamic>> _addresses = [];
  int? _categoryId;
  int? _addressId;
  String _urgency = 'NORMAL';
  DateTime? _expectTime;
  final List<String> _mediaUrls = [];
  bool _uploading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAddresses();
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
    } catch (_) {}
  }

  Future<void> _loadAddresses() async {
    try {
      final data =
          await ref.read(apiClientProvider).get('/api/customer/addresses') as List<dynamic>;
      final list = data.cast<Map<String, dynamic>>();
      setState(() {
        _addresses = list;
        if (list.isNotEmpty) {
          final def = list.where((a) => a['isDefault'] == true).toList();
          _addressId = (def.isNotEmpty ? def.first : list.first)['id'] as int;
        }
      });
    } catch (_) {}
  }

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1920);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    for (final f in files) {
      try {
        final url = await ref.read(apiClientProvider).upload(f.path);
        setState(() => _mediaUrls.add(url));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('图片上传失败：$e')));
        }
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _pickExpectTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
    );
    if (time == null) return;
    setState(() => _expectTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (_categoryId == null || _addressId == null || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请完善设备类型、服务地址与故障描述')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/api/orders', data: {
        'deviceCategoryId': _categoryId,
        'deviceBrand': _brandController.text.trim(),
        'deviceModel': _modelController.text.trim(),
        'faultDesc': _descController.text.trim(),
        'mediaUrls': _mediaUrls,
        'addressId': _addressId,
        'urgency': _urgency,
        'expectTime': _expectTime?.toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('发布成功，正在为你匹配附近工程师')));
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('发布维修工单')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          SectionCard(
            title: '设备信息',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      decoration:
                          const InputDecoration(labelText: '品牌（选填）'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(
                      controller: _modelController,
                      decoration:
                          const InputDecoration(labelText: '型号（选填）'))),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                      labelText: '故障描述', alignLabelWithHint: true),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '故障照片',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_mediaUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mediaUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_mediaUrls[index],
                                  width: 84, height: 84, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: -6,
                              top: -6,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _mediaUrls.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.cancel,
                                      size: 18, color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: Container(
                    height: 84,
                    width: 84,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: scheme.outlineVariant, style: BorderStyle.solid),
                    ),
                    child: _uploading
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 22, color: scheme.onSurfaceVariant),
                              const SizedBox(height: 4),
                              Text('添加照片',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant)),
                            ],
                          ),
                  ),
                ),
                // TODO(1.3.2) 视频拍摄上传与压缩
              ],
            ),
          ),
          SectionCard(
            title: '服务安排',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _addressId,
                        decoration: const InputDecoration(labelText: '服务地址'),
                        items: _addresses
                            .map((a) => DropdownMenuItem<int>(
                                  value: a['id'] as int,
                                  child: Text(
                                    '${a["label"] ?? "地址"} · ${a["detail"] ?? ""}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _addressId = value),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await context.push('/customer/addresses');
                        _loadAddresses();
                      },
                      child: const Text('管理'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickExpectTime,
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: '期望上门时间（选填）'),
                    child: Text(_expectTime == null
                        ? '尽快上门'
                        : '${_expectTime!.month}月${_expectTime!.day}日 '
                            '${_expectTime!.hour.toString().padLeft(2, "0")}:${_expectTime!.minute.toString().padLeft(2, "0")}'),
                  ),
                ),
                const SizedBox(height: 16),
                Text('紧急程度',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'NORMAL', label: Text('普通')),
                      ButtonSegment(value: 'URGENT', label: Text('紧急')),
                      ButtonSegment(value: 'CRITICAL', label: Text('特急')),
                    ],
                    selected: {_urgency},
                    onSelectionChanged: (s) =>
                        setState(() => _urgency = s.first),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: PrimaryButton(
                label: '提交工单', onPressed: _submit, loading: _submitting),
          ),
        ],
      ),
    );
  }
}
