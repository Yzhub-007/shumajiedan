import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 工程师资质认证（计划书 2.2.6）：身份证拍照、证书上传、技能多选、服务半径。
class EngineerVerifyScreen extends ConsumerStatefulWidget {
  const EngineerVerifyScreen({super.key});

  @override
  ConsumerState<EngineerVerifyScreen> createState() => _EngineerVerifyScreenState();
}

class _EngineerVerifyScreenState extends ConsumerState<EngineerVerifyScreen> {
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _skillsController = TextEditingController();
  double _radiusKm = 10;
  bool _submitting = false;
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ref
          .read(apiClientProvider)
          .get('/api/engineer/verify-status') as Map<String, dynamic>;
      setState(() {
        _currentStatus = data['verifyStatus']?.toString();
        _nameController.text = data['realName']?.toString() ?? '';
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _idCardController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写姓名与身份证号')));
      return;
    }
    setState(() => _submitting = true);
    try {
      // TODO(2.2.6) 身份证/证书拍照上传：image_picker + /api/upload/presign 直传，回填 URL
      await ref.read(apiClientProvider).post('/api/engineer/verify', data: {
        'realName': _nameController.text.trim(),
        'idCardNo': _idCardController.text.trim(),
        'idCardFrontUrl': 'https://placeholder/front.jpg',
        'idCardBackUrl': 'https://placeholder/back.jpg',
        'certUrls': <String>[],
        'skillTags': _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'serviceRadiusKm': _radiusKm.round(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已提交，等待平台审核（1 个工作日内）')));
      _loadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('资质认证')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_currentStatus != null) ...[
            _statusBanner(),
            const SizedBox(height: 16),
          ],
          TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '真实姓名')),
          const SizedBox(height: 12),
          TextField(
              controller: _idCardController,
              maxLength: 18,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '身份证号', counterText: '')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
                onPressed: () {/* TODO(2.2.6) 拍身份证正面 */},
                icon: const Icon(Icons.badge_outlined),
                label: const Text('身份证正面'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(
                onPressed: () {/* TODO(2.2.6) 拍身份证反面 */},
                icon: const Icon(Icons.badge),
                label: const Text('身份证反面'))),
          ]),
          const SizedBox(height: 12),
          TextField(
              controller: _skillsController,
              decoration: const InputDecoration(
                  labelText: '擅长设备类型（逗号分隔，如：注塑机,制冷设备）')),
          const SizedBox(height: 16),
          Text('服务半径：${_radiusKm.round()} 公里'),
          Slider(
            value: _radiusKm,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_radiusKm.round()}km',
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: '提交认证', onPressed: _submit, loading: _submitting),
        ],
      ),
    );
  }

  Widget _statusBanner() {
    final text = switch (_currentStatus) {
      'PENDING' => '资质审核中，请耐心等待（1 个工作日内）',
      'APPROVED' => '已通过认证，可以上线接单',
      'REJECTED' => '认证未通过，请补充材料后重新提交',
      _ => '',
    };
    final color = switch (_currentStatus) {
      'APPROVED' => Colors.green,
      'REJECTED' => Colors.red,
      _ => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withAlpha(24), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(Icons.info_outline, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ]),
    );
  }
}
