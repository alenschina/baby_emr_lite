import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/enums/medication_intake_status_type.dart';
import '../providers/medication_providers.dart';
import '../providers/core_providers.dart';
import 'glass_card.dart';

class MedicationTodayCheckinSheet extends ConsumerWidget {
  /// 若设置，仅展示该用药计划今日的槽位（从卡片进入时可区分多条计划）
  final String? filterPlanId;
  final String? filterPlanName;

  const MedicationTodayCheckinSheet({
    super.key,
    this.filterPlanId,
    this.filterPlanName,
  });

  int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255).toInt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayMedicationCheckinItemsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: AppTheme.glassCardGradientHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
      ),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e.toString()),
        data: (items) {
          final filtered = filterPlanId == null
              ? items
              : items.where((i) => i.planId == filterPlanId).toList();
          final title = filterPlanId == null
              ? '今日用药打卡'
              : '今日打卡 · ${filterPlanName ?? '用药'}';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
              if (filterPlanId != null) ...[
                const SizedBox(height: 4),
                Text(
                  '仅显示本条计划的今日时间点',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                _buildEmpty(singlePlan: filterPlanId != null)
              else
                _buildList(context, ref, filtered),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty({bool singlePlan = false}) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(_alpha(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              singlePlan
                  ? '该计划今日无需打卡（无排期时间点或已全部记录）'
                  : '今天暂无需要打卡的用药时间点',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.error.withAlpha(_alpha(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '加载失败：$message',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<TodayMedicationCheckinItem> items,
  ) {
    // 分组：planId
    final byPlan = <String, List<TodayMedicationCheckinItem>>{};
    for (final i in items) {
      (byPlan[i.planId] ??= []).add(i);
    }

    final planIds = byPlan.keys.toList()
      ..sort(
        (a, b) => byPlan[a]!.first.medicationName.compareTo(
          byPlan[b]!.first.medicationName,
        ),
      );

    return Flexible(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final planId in planIds) ...[
            _buildPlanSection(context, ref, byPlan[planId]!),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanSection(
    BuildContext context,
    WidgetRef ref,
    List<TodayMedicationCheckinItem> items,
  ) {
    final title = items.first.medicationName;
    final doseText = items.first.doseText;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              Text(
                '每次$doseText',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            _buildSlotRow(context, ref, item),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotRow(
    BuildContext context,
    WidgetRef ref,
    TodayMedicationCheckinItem item,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            item.timeOfDay,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip(
                context,
                ref,
                item,
                MedicationIntakeStatusType.taken,
                AppTheme.success,
              ),
              _statusChip(
                context,
                ref,
                item,
                MedicationIntakeStatusType.missed,
                AppTheme.error,
              ),
              _statusChip(
                context,
                ref,
                item,
                MedicationIntakeStatusType.skipped,
                AppTheme.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(
    BuildContext context,
    WidgetRef ref,
    TodayMedicationCheckinItem item,
    MedicationIntakeStatusType value,
    Color color,
  ) {
    final selected = item.status == value;
    final repo = ref.watch(medicationIntakeStatusRepositoryProvider);

    return ChoiceChip(
      label: Text(value.label),
      selected: selected,
      onSelected: (_) async {
        await repo.upsertForSlot(
          planId: item.planId,
          scheduledDate: item.scheduledDate,
          timeId: item.timeId,
          status: value,
        );
        ref.invalidate(todayMedicationCheckinItemsProvider);
        ref.invalidate(todayMedicationRemindersProvider);
        ref.invalidate(medicationPlanSlotComplianceProvider(item.planId));
      },
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? Colors.white : color,
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: color,
      backgroundColor: color.withAlpha(_alpha(0.08)),
      side: BorderSide(color: color.withAlpha(_alpha(0.35))),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}

