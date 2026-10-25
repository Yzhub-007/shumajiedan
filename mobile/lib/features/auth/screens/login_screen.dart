import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
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
  UserRole _role = UserRole.customer;
  int _countdown = 0;
  Timer? _timer;
  bool _agreed = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
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
      await ref
          .read(authControllerProvider.notifier)
          .sendSmsCode(_phoneController.text.trim());
      if (!mounted) return;
      _toast('验证码已发送（开发模式验证码见后端日志）');
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
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null) {
        _toast(next.error!);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            Icon(Icons.build_circle_outlined,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('机器报修', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 40),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: const InputDecoration(
                labelText: '手机号',
                counterText: '',
                prefixIcon: Icon(Icons.phone_android),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _countdown > 0 ? null : _sendCode,
                  child: Text(_countdown > 0 ? '${_countdown}s' : '获取验证码'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('选择身份', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<UserRole>(
              segments: const [
                ButtonSegment(value: UserRole.customer, label: Text('我是客户'), icon: Icon(Icons.factory_outlined)),
                ButtonSegment(value: UserRole.engineer, label: Text('我是工程师'), icon: Icon(Icons.engineering)),
              ],
              selected: {_role},
              onSelectionChanged: (selection) => setState(() => _role = selection.first),
            ),
            const SizedBox(height: 32),
            PrimaryButton(label: '登录 / 注册', onPressed: _login, loading: auth.loading),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                ),
                const SizedBox(width: 4),
                Text('已阅读并同意', style: Theme.of(context).textTheme.bodySmall),
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
