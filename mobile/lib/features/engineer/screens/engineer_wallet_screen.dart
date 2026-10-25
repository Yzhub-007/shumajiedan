import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

/// 工程师钱包：余额/累计收入/提现记录/申请提现（计划书 3.2 / 2.4）。
/// 真实打款渠道（微信商家转账等）见后端 TODO(V1.1)。
class EngineerWalletScreen extends ConsumerStatefulWidget {
  const EngineerWalletScreen({super.key});

  @override
  ConsumerState<EngineerWalletScreen> createState() => _EngineerWalletScreenState();
}

class _EngineerWalletScreenState extends ConsumerState<EngineerWalletScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _withdrawals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final wallet =
          await ref.read(apiClientProvider).get('/api/engineer/wallet') as Map<String, dynamic>;
      setState(() => _wallet = wallet);
    } catch (_) {}
    try {
      final list =
          await ref.read(apiClientProvider).get('/api/engineer/withdrawals') as List<dynamic>;
      setState(() => _withdrawals = list);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _applyWithdrawal() async {
    final amountController = TextEditingController();
    final accountController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('申请提现'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '提现金额（元）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: accountController,
            decoration: const InputDecoration(labelText: '收款账户（支付宝/银行卡）'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('提交')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final amount = num.tryParse(amountController.text.trim());
    if (amount == null || accountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写提现金额与收款账户')));
      return;
    }
    try {
      await ref.read(apiClientProvider).post('/api/engineer/withdrawals', data: {
        'amount': amount,
        'account': accountController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('申请已提交，等待平台审核')));
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('我的钱包')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                children: [
                  // 余额卡
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E5AA8), Color(0xFF3E7BC8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withAlpha(70),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('可用余额（元）',
                            style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: 13)),
                        const SizedBox(height: 6),
                        Text('${_wallet?['balance'] ?? 0}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 10),
                        Text(
                            '冻结 ${_wallet?['frozen'] ?? 0} · 累计收入 ${_wallet?['totalIncome'] ?? 0}',
                            style: TextStyle(
                                color: Colors.white.withAlpha(190),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: FilledButton.icon(
                      onPressed: _applyWithdrawal,
                      icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                      label: const Text('申请提现'),
                    ),
                  ),
                  SectionCard(
                    title: '提现记录',
                    child: _withdrawals.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: EmptyView(
                                icon: Icons.receipt_long_outlined,
                                text: '暂无提现记录'),
                          )
                        : Column(
                            children: _withdrawals.map((w) {
                              final item = w as Map<String, dynamic>;
                              final status = item['status']?.toString() ?? '';
                              final statusText = switch (status) {
                                'APPROVED' => '已通过',
                                'REJECTED' => '已拒绝',
                                _ => '审核中',
                              };
                              final statusColor = switch (status) {
                                'APPROVED' => const Color(0xFF34C759),
                                'REJECTED' => const Color(0xFFFF3B30),
                                _ => const Color(0xFFFF9500),
                              };
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('-${item['amount']} 元',
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text(
                                              item['createdAt']?.toString() ?? '',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: scheme
                                                      .onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                    Text(statusText,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
