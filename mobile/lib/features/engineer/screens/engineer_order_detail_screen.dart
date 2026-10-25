import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 工程师端工单操作流（计划书 3.2.3）：
/// 出发 → 导航跳转 → 到达签到(GPS) → 报价表单 → 开始维修 → 完工提交（多图）。
class EngineerOrderDetailScreen extends ConsumerStatefulWidget {
  const EngineerOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<EngineerOrderDetailScreen> createState() =>
      _EngineerOrderDetailScreenState();
}

class _EngineerOrderDetailScreenState extends ConsumerState<EngineerOrderDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(apiClientProvider)
          .get('/api/orders/${widget.orderId}') as Map<String, dynamic>;
      setState(() => _detail = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _post(String path, {Object? body, String? successMsg}) async {
    setState(() => _acting = true);
    try {
      await ref.read(apiClientProvider).post('/api/engineer/orders/${widget.orderId}$path',
          data: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMsg ?? '操作成功')));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _arrive() async {
    // TODO(3.2.3) geolocator 取真实 GPS；后端会校验与服务地址距离 ≤ 500m
    await _post('/arrive', body: {'lng': 121.4737, 'lat': 31.2304},
        successMsg: '签到成功');
  }

  Future<void> _showQuoteDialog() async {
    final laborController = TextEditingController();
    final partsController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提交报价'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: laborController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '工时费（元）')),
          const SizedBox(height: 12),
          TextField(controller: partsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '配件费（元）')),
          // TODO(3.2.3) 配件明细逐项录入
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('提交')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _post('/quote', body: {
      'laborFee': num.tryParse(laborController.text) ?? 0,
      'partsFee': num.tryParse(partsController.text) ?? 0,
      'partsDetail': <String>[],
    }, successMsg: '报价已提交，等待客户确认');
  }

  Future<void> _showFinishDialog() async {
    final diagnosisController = TextEditingController();
    final solutionController = TextEditingController();
    final beforeUrls = <String>[];
    final afterUrls = <String>[];

    Future<void> pickPhotos(List<String> target) async {
      final files = await ImagePicker()
          .pickMultiImage(imageQuality: 80, maxWidth: 1920);
      for (final f in files) {
        try {
          final url = await ref.read(apiClientProvider).upload(f.path);
          target.add(url);
        } catch (_) {}
      }
    }

    Widget photoStrip(List<String> urls) => SizedBox(
          height: urls.isEmpty ? 0 : 72,
          child: urls.isEmpty
              ? null
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child:
                        Image.network(urls[index], width: 72, height: 72, fit: BoxFit.cover),
                  ),
                ),
        );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('完工提交'),
          content: SizedBox(
            width: 320,
            child: ListView(shrinkWrap: true, children: [
              TextField(controller: diagnosisController, maxLines: 2,
                  decoration: const InputDecoration(labelText: '故障诊断')),
              const SizedBox(height: 12),
              TextField(controller: solutionController, maxLines: 2,
                  decoration: const InputDecoration(labelText: '维修方案')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: () async {
                    await pickPhotos(beforeUrls);
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text('维修前照片（${beforeUrls.length}）')),
              photoStrip(beforeUrls),
              OutlinedButton.icon(
                  onPressed: () async {
                    await pickPhotos(afterUrls);
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: Text('维修后照片（${afterUrls.length}）')),
              photoStrip(afterUrls),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('提交完工')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    if (beforeUrls.isEmpty || afterUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请上传维修前后照片')));
      }
      return;
    }
    await _post('/finish', body: {
      'diagnosis': diagnosisController.text,
      'solution': solutionController.text,
      'beforePhotos': beforeUrls,
      'afterPhotos': afterUrls,
      'partsReplaced': <String>[],
    }, successMsg: '已提交完工，等待客户验收');
  }

  @override
  Widget build(BuildContext context) {
    final order = _detail?['order'] as Map<String, dynamic>?;
    final status = order?['status']?.toString() ?? '';
    final address = order?['addressText']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(order?['statusLabel']?.toString() ?? '工单详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                SectionCard(
                  title: '工单信息',
                  child: Text(
                      '${order?['deviceCategoryName'] ?? ""} ${order?['deviceBrand'] ?? ""} ${order?['deviceModel'] ?? ""}\n'
                      '故障：${order?['faultDesc'] ?? ""}\n地址：$address'),
                ),
                if (status == 'ACCEPTED') ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Expanded(child: OutlinedButton.icon(
                          onPressed: _acting ? null : () {/* TODO(3.2.3) 跳转高德/百度/苹果地图导航 */},
                          icon: const Icon(Icons.navigation_outlined),
                          label: const Text('导航'))),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(
                          onPressed: _acting ? null : () => _post('/depart',
                              successMsg: '已出发'),
                          child: const Text('出发'))),
                    ]),
                  ),
                ],
                if (status == 'ON_THE_WAY')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.icon(
                        onPressed: _acting ? null : _arrive,
                        icon: const Icon(Icons.where_to_vote_outlined),
                        label: const Text('到达签到（GPS 校验）')),
                  ),
                if (status == 'ARRIVED')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Expanded(child: OutlinedButton(
                          onPressed: _acting ? null : _showQuoteDialog,
                          child: const Text('提交报价'))),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(
                          onPressed: _acting ? null : () => _post('/start-repair',
                              successMsg: '已开始维修'),
                          child: const Text('直接开始维修'))),
                    ]),
                  ),
                if (status == 'REPAIRING')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      FilledButton(
                          onPressed: _acting ? null : _showFinishDialog,
                          child: const Text('提交完工')),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _acting ? null : () => _showCloseDialog(),
                          child: const Text('无法修复，申请关闭')),
                    ]),
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Future<void> _showCloseDialog() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('无法修复关闭'),
        content: TextField(controller: reasonController,
            decoration: const InputDecoration(labelText: '原因说明')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('确认关闭')),
        ],
      ),
    );
    if (confirmed != true || reasonController.text.trim().isEmpty) return;
    await _post('/close', body: {'reason': reasonController.text.trim()},
        successMsg: '工单已关闭');
  }
}
