import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 用药管理 Tab 栏
/// 对应 Web 版 Tab 切换
class MedicationTabBar extends StatelessWidget {
  final TabController controller;

  const MedicationTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final tabWidth = (availableWidth - 44) / 3;
        final compact = tabWidth < 108;
        final veryCompact = tabWidth < 92;

        final fontSize = veryCompact ? 11.0 : (compact ? 12.0 : 14.0);
        final iconSize = veryCompact ? 14.0 : (compact ? 16.0 : 18.0);
        final tabPadding = veryCompact ? 4.0 : 6.0;
        final horizontalMargin = veryCompact ? 10.0 : 16.0;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          padding: EdgeInsets.all(tabPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: TabBar(
            controller: controller,
            isScrollable: veryCompact,
            labelPadding: EdgeInsets.symmetric(horizontal: veryCompact ? 6 : 0),
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.brandPrimary, Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.slate600,
            labelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              _buildAdaptiveTab(
                icon: Icons.medication,
                title: '当前用药',
                iconSize: iconSize,
                spacing: compact ? 4 : 6,
                minWidth: veryCompact ? 88 : null,
              ),
              _buildAdaptiveTab(
                icon: Icons.history,
                title: '用药历史',
                iconSize: iconSize,
                spacing: compact ? 4 : 6,
                minWidth: veryCompact ? 88 : null,
              ),
              _buildAdaptiveTab(
                icon: Icons.bar_chart,
                title: '依从性',
                iconSize: iconSize,
                spacing: compact ? 4 : 6,
                minWidth: veryCompact ? 88 : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdaptiveTab({
    required IconData icon,
    required String title,
    required double iconSize,
    required double spacing,
    double? minWidth,
  }) {
    return Tab(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth ?? 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize),
            SizedBox(width: spacing),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
