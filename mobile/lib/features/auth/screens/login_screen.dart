import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/config/server_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../controllers/auth_controller.dart';

/// 手机号 + 验证码登录，登录时选择身份（计划书 2.2.1）。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _serverCtrl = TextEditingController(text: ServerConfig.baseUrl);
  UserRole _role = UserRole.customer;
  int _countdown = 0;
  Timer? _timer;
  bool _agreed = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _serverCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool get _phoneValid => RegExp(r'^1\d{10}$').hasMatch(_phoneController.text.trim());

  Future<void> _sendCode() async {
    if (!_phoneValid) {
      _toast('请输入正确的手机号');
      return;
    }
    try {
      final devCode = await ref
          .read(authControllerProvider.notifier)
          .sendSmsCode(_phoneController.text.trim());
      if (!mounted) return;
      if (devCode != null && devCode.isNotEmpty) {
        // 开发模式：验证码直接展示，免去翻后端日志（生产环境此弹窗不会出现）
        _showDevCodeDialog(devCode);
      } else {
        _toast('验证码已发送，请查收短信');
      }
      setState(() => _countdown = 60);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown <= 1) {
          timer.cancel();
        }
        setState(() => _countdown = _countdown > 0 ? _countdown - 1 : 0);
      });
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  void _showDevCodeDialog(String code) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('验证码（开发模式）'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(code,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 8),
            Text('正式版将通过短信下发，此弹窗仅开发环境出现',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('手动输入')),
          FilledButton(
            onPressed: () {
              _codeController.text = code;
              Navigator.pop(dialogContext);
            },
            child: const Text('自动填入'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_agreed) {
      _toast('请先阅读并同意《用户服务协议》与《隐私政策》');
      return;
    }
    if (!_phoneValid) {
      _toast('请输入正确的手机号');
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      _toast('请输入验证码');
      return;
    }
    await ref.read(authControllerProvider.notifier).login(
          _phoneController.text.trim(),
          _codeController.text.trim(),
          _role,
        );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _agreementLink(BuildContext context, String label, bool privacy) {
    return GestureDetector(
      onTap: () => context.push(privacy ? '/agreement/privacy' : '/agreement/terms'),
      child: Text(label,
          style: TextStyle(
              fontSize: 13, color: Theme.of(context).colorScheme.primary)),
    );
  }

  Widget _roleCard(UserRole role, IconData icon, String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withAlpha(18) : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              TintedIconBox(icon: icon, color: selected ? scheme.primary : scheme.onSurfaceVariant, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null) {
        _toast(next.error!);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.brand, Color(0xFF3E7BC8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withAlpha(60),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.build_circle_outlined,
                    size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text('机器报修',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text('设备故障 · 一键报修 · 工程师快速接单',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                labelText: '手机号',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    onPressed: _countdown > 0 ? null : _sendCode,
                    child: Text(_countdown > 0 ? '${_countdown}s 后重发' : '获取验证码'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text('选择登录身份',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
            ),
            Row(
              children: [
                _roleCard(UserRole.customer, Icons.factory_outlined, '我是客户',
                    '发布工单 · 追踪维修'),
                const SizedBox(width: 12),
                _roleCard(UserRole.engineer, Icons.engineering, '我是工程师',
                    '接单上门 · 收入提现'),
              ],
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: '登录 / 注册', onPressed: _login, loading: auth.loading),
            const SizedBox(height: 4),
            // 电脑 IP 被校园网 DHCP 轮换时，在这里改成新地址即可，无需重新打包
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text('服务器设置（当前：${ServerConfig.baseUrl}）',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
                children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _serverCtrl,
                        decoration: const InputDecoration(
                            labelText: 'API 地址',
                            hintText: 'http://<电脑IP>:8080'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final url = _serverCtrl.text.trim();
                        if (!url.startsWith('http')) {
                          _toast('地址需以 http:// 开头');
                          return;
                        }
                        await ServerConfig.setBaseUrl(url);
                        if (!mounted) return;
                        setState(() {});
                        _toast('已保存：${ServerConfig.baseUrl}');
                      },
                      child: const Text('保存'),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                ),
                const SizedBox(width: 6),
                Text('已阅读并同意',
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant)),
                _agreementLink(context, '《用户服务协议》', false),
                _agreementLink(context, '《隐私政策》', true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
