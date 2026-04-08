import 'package:flutter/material.dart';
import 'segment_tab_bar.dart';

/// 用药管理 Tab 栏
/// 对应 Web 版 Tab 切换
class MedicationTabBar extends StatelessWidget {
  final TabController controller;

  const MedicationTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SegmentTabBar(
      controller: controller,
      items: const [
        SegmentTabItem(icon: Icons.medication, title: '当前用药'),
        SegmentTabItem(icon: Icons.history, title: '用药历史'),
        SegmentTabItem(icon: Icons.bar_chart, title: '依从性'),
      ],
    );
  }
}
