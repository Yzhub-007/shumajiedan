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
  final _typeController = TextEditingController();

  /// 字典树平铺（含二级分类），用于"常用类型"推荐
  List<Map<String, dynamic>> _flatCategories = [];
  /// 历史设备记忆（类型+品牌+型号组合），来自 /api/orders/device-history
  List<Map<String, dynamic>> _deviceHistory = [];
  List<Map<String, dynamic>> _addresses = [];
  int? _selectedCategoryId;
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
    _loadDeviceHistory();
    _loadAddresses();
  }

  @override
  void dispose() {
    _descController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ref.read(apiClientProvider).get('/api/device-categories') as List<dynamic>;
      final flat = <Map<String, dynamic>>[];
      for (final item in data.cast<Map<String, dynamic>>()) {
        flat.add(item);
        final children = item['children'];
        if (children is List) {
          flat.addAll(children.cast<Map<String, dynamic>>());
        }
      }
      if (mounted) setState(() => _flatCategories = flat);
    } catch (_) {}
  }

  Future<void> _loadDeviceHistory() async {
    try {
      final data =
          await ref.read(apiClientProvider).get('/api/orders/device-history') as List<dynamic>;
      if (mounted) {
        setState(() => _deviceHistory = data.cast<Map<String, dynamic>>());
      }
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

  String get _typeQuery => _typeController.text.trim().toLowerCase();

  List<Map<String, dynamic>> get _filteredHistory => _deviceHistory
      .where((h) => _typeQuery.isEmpty
          ? true
          : (h['deviceType']?.toString() ?? '').toLowerCase().contains(_typeQuery))
      .toList();

  List<Map<String, dynamic>> get _filteredCategories => _flatCategories
      .where((c) => _typeQuery.isEmpty
          ? true
          : (c['name']?.toString() ?? '').toLowerCase().contains(_typeQuery))
      .toList();

  /// 文本与字典名一致时带上 id，保留计价与技能匹配
  int? _categoryIdByName(String name) {
    final hit = _flatCategories
        .where((c) => (c['name']?.toString() ?? '').trim() == name.trim())
        .toList();
    return hit.isEmpty ? null : hit.first['id'] as int?;
  }

  String _historyLabel(Map<String, dynamic> h) {
    final parts = [h['deviceType'], h['deviceBrand'], h['deviceModel']]
        .map((e) => (e ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? '历史设备' : parts.join(' · ');
  }

  void _applyHistory(Map<String, dynamic> h) {
    setState(() {
      _typeController.text = (h['deviceType'] ?? '').toString();
      _brandController.text = (h['deviceBrand'] ?? '').toString();
      _modelController.text = (h['deviceModel'] ?? '').toString();
      _selectedCategoryId = _categoryIdByName(_typeController.text);
    });
  }

  void _applyCategory(Map<String, dynamic> c) {
    setState(() {
      _typeController.text = c['name']?.toString() ?? '';
      _selectedCategoryId = c['id'] as int?;
    });
  }

  Future<void> _submit() async {
    final typeText = _typeController.text.trim();
    if (typeText.isEmpty || _addressId == null || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请完善设备类型、服务地址与故障描述')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/api/orders', data: {
        'deviceCategoryId': _selectedCategoryId,
        'deviceCategoryInput': typeText,
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
                TextField(
                  controller: _typeController,
                  maxLength: 50,
                  buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          required maxLength}) =>
                      null,
                  onChanged: (value) => setState(() {
                        // 手动改动文本后仅当仍与所选字典名一致时保留关联
                        if (_selectedCategoryId != null &&
                            _categoryIdByName(value) != _selectedCategoryId) {
                          _selectedCategoryId = null;
                        }
                      }),
                  decoration: const InputDecoration(
                    labelText: '设备类型',
                    hintText: '输入或从下方推荐中选择',
                  ),
                ),
                if (_filteredHistory.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('最近使用',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final h in _filteredHistory)
                        ActionChip(
                          avatar: Icon(Icons.history,
                              size: 16, color: scheme.primary),
                          label: Text(_historyLabel(h),
                              overflow: TextOverflow.ellipsis),
                          onPressed: () => _applyHistory(h),
                        ),
                    ],
                  ),
                ],
                if (_filteredCategories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('常用类型',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _filteredCategories)
                        ActionChip(
                          label: Text(c['name']?.toString() ?? '',
                              overflow: TextOverflow.ellipsis),
                          onPressed: () => _applyCategory(c),
                        ),
                    ],
                  ),
                ],
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
