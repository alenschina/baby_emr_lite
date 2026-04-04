import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Liquid 风格浮动添加按钮
///
/// 参考首页设置按钮的玻璃拟态设计风格
/// 采用径向渐变背景、多层柔和阴影和细腻边框，呈现流体感的视觉效果
/// 定位在右上角，尺寸与页面标题字体大小（24px）协调
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
    this.extraSpacing = 16.0, // FAB 与顶部边缘之间的间距
    this.size = 40.0, // FAB 尺寸调整为 40px，与 24px 标题字体视觉协调
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: extraSpacing,
            right: extraSpacing,
          ),
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
                size: 20, // 图标尺寸调整为 20px，与按钮尺寸协调
              ),
            ),
          ),
        ),
      ),
    );
  }
}
