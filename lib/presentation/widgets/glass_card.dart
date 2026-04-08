import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255).toInt();

/// Liquid 风格卡片组件
/// 现代流体设计语言：柔和有机形状、流体渐变、光泽感
/// 特点：
/// - 高透明度白色基底（92%/78%）
/// - 多层柔和阴影（柔和扩散 + 环境光）
/// - 细腻的内发光边框
/// - 大圆角（24px）
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final VoidCallback? onTap;
  final bool isHighLight;
  final Gradient? gradient;
  final bool showShadow;
  final bool useLiquidStyle;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.border,
    this.onTap,
    this.isHighLight = false,
    this.gradient,
    this.showShadow = true,
    this.useLiquidStyle = true,
  });

  /// 创建 Liquid 风格卡片（默认）
  factory GlassCard.liquid({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      key: key,
      useLiquidStyle: true,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  /// 创建高亮卡片
  factory GlassCard.highlight({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      key: key,
      isHighLight: true,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  /// 创建无阴影卡片
  factory GlassCard.flat({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      key: key,
      showShadow: false,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Liquid 风格：使用新的装饰方法
    final decoration = useLiquidStyle
        ? AppTheme.liquidGradientCard.copyWith(
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppTheme.radiusCard,
            ),
          )
        : BoxDecoration(
            gradient:
                gradient ??
                (isHighLight
                    ? AppTheme.glassCardGradientHigh
                    : AppTheme.glassCardGradient),
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppTheme.radiusCard,
            ),
            border:
                border ??
                Border.all(
                  color: Colors.white.withAlpha(_alpha(0.8)),
                  width: 1.5,
                ),
            boxShadow: showShadow
                ? (boxShadow ?? AppTheme.glassCardShadow)
                : null,
          );

    final cardWidget = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppTheme.cardPadding),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

/// Liquid 风格图标容器
/// 柔和背景 + 微妙光泽
class GlassIconContainer extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final VoidCallback? onTap;
  final Color? gradientColor;

  const GlassIconContainer({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.onTap,
    this.gradientColor,
  });

  @override
  Widget build(BuildContext context) {
    final containerSize = size ?? 48;
    final containerIconSize = iconSize ?? 24;

    final widget = Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        // Liquid 风格渐变背景
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [
            Colors.white.withAlpha(_alpha(0.95)),
            backgroundColor ?? Colors.white.withAlpha(_alpha(0.75)),
            (gradientColor ?? AppTheme.brandPrimary).withAlpha(_alpha(0.08)),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusIconContainer),
        border: Border.all(
          color: Colors.white.withAlpha(_alpha(0.8)),
          width: 1.5,
        ),
        // 柔和阴影
        boxShadow: [
          BoxShadow(
            color: (gradientColor ?? AppTheme.brandPrimary).withAlpha(_alpha(0.1)),
            blurRadius: 15,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: containerIconSize,
          color: iconColor ?? AppTheme.textSecondary,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: widget,
      );
    }

    return widget;
  }
}

/// Liquid 风格渐变按钮
/// 柔和渐变 + 光泽感 + 柔和阴影
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height ?? 52,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          // Liquid 风格渐变
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C6CF0), // 浅紫蓝
              Color(0xFF6B5CE7), // 主色
              Color(0xFF5B4DD9), // 深紫蓝
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          // Liquid 风格柔和阴影
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5CE7).withAlpha(_alpha(0.35)),
              blurRadius: 25,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFFF6BBD).withAlpha(_alpha(0.15)),
              blurRadius: 15,
              offset: const Offset(5, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppTheme.fontSizeBody,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liquid 风格状态标签
/// 柔和背景 + 细腻边框
class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  final bool isOutlined;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = StatusType.success,
    this.isOutlined = true,
  });

  @override
  Widget build(BuildContext context) {
    // Liquid 风格：更柔和的颜色
    final (backgroundColor, textColor, borderColor) = switch (type) {
      StatusType.success => (
        const Color(0xFFE8FAF3), // 柔和绿色背景
        const Color(0xFF059669), // 翠绿色文字
        const Color(0xFFA7F3D0), // 浅绿边框
      ),
      StatusType.warning => (
        const Color(0xFFFFF7ED), // 柔和橙色背景
        const Color(0xFFD97706), // 琥珀色文字
        const Color(0xFFFED7AA), // 浅橙边框
      ),
      StatusType.error => (
        const Color(0xFFFEF2F2), // 柔和红色背景
        const Color(0xFFDC2626), // 红色文字
        const Color(0xFFFECACA), // 浅红边框
      ),
      StatusType.info => (
        const Color(0xFFEFF6FF), // 柔和蓝色背景
        const Color(0xFF2563EB), // 蓝色文字
        const Color(0xFFBFDBFE), // 浅蓝边框
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20), // 更圆润
        border: isOutlined ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTheme.fontSizeCaption,
          fontWeight: FontWeight.w500,
          color: textColor,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}

enum StatusType { success, warning, error, info }
