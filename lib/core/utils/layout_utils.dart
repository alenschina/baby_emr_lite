import 'package:flutter/material.dart';

/// 布局工具类
/// 提供响应式布局和溢出检测功能
class LayoutUtils {
  LayoutUtils._();

  /// 获取屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 获取屏幕尺寸分类
  static ScreenSize getScreenSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) {
      return ScreenSize.extraSmall;
    } else if (width < 375) {
      return ScreenSize.small;
    } else if (width < 414) {
      return ScreenSize.medium;
    } else if (width < 450) {
      return ScreenSize.large;
    } else {
      return ScreenSize.extraLarge;
    }
  }

  /// 根据屏幕尺寸获取缩放因子
  static double getScaleFactor(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.extraSmall:
        return 0.85;
      case ScreenSize.small:
        return 0.9;
      case ScreenSize.medium:
        return 1.0;
      case ScreenSize.large:
        return 1.05;
      case ScreenSize.extraLarge:
        return 1.1;
    }
  }

  /// 根据屏幕尺寸调整间距
  static double adjustSpacing(
    BuildContext context,
    double baseSpacing,
  ) {
    final factor = getScaleFactor(context);
    return baseSpacing * factor;
  }

  /// 根据屏幕尺寸调整字体大小
  static double adjustFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final factor = getScaleFactor(context);
    return baseFontSize * factor;
  }

  /// 根据屏幕尺寸调整图标大小
  static double adjustIconSize(
    BuildContext context,
    double baseIconSize,
  ) {
    final factor = getScaleFactor(context);
    return baseIconSize * factor;
  }

  /// 检查是否为小屏幕设备
  static bool isSmallScreen(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.extraSmall || size == ScreenSize.small;
  }

  /// 创建安全的文本溢出处理
  static Widget buildSafeText(
    String text, {
    TextStyle? style,
    int? maxLines = 1,
    TextOverflow overflow = TextOverflow.fade,
    bool softWrap = false,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textAlign: textAlign,
    );
  }

  /// 创建紧凑的徽章组件
  static Widget buildCompactBadge({
    required String text,
    required Color color,
    IconData? icon,
    double? fontSize,
    double? iconSize,
    VoidCallback? onTap,
  }) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? 4 : 6,
        vertical: 1.5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round().clamp(0, 255)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize ?? 9,
              color: color,
            ),
            const SizedBox(width: 1),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize ?? 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }
    return badge;
  }

  /// 创建响应式的 Row
  static Widget buildResponsiveRow({
    required BuildContext context,
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double spacing = 8,
  }) {
    final adjustedSpacing = adjustSpacing(context, spacing);
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _addSpacing(children, adjustedSpacing),
    );
  }

  /// 在子组件之间添加间距
  static List<Widget> _addSpacing(List<Widget> children, double spacing) {
    if (children.isEmpty) return children;
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(width: spacing));
      }
    }
    return result;
  }
}

/// 屏幕尺寸枚举
enum ScreenSize {
  extraSmall, // < 360px (如 iPhone SE)
  small,      // 360-375px (如 iPhone 8)
  medium,     // 375-414px (如 iPhone 13)
  large,      // 414-450px (如 iPhone 14 Pro Max)
  extraLarge, // > 450px (如大屏安卓设备)
}

/// 布局约束包装器
/// 用于防止子组件溢出
class LayoutConstraintWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final Alignment alignment;
  final bool showOverflowIndicator;

  const LayoutConstraintWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.alignment = Alignment.centerLeft,
    this.showOverflowIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? constraints.maxWidth,
            maxHeight: maxHeight ?? constraints.maxHeight,
          ),
          alignment: alignment,
          child: OverflowBox(
            maxWidth: maxWidth ?? double.infinity,
            maxHeight: maxHeight ?? double.infinity,
            alignment: alignment,
            child: Stack(
              children: [
                child,
                if (showOverflowIndicator) _buildOverflowIndicator(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverflowIndicator(BuildContext context) {
    // 该指示器需要真实的溢出检测逻辑才能正确显示。
    // 当前没有可靠的检测实现，避免保留“永远为 false”的死代码。
    return const SizedBox.shrink();
  }
}
