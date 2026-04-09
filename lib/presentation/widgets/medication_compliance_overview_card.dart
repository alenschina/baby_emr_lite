import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../providers/medication_providers.dart';

/// 用药「依从性」Tab 顶部总览：环形分布 + 图例 + 评级，替代单一 Progress 环。
class MedicationComplianceOverviewCard extends StatelessWidget {
  const MedicationComplianceOverviewCard({
    super.key,
    required this.isLoading,
    this.aggregate,
  });

  final bool isLoading;
  final MedicationCompliance? aggregate;

  /// 环形图区域边长（较初版缩小 15%，减轻与周边文案重叠）
  static const double _chartSize = 176.8;

  int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255).toInt();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final agg = aggregate;
    if (agg == null) {
      return const SizedBox.shrink();
    }

    final total = agg.totalDays;
    final taken = agg.takenDays;
    final missed = agg.missedDays;
    final skipped = agg.skippedDays;
    final accounted = taken + missed + skipped;
    final pending = math.max(0, total - accounted);
    final rate = agg.complianceRate;

    if (total <= 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: AppTheme.slate300),
            const SizedBox(height: 12),
            Text(
              '暂无应服次数',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                '进行中计划尚无截至今日的槽位统计',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeCaption,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final tier = _tierForRate(rate);
    final sections = _buildSections(
      taken: taken,
      missed: missed,
      skipped: skipped,
      pending: pending,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.brandPrimary.withAlpha(_alpha(0.22)),
                      AppTheme.brandPrimary.withAlpha(_alpha(0.08)),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.brandPrimary.withAlpha(_alpha(0.2)),
                  ),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 20,
                  color: AppTheme.brandPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '总体依从性',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSectionTitle,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '应服 $total 次 · 截至今日加权',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeCaption,
                        color: AppTheme.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              _TierBadge(label: tier.label, color: tier.color, light: tier.light),
            ],
          ),
          // 与圆环之间留出足够垂直间距，避免标题区与弧顶视觉挤压
          const SizedBox(height: 24),
          SizedBox(
            height: _chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: _chartSize * 0.92,
                      height: _chartSize * 0.92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.brandPrimary.withAlpha(_alpha(0.06)),
                            Colors.transparent,
                          ],
                          stops: const [0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 54.4,
                    sections: sections,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 450),
                  swapAnimationCurve: Curves.easeOutCubic,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(rate * 100).toStringAsFixed(0)}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.fontFamily,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已服占比',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeCaption,
                        color: AppTheme.textTertiary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 圆环底部与图例之间的垂直呼吸空间
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _LegendChip(
                color: AppTheme.success,
                label: '已服',
                value: taken,
              ),
              _LegendChip(
                color: AppTheme.error,
                label: '漏服',
                value: missed,
              ),
              _LegendChip(
                color: AppTheme.warning,
                label: '跳过',
                value: skipped,
              ),
              if (pending > 0)
                _LegendChip(
                  color: AppTheme.slate400,
                  label: '待打卡',
                  value: pending,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppTheme.slate200.withAlpha(_alpha(0.65))),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              '按时间点槽位统计，总览按应服次数加权',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeCaption,
                color: AppTheme.textTertiary,
                fontFamily: AppTheme.fontFamily,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TierStyle _tierForRate(double rate) {
    if (rate >= 0.8) {
      return _TierStyle('良好', AppTheme.success, AppTheme.successLight);
    }
    if (rate >= 0.5) {
      return _TierStyle('一般', AppTheme.warning, AppTheme.warningLight);
    }
    return _TierStyle('需关注', AppTheme.error, AppTheme.errorLight);
  }

  List<PieChartSectionData> _buildSections({
    required int taken,
    required int missed,
    required int skipped,
    required int pending,
  }) {
    const outer = 44.2;
    final List<PieChartSectionData> list = [];

    void add(double v, Color color) {
      if (v <= 0) return;
      list.add(
        PieChartSectionData(
          value: v,
          color: color,
          radius: outer,
          showTitle: false,
        ),
      );
    }

    add(taken.toDouble(), AppTheme.success);
    add(missed.toDouble(), AppTheme.error);
    add(skipped.toDouble(), AppTheme.warning);
    add(pending.toDouble(), AppTheme.slate300);

    if (list.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: AppTheme.slate200,
          radius: outer,
          showTitle: false,
        ),
      ];
    }
    return list;
  }
}

class _TierStyle {
  const _TierStyle(this.label, this.color, this.light);
  final String label;
  final Color color;
  final Color light;
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.label,
    required this.color,
    required this.light,
  });

  final String label;
  final Color color;
  final Color light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: light.withAlpha((0.85 * 255).round().clamp(0, 255)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha((0.28 * 255).round().clamp(0, 255)),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppTheme.fontSizeMicro,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round().clamp(0, 255)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha((0.22 * 255).round().clamp(0, 255)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            maxLines: 1,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
