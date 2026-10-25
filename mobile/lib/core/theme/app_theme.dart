import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局主题 —— 参考 Apple Human Interface Guidelines（iOS 设计语言）：
///   清晰 Clarity：层次分明的排版与语义色，正文 15/17 号，标题加粗；
///   谦逊 Deference：大留白、弱装饰、无边框输入框，让内容优先于控件；
///   深度 Depth：分组卡片表达信息结构，浮层用圆角与阴影区分层级。
/// 色板 = 品牌蓝（计划书 0.2.1）+ iOS 系统语义色；浅色 / 深色（跟随系统）双主题。
class AppTheme {
  AppTheme._();

  /// 品牌蓝（计划书 0.2.1 视觉规范）
  static const Color brand = Color(0xFF1E5AA8);

  /// 深色模式下的品牌交互色（提亮以保持对比度，同 iOS 深色语义色的处理方式）
  static const Color brandDark = Color(0xFF5E93DD);

  // ---- iOS 系统语义色（Apple HIG: Colors - System Colors）----
  static const systemBlue = Color(0xFF007AFF);
  static const systemGreen = Color(0xFF34C759);
  static const systemOrange = Color(0xFFFF9500);
  static const systemRed = Color(0xFFFF3B30);
  static const systemTeal = Color(0xFF30B0C7);
  static const systemPurple = Color(0xFFAF52DE);

  // ---- iOS 分层背景 / 文本色（浅色）----
  static const _groupedBg = Color(0xFFF2F2F7);
  static const _label = Color(0xFF1C1C1E);
  static const _secondaryLabel = Color(0x993C3C43);
  static const _tertiaryLabel = Color(0x4D3C3C43);
  static const _separator = Color(0x1F3C3C43);
  static const _fill = Color(0x1F767680);

  // ---- iOS 分层背景 / 文本色（深色）----
  static const _darkGroupedBg = Color(0xFF000000);
  static const _darkCard = Color(0xFF1C1C1E);
  static const _darkSecondaryLabel = Color(0x99EBEBF5);
  static const _darkTertiaryLabel = Color(0x4DEBEBF5);
  static const _darkSeparator = Color(0x3D545458);
  static const _darkFill = Color(0x2A787880);

  static ThemeData light() => build(Brightness.light);

  static ThemeData dark() => build(Brightness.dark);

  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
    ).copyWith(
      // iOS 分层：页面分组背景 / 卡片表面 / 填充层
      surface: isDark ? _darkGroupedBg : _groupedBg,
      surfaceContainerLowest: isDark ? _darkGroupedBg : Colors.white,
      surfaceContainerLow: isDark ? _darkCard : Colors.white,
      surfaceContainer: isDark ? _darkCard : Colors.white,
      surfaceContainerHigh: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      surfaceContainerHighest:
          isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFAFAFC),
      onSurface: isDark ? Colors.white : _label,
      onSurfaceVariant: isDark ? _darkSecondaryLabel : _secondaryLabel,
      outline: isDark ? _darkTertiaryLabel : _tertiaryLabel,
      outlineVariant: isDark ? _darkSeparator : _separator,
      primary: isDark ? brandDark : brand,
      onPrimary: Colors.white,
      secondary: isDark ? brandDark : brand,
      error: isDark ? const Color(0xFFFF453A) : systemRed,
    );

    final separator = scheme.outlineVariant;
    final inputFill = isDark ? _darkFill : _fill;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(scheme),
      // 更克制的按压反馈（iOS 无涟漪，这里保留但弱化）
      splashColor: scheme.onSurface.withAlpha(10),
      highlightColor: scheme.onSurface.withAlpha(6),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 24),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle:
            TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurface),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withAlpha(70),
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xF02C2C2E) : const Color(0xE61C1C1E),
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 6,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withAlpha(90),
          disabledForegroundColor: Colors.white,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          foregroundColor: scheme.onSurface,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          side: BorderSide(color: separator, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // iOS 风格无边框填充输入框，聚焦时浮现品牌色细环
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: systemRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: systemRed, width: 1.4),
        ),
        labelStyle: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(fontSize: 13, color: scheme.primary),
        hintStyle: TextStyle(fontSize: 15, color: scheme.outline),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: scheme.primary,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.25,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: scheme.onSurfaceVariant,
        ),
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFill,
        selectedColor: scheme.primary,
        checkmarkColor: Colors.white,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : scheme.onSurface,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: separator)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : scheme.onSurfaceVariant,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? systemGreen
              : inputFill,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(width: 1.4, color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
        shadowColor: Colors.black26,
        textStyle: TextStyle(fontSize: 15, color: scheme.onSurface),
        position: PopupMenuPosition.under,
      ),
      dividerTheme:
          DividerThemeData(color: separator, thickness: 0.5, space: 1),
      dividerColor: separator,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: inputFill,
        circularTrackColor: inputFill,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: inputFill,
        thumbColor: Colors.white,
        overlayColor: scheme.primary.withAlpha(30),
        valueIndicatorColor: scheme.primary,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withAlpha(50),
        selectionHandleColor: scheme.primary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  /// iOS 排版尺度：大标题 28-34 加粗、正文 17/15、辅助 13、标签 11-12。
  static TextTheme _textTheme(ColorScheme scheme) {
    final base = TextTheme(
      displayLarge: const TextStyle(
          fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displayMedium: const TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      displaySmall: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      headlineSmall: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 17, height: 1.4),
      bodyMedium: const TextStyle(fontSize: 15, height: 1.4),
      bodySmall: const TextStyle(fontSize: 13, height: 1.4),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    );
    return base.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
