import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _frontUrl;
  String? _backUrl;
  final List<String> _certUrls = [];

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

  /// 拍身份证照并上传（TODO(2.2.6) 证书列表多图上传）
  Future<void> _pickIdPhoto({required bool front}) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (photo == null) return;
    try {
      final url = await ref.read(apiClientProvider).upload(photo.path);
      setState(() {
        if (front) {
          _frontUrl = url;
        } else {
          _backUrl = url;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('上传失败：$e')));
      }
    }
  }

  /// 技能证书多图上传（计划书 2.2.6）
  Future<void> _pickCerts() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1920);
    for (final f in files) {
      try {
        final url = await ref.read(apiClientProvider).upload(f.path);
        setState(() => _certUrls.add(url));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('证书上传失败：$e')));
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _idCardController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写姓名与身份证号')));
      return;
    }
    if (_frontUrl == null || _backUrl == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请拍摄身份证正反面')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/api/engineer/verify', data: {
        'realName': _nameController.text.trim(),
        'idCardNo': _idCardController.text.trim(),
        'idCardFrontUrl': _frontUrl,
        'idCardBackUrl': _backUrl,
        'certUrls': _certUrls,
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('资质认证')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          if (_currentStatus != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _statusBanner(),
            ),
            const SizedBox(height: 10),
          ],
          SectionCard(
            title: '基本信息',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '真实姓名')),
                const SizedBox(height: 12),
                TextField(
                    controller: _idCardController,
                    maxLength: 18,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: '身份证号', counterText: '')),
                const SizedBox(height: 12),
                TextField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                        labelText: '擅长设备类型（逗号分隔，如：注塑机,制冷设备）')),
              ],
            ),
          ),
          SectionCard(
            title: '资质材料',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickIdPhoto(front: true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 96,
                        decoration: BoxDecoration(
                          color: scheme.onSurfaceVariant.withAlpha(12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: _frontUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge_outlined,
                                      size: 22, color: scheme.onSurfaceVariant),
                                  const SizedBox(height: 4),
                                  Text('身份证正面',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_frontUrl!,
                                    fit: BoxFit.cover, width: double.infinity)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickIdPhoto(front: false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 96,
                        decoration: BoxDecoration(
                          color: scheme.onSurfaceVariant.withAlpha(12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: _backUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge,
                                      size: 22, color: scheme.onSurfaceVariant),
                                  const SizedBox(height: 4),
                                  Text('身份证反面',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_backUrl!,
                                    fit: BoxFit.cover, width: double.infinity)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickCerts,
                    icon: const Icon(Icons.workspace_premium_outlined, size: 20),
                    label: Text('技能证书上传（${_certUrls.length}）'),
                  ),
                ),
                if (_certUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _certUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(_certUrls[index],
                              width: 76, height: 76, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: '服务范围',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('接单半径：${_radiusKm.round()} 公里',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface)),
                Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_radiusKm.round()}km',
                  onChanged: (v) => setState(() => _radiusKm = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: PrimaryButton(
                label: '提交认证', onPressed: _submit, loading: _submitting),
          ),
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
      'APPROVED' => const Color(0xFF34C759),
      'REJECTED' => const Color(0xFFFF3B30),
      _ => const Color(0xFFFF9500),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withAlpha(24), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(Icons.info_outline, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, height: 1.4, color: Theme.of(context).colorScheme.onSurface))),
      ]),
    );
  }
}
