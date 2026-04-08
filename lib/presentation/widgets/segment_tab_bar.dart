import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 分段 Tab 栏（用药管理、疫苗接种等顶部切换）
/// 与用药管理页 [MedicationTabBar] 视觉一致：玻璃容器 + 渐变指示器 + 图标+文案
class SegmentTabItem {
  const SegmentTabItem({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

class SegmentTabBar extends StatelessWidget {
  const SegmentTabBar({
    super.key,
    required this.controller,
    required this.items,
  });

  final TabController controller;
  final List<SegmentTabItem> items;

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty, 'SegmentTabBar requires at least one tab');
    final tabCount = items.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // 与用药页一致：外边距 16×2 + 内边距 6×2 = 44
        final tabWidth = (availableWidth - 44) / tabCount;
        final compact = tabWidth < 108;
        final veryCompact = tabWidth < 92;

        final fontSize = veryCompact ? 11.0 : (compact ? 12.0 : 14.0);
        final iconSize = veryCompact ? 14.0 : (compact ? 16.0 : 18.0);
        final horizontalMarginResolved =
            veryCompact ? 10.0 : 16.0;
        final tabPaddingResolved = veryCompact ? 4.0 : 6.0;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMarginResolved),
          padding: EdgeInsets.all(tabPaddingResolved),
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
              for (final item in items)
                _buildAdaptiveTab(
                  icon: item.icon,
                  title: item.title,
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
