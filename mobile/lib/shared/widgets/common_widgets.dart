import 'package:flutter/material.dart';

/// 通用组件 —— Apple HIG 视觉语言：
/// 分组卡片（iOS inset grouped）、药丸状态标签、50pt 主按钮、大标题页头。
/// （计划书 1.2.2 脚手架通用组件层，随 UI 设计稿逐步丰富。）

/// 工单状态语义色（iOS 系统色，明暗模式自适应取色）。
class StatusColors {
  StatusColors._();

  static Color of(BuildContext context, String kind) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (kind) {
      case 'pending':
        return dark ? const Color(0xFFFFB340) : const Color(0xFFFF9500);
      case 'inProgress':
        return dark ? const Color(0xFF64A8FF) : const Color(0xFF007AFF);
      case 'repairing':
        return dark ? const Color(0xFFC777EC) : const Color(0xFFAF52DE);
      case 'pendingConfirm':
      case 'pendingPayment':
        return dark ? const Color(0xFF53C6DE) : const Color(0xFF30B0C7);
      case 'done':
        return dark ? const Color(0xFF33D267) : const Color(0xFF34C759);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  static Color colorOfKind(String kind, BuildContext context) {
    return StatusColors.of(context, kind);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(dark ? 46 : 26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: c, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.icon = Icons.inbox_outlined, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 30, color: scheme.onSurfaceVariant.withAlpha(150)),
          ),
          const SizedBox(height: 14),
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title!,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// iOS 分组列表容器：圆角白卡内多行 ListTile，行间 hairline 分隔线
/// （缩进对齐文本，参考 iOS「设置」的 inset grouped list）。
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.separatorIndent = 16,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final double separatorIndent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(
            height: 1,
            thickness: 0.5,
            indent: separatorIndent,
            color: scheme.outlineVariant));
      }
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// iOS「设置」风格图标底衬：彩色圆角方块 + 白色线性图标。
class TintedIconBox extends StatelessWidget {
  const TintedIconBox({
    super.key,
    required this.icon,
    this.color,
    this.size = 30,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: size * 0.56, color: Colors.white),
    );
  }
}

/// iOS Large Title 页头：大字号标题 + 副标题 + 右侧操作区。
class LargeTitleHeader extends StatelessWidget {
  const LargeTitleHeader({super.key, required this.title, this.subtitle, this.actions});

  final String title;
  final String? subtitle;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: scheme.onSurface)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          if (actions != null) actions!,
        ],
      ),
    );
  }
}

/// 详情页 key-value 行：左侧灰色标签、右侧主要文本，右对齐。
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label,
                style:
                    TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
