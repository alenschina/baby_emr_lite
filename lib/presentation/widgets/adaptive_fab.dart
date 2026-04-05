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

  const AdaptiveFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.iconColor,
    this.tooltip,
    this.extraSpacing = 16.0,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: extraSpacing, right: extraSpacing),
          child: GlassIconContainer(
            icon: icon,
            size: size,
            iconSize: 20,
            iconColor: iconColor ?? AppTheme.textSecondary,
            onTap: onPressed,
          ),
        ),
      ),
    );
  }
}
