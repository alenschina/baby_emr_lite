import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bottom_sheet_utils.dart';

/// 适配浮动导航栏的浮动添加按钮
///
/// 自动计算底部边距，确保按钮不会被底部导航栏遮挡
class AdaptiveFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final double extraSpacing;

  const AdaptiveFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.extraSpacing = 24.0, // FAB 与底部导航栏之间的间距
  });

  @override
  Widget build(BuildContext context) {
    final bottomMargin = BottomSheetUtils.getFabBottomMargin(
      context,
      extraSpacing: extraSpacing,
    );

    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.fabShadow,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? AppTheme.brandPrimary,
        tooltip: tooltip,
        child: Icon(icon, color: iconColor ?? Colors.white),
      ),
    );
  }
}
