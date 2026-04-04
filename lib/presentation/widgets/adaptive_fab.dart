import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bottom_sheet_utils.dart';

/// Liquid 风格浮动添加按钮
///
/// 参考首页设置按钮的玻璃拟态设计风格
/// 采用径向渐变背景、多层柔和阴影和细腻边框，呈现流体感的视觉效果
/// 自动计算底部边距，确保按钮不会被底部导航栏遮挡
class AdaptiveFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? gradientColor;
  final Color? iconColor;
  final String? tooltip;
  final double extraSpacing;
  final double size;

  const AdaptiveFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.gradientColor,
    this.iconColor,
    this.tooltip,
    this.extraSpacing = 36.0, // FAB 与底部导航栏之间的间距（增大以避免重叠）
    this.size = 56.0, // FAB 默认尺寸
  });

  @override
  Widget build(BuildContext context) {
    final bottomMargin = BottomSheetUtils.getFabBottomMargin(
      context,
      extraSpacing: extraSpacing,
    );

    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: AppTheme.liquidFabDecoration(gradientColor: gradientColor),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
