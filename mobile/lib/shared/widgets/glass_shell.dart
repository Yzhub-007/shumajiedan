import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 微信式底部 Tab 壳 + Apple「液态玻璃」底栏（iOS 26 Liquid Glass 风格）：
/// 实时背景虚化（BackdropFilter）→ 半透明灰色垫层（保证文字与内容的对比度）
/// → 渐变描边一圈（受光边缘亮、背光边缘淡）→ 向外扩散的光晕阴影。
/// 页面通过 `extendBody` 从底栏下方穿过，虚化才能"透"出滚动内容。
class GlassTab {
  const GlassTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class GlassShellScreen extends StatelessWidget {
  const GlassShellScreen({super.key, required this.shell, required this.tabs});

  final StatefulNavigationShell shell;
  final List<GlassTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: GlassTabBar(
        tabs: tabs,
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // 外扩光晕（品牌色）+ 常规投影，让玻璃从页面上“浮起来”
              BoxShadow(
                color: scheme.primary.withAlpha(38),
                blurRadius: 26,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(dark ? 70 : 28),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            // 渐变描边一圈：玻璃边缘的高光渐变
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [
                        Colors.white.withAlpha(110),
                        Colors.white.withAlpha(26),
                        Colors.white.withAlpha(110),
                      ]
                    : [
                        Colors.white.withAlpha(235),
                        Colors.white.withAlpha(70),
                        Colors.white.withAlpha(235),
                      ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 62,
                  // 灰色垫层：垫在虚化背景之上、文字之下，提高标签可读性
                  color: dark
                      ? const Color(0xD9161618)
                      : const Color(0xCDE9E9EE),
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        _buildItem(context, i),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final tab = tabs[index];
    final selected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withAlpha(28)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withAlpha(50),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 22,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
