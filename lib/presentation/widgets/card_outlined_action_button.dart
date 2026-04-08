import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 卡片列表项次要操作：描边 + 图标 + 文案（用药计划、疫苗记录等卡片统一使用）。
class CardOutlinedActionButton extends StatelessWidget {
  const CardOutlinedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final VoidCallback onPressed;

  int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255).toInt();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeCaption,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: foreground.withAlpha(_alpha(0.38))),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
      ),
    );
  }
}
