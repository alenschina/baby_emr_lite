import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 底部弹出框适配工具
///
/// 解决问题：
/// 1. 键盘弹出时的遮挡问题
/// 2. 底部导航栏的遮挡问题
/// 3. 不同设备安全区域的适配问题
class BottomSheetUtils {
  BottomSheetUtils._();

  /// 底部导航栏的估算高度（包含 SafeArea）
  /// 导航栏内容高度约 52px + 顶部 padding 8px + 底部 padding 12px
  static const double kBottomNavHeight = 72.0;

  /// 浮动导航栏自身高度（不含 SafeArea）
  /// 由以下部分组成：
  /// - 底部 padding: 12px
  /// - Container padding: vertical 8px * 2 = 16px
  /// - 内容高度：图标 22px + 间距 4px + 文字约 15px ≈ 41px
  /// 总计约：12 + 16 + 41 = 69px
  static const double kFloatingNavBarHeight = 69.0;

  /// 获取 FAB 需要上移的边距
  ///
  /// 在使用 `extendBody: true` 时，FAB 需要上移以避开浮动的底部导航栏
  ///
  /// [extraSpacing] - FAB 与导航栏之间的额外间距，默认 16.0
  static double getFabBottomMargin(
    BuildContext context, {
    double extraSpacing = 16.0,
  }) {
    final safePadding = getBottomSafePadding(context);
    // FAB 需要在浮动导航栏上方
    // 距离 = SafeArea + 导航栏高度 + 额外间距
    return safePadding + kFloatingNavBarHeight + extraSpacing;
  }

  /// 显示适配的 Bottom Sheet
  ///
  /// [context] - BuildContext
  /// [builder] - 内容构建器
  /// [isScrollControlled] - 是否可滚动控制，默认 true
  /// [enableDrag] - 是否可拖拽关闭，默认 true
  /// [showDragHandle] - 是否显示拖拽手柄，默认 false
  static Future<T?> showAdaptiveSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool enableDrag = true,
    bool showDragHandle = false,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      builder: builder,
    );
  }

  /// 获取底部安全区域的 padding
  ///
  /// 包含：
  /// - 系统安全区域（如 iPhone 的 Home Indicator）
  /// - 额外的视觉间距
  static double getBottomSafePadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    // 确保最小间距
    return bottomPadding > 0 ? bottomPadding : 16.0;
  }

  /// 获取键盘高度
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// 获取完整的底部 padding（键盘 + 安全区域 + 底部导航栏 + 额外间距）
  ///
  /// 用于表单底部按钮的 padding 计算
  ///
  /// [includeBottomNav] - 是否包含底部导航栏高度，默认 true
  /// [extraSpacing] - 额外的视觉间距，默认 24.0
  static double getFullBottomPadding(
    BuildContext context, {
    bool includeBottomNav = true,
    double extraSpacing = 24.0,
  }) {
    final keyboardHeight = getKeyboardHeight(context);
    final safePadding = getBottomSafePadding(context);

    // 如果键盘弹出，键盘高度已经包含了安全区域
    // 只需要添加额外间距
    if (keyboardHeight > 0) {
      return keyboardHeight + extraSpacing;
    }

    // 无键盘时：安全区域 + 底部导航栏高度 + 额外间距
    // 底部导航栏是浮动的，需要额外空间来避开它
    final bottomNavHeight = includeBottomNav ? kBottomNavHeight : 0.0;
    return safePadding + bottomNavHeight + extraSpacing;
  }

  /// 创建适配的 Bottom Sheet 容器
  ///
  /// [child] - 子组件
  /// [showDragHandle] - 是否显示顶部拖拽指示器
  /// [includeBottomNav] - 是否为底部导航栏预留空间，默认 true
  static Widget buildAdaptiveContainer({
    required BuildContext context,
    required Widget child,
    bool showDragHandle = true,
    bool includeBottomNav = true,
    EdgeInsets? additionalPadding,
  }) {
    // 计算底部需要的额外间距（不包含 Container 的 padding）
    // 这部分间距由 SingleChildScrollView 内部的 BottomSafeAreaSpacing 提供
    final horizontalPadding = additionalPadding?.left ?? 24.0;
    final topPadding = additionalPadding?.top ?? 24.0;

    return Container(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: topPadding,
        // 底部 padding 在内部处理，这里设为 0
        bottom: 0,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.glassCardGradientHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDragHandle) _buildDragHandle(),
          // 使用 Expanded 而不是 Flexible，确保内容能正确填充
          child,
        ],
      ),
    );
  }

  static Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.slate300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// 适配底部安全区域的 ScrollView
///
/// 用于表单内容，自动处理键盘和安全区域
class AdaptiveScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollController? controller;

  const AdaptiveScrollView({
    super.key,
    required this.child,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = BottomSheetUtils.getFullBottomPadding(context);

    return SingleChildScrollView(
      controller: controller,
      padding: padding != null
          ? EdgeInsets.only(
              left: padding!.left,
              right: padding!.right,
              top: padding!.top,
              bottom: bottomPadding,
            )
          : EdgeInsets.only(bottom: bottomPadding),
      child: child,
    );
  }
}

/// 适配底部安全区域的填充组件
///
/// 在 Bottom Sheet 底部添加此组件，确保内容不会被遮挡
/// 自动计算底部导航栏、安全区域和键盘高度
class BottomSafeAreaSpacing extends StatelessWidget {
  /// 额外的间距
  final double extraSpacing;

  /// 是否包含底部导航栏高度
  final bool includeBottomNav;

  const BottomSafeAreaSpacing({
    super.key,
    this.extraSpacing = 24.0,
    this.includeBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BottomSheetUtils.getFullBottomPadding(
        context,
        includeBottomNav: includeBottomNav,
        extraSpacing: extraSpacing,
      ),
    );
  }
}
