import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/medication_frequency.dart';
import '../../../domain/entities/medication_plan_aggregate.dart';
import '../../../domain/enums/medication_frequency_type.dart';
import '../../providers/medication_providers.dart';
import '../card_outlined_action_button.dart';
import '../glass_card.dart';

String medicationFrequencyDisplay(MedicationFrequency f) {
  return switch (f.type) {
    MedicationFrequencyType.none => '未设置',
    MedicationFrequencyType.daily => '每天',
    MedicationFrequencyType.everyNDays =>
      '每${(f.interval ?? 1).clamp(1, 365000)}天',
    MedicationFrequencyType.everyNWeeks =>
      '每${(f.interval ?? 1).clamp(1, 5200)}周',
  };
}

int _alphaFromOpacity(double opacity) =>
    (opacity * 255).round().clamp(0, 255).toInt();

/// 方案 C：用药计划卡片（列表展示）
class MedicationPlanCard extends ConsumerWidget {
  final MedicationPlanAggregate aggregate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onEndPlan;
  /// 打开「仅本计划」的今日打卡；多条计划时与右上角「全部」区分
  final VoidCallback? onOpenTodayCheckin;

  const MedicationPlanCard({
    super.key,
    required this.aggregate,
    this.onEdit,
    this.onDelete,
    this.onEndPlan,
    this.onOpenTodayCheckin,
  });

  bool _isActiveOnDate(DateTime todayDate) {
    final end = aggregate.plan.endDate;
    if (end == null) return true;
    final endD = DateTime(end.year, end.month, end.day);
    return endD.isAfter(todayDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final isActive = _isActiveOnDate(todayDate);

    final timesText = aggregate.times.isEmpty
        ? '未设置时间点'
        : aggregate.times.map((t) => t.timeOfDay).join('、');

    final complianceAsync = ref.watch(
      medicationPlanSlotComplianceProvider(aggregate.plan.id),
    );

    final checkinAsync = ref.watch(todayMedicationCheckinItemsProvider);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  aggregate.plan.medicationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              StatusBadge(
                text: isActive ? '进行中' : '已结束',
                type: isActive ? StatusType.success : StatusType.info,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.medication_outlined,
                text: '${aggregate.dose.amount}${aggregate.dose.unit}',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.schedule,
                text: medicationFrequencyDisplay(aggregate.frequency),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.access_time, size: 16, color: AppTheme.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timesText,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.date_range, size: 16, color: AppTheme.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatDate(aggregate.plan.startDate)} - ${aggregate.plan.endDate != null ? _formatDate(aggregate.plan.endDate!) : "进行中"}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          if (aggregate.plan.notes != null &&
              aggregate.plan.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.slate50.withAlpha(_alphaFromOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_outlined,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aggregate.plan.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isActive)
            complianceAsync.when(
              data: (compliance) {
                if (compliance.totalDays == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: compliance.complianceRate,
                            backgroundColor: AppTheme.slate200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              compliance.complianceRate >= 0.8
                                  ? AppTheme.success
                                  : compliance.complianceRate >= 0.5
                                  ? AppTheme.warning
                                  : AppTheme.error,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(compliance.complianceRate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, st) => const SizedBox.shrink(),
            ),
          if (isActive && onOpenTodayCheckin != null) ...[
            const SizedBox(height: 12),
            checkinAsync.when(
              data: (items) {
                final mine =
                    items.where((i) => i.planId == aggregate.plan.id).toList();
                final pending =
                    mine.where((i) => i.status == null).length;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOpenTodayCheckin,
                    icon: const Icon(Icons.fact_check_outlined, size: 20),
                    label: Text(
                      pending > 0
                          ? '今日打卡（待完成 $pending 次）'
                          : '今日打卡',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusButton,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, st) => const SizedBox.shrink(),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isActive && onEndPlan != null)
                  CardOutlinedActionButton(
                    icon: Icons.stop_circle_outlined,
                    label: '结束用药',
                    foreground: AppTheme.warning,
                    onPressed: onEndPlan!,
                  ),
                if (onEdit != null)
                  CardOutlinedActionButton(
                    icon: Icons.edit_outlined,
                    label: '编辑',
                    foreground: AppTheme.textSecondary,
                    onPressed: onEdit!,
                  ),
                if (onDelete != null)
                  CardOutlinedActionButton(
                    icon: Icons.delete_outline,
                    label: '删除',
                    foreground: AppTheme.error,
                    onPressed: onDelete!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.brandPrimary.withAlpha(_alphaFromOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.brandPrimary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.brandPrimary,
                fontFamily: AppTheme.fontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }
}
