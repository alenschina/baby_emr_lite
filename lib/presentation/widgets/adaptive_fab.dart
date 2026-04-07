import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'glass_card.dart';

/// 顶部右侧浮动操作按钮
/// 与首页设置按钮保持完全一致的视觉样式与交互方式
class AdaptiveFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? iconColor;
  final String? tooltip;
  final double extraSpacing;
  final double size;

  /// 可选第二颗按钮（与主按钮相同 Glass 样式，横向排在主按钮左侧，贴近屏幕右缘仍为一行）
  final VoidCallback? secondaryOnPressed;
  final IconData? secondaryIcon;
  final String? secondaryTooltip;
  final double secondaryGap;

  const AdaptiveFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.iconColor,
    this.tooltip,
    this.extraSpacing = 16.0,
    this.size = 40.0,
    this.secondaryOnPressed,
    this.secondaryIcon,
    this.secondaryTooltip,
    this.secondaryGap = 10.0,
  });

  Widget _glassAction({
    required IconData iconData,
    required VoidCallback onTap,
    String? tip,
  }) {
    final child = GlassIconContainer(
      icon: iconData,
      size: size,
      iconSize: 20,
      iconColor: iconColor ?? AppTheme.textSecondary,
      onTap: onTap,
    );
    if (tip != null && tip.isNotEmpty) {
      return Tooltip(message: tip, child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: extraSpacing, right: extraSpacing),
          child: secondaryOnPressed != null && secondaryIcon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _glassAction(
                      iconData: secondaryIcon!,
                      onTap: secondaryOnPressed!,
                      tip: secondaryTooltip,
                    ),
                    SizedBox(width: secondaryGap),
                    _glassAction(
                      iconData: icon,
                      onTap: onPressed,
                      tip: tooltip,
                    ),
                  ],
                )
              : _glassAction(
                  iconData: icon,
                  onTap: onPressed,
                  tip: tooltip,
                ),
        ),
      ),
    );
  }
}
