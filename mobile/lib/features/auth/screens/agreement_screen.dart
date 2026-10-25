import 'package:flutter/material.dart';

/// 用户协议 / 隐私政策静态页（计划书 5.2.1 上架合规）。
/// TODO(5.2.1) 正式上线前由法务出具完整文本并替换；应用商店提审需与权限说明一致。
class AgreementScreen extends StatelessWidget {
  const AgreementScreen({super.key, required this.isPrivacy});

  final bool isPrivacy;

  @override
  Widget build(BuildContext context) {
    final title = isPrivacy ? '隐私政策' : '用户服务协议';
    final paragraphs = isPrivacy
        ? const [
            '我们非常重视您的个人信息与隐私保护。本政策说明我们在您使用"机器报修"服务时收集、使用、存储与保护信息的方式。',
            '一、我们收集的信息：手机号码（用于注册登录与身份验证）；企业名称与联系信息（用于提供服务）；设备故障照片/视频（用于维修服务与留存）；位置信息（仅工程师端在上线接单期间收集，用于派单与到达校验）。',
            '二、信息的使用：上述信息仅用于提供与改进本平台服务，不会向维修服务相关方以外的第三方提供。维修工程师仅能查看与工单相关的必要信息。',
            '三、信息的存储：数据存储于中华人民共和国境内的服务器；照片与视频经加密传输。',
            '四、您的权利：您可以在 App 内随时查看、更正您的资料，也可以联系客服注销账号；注销后我们将在法定期限内删除或匿名化您的个人信息。',
            '五、联系我们：如对本政策有任何疑问，请通过 App 内"联系客服"与我们取得联系。',
          ]
        : const [
            '欢迎使用"机器报修"平台服务。本协议是您与平台之间就设备维修撮合服务所订立的约定。',
            '一、服务内容：平台为您提供设备故障报修、工程师匹配、维修过程管理与评价等撮合服务；维修服务由认证工程师实际提供。',
            '二、用户责任：您应提供真实、准确的故障描述与地址信息；不得利用平台从事违法违规活动。',
            '三、工程师服务规范：工程师须通过平台资质认证，按平台流程上门服务、提交报价与维修报告；不得绕开平台私下交易。',
            '四、费用与支付：服务费用以工单确认报价为准；通过平台支付的交易享受平台保障与保修承诺。',
            '五、免责条款：因不可抗力或客户原因（如隐瞒设备真实状况）导致的服务中断或损失，平台不承担责任。',
            '六、协议变更与终止：我们可能适时修订本协议并在 App 内公告；您继续使用服务视为接受修订。',
          ];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('最近更新：2026-10', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          ...paragraphs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(p, style: const TextStyle(height: 1.6)),
              )),
          const SizedBox(height: 12),
          Text('※ 本文本为产品模板示例，正式发布前请由法务审核定稿。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}
