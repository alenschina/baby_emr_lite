import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/medication_plan_aggregate.dart';
import '../../domain/entities/medication_plan_upsert_input.dart';
import '../../domain/enums/medication_intake_status_type.dart';
import '../../domain/repositories/medication_plan_repository.dart';
import '../../domain/services/medication_slot_service.dart' as slot;
import 'baby_providers.dart';
import 'core_providers.dart';

// ============== 方案 C：今日提醒 / 打卡 / 依从性 ==============

/// 用药依从性统计（UI 层；[totalDays] 在槽位模式下表示应服次数）
class MedicationCompliance {
  final int totalDays;
  final int takenDays;
  final int missedDays;
  final int skippedDays;
  final double complianceRate;

  const MedicationCompliance({
    required this.totalDays,
    required this.takenDays,
    required this.missedDays,
    required this.skippedDays,
    required this.complianceRate,
  });
}

/// 当前宝宝的用药计划聚合列表（方案 C）
final medicationPlanAggregatesProvider =
    FutureProvider<List<MedicationPlanAggregate>>((ref) async {
      final babyId = ref.watch(currentBabyIdProvider);
      if (babyId == null) return [];

      final repository = ref.watch(medicationPlanRepositoryProvider);
      return repository.listAggregatesByBabyId(babyId);
    });

/// 进行中的用药计划聚合（endDate 为空或严格晚于今日；当日结束即不再算进行中）
final activeMedicationPlanAggregatesProvider =
    FutureProvider<List<MedicationPlanAggregate>>((ref) async {
      final all = await ref.watch(medicationPlanAggregatesProvider.future);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      return all.where((agg) {
        final end = agg.plan.endDate;
        return end == null ||
            DateTime(end.year, end.month, end.day).isAfter(todayDate);
      }).toList();
    });

class TodayMedicationCheckinItem {
  final String planId;
  final String medicationName;
  final String doseText;
  final DateTime scheduledDate;
  final String timeId;
  final String timeOfDay;
  final MedicationIntakeStatusType? status;

  const TodayMedicationCheckinItem({
    required this.planId,
    required this.medicationName,
    required this.doseText,
    required this.scheduledDate,
    required this.timeId,
    required this.timeOfDay,
    required this.status,
  });
}

/// 今日所有应打卡槽位（按 active plans + 槽位计算），并附带当前状态（若已打卡）
final todayMedicationCheckinItemsProvider =
    FutureProvider<List<TodayMedicationCheckinItem>>((ref) async {
      final activeAggs =
          await ref.watch(activeMedicationPlanAggregatesProvider.future);
      if (activeAggs.isEmpty) return [];

      final intakeRepo = ref.watch(medicationIntakeStatusRepositoryProvider);
      const svc = slot.MedicationSlotService();

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final items = <TodayMedicationCheckinItem>[];

      for (final agg in activeAggs) {
        final slots = svc.computeSlots(agg: agg, today: todayDate);
        final todaySlots =
            slots.where((s) => s.scheduledDate == todayDate).toList()
              ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));

        if (todaySlots.isEmpty) continue;

        final statuses = await intakeRepo.listByPlanId(agg.plan.id);
        final statusByKey = <String, MedicationIntakeStatusType>{};
        for (final s in statuses) {
          final key =
              '${s.planId}|${svc.normalizeDate(s.scheduledDate).toIso8601String()}|${s.timeId}';
          statusByKey[key] = s.status;
        }

        final doseText = '${agg.dose.amount}${agg.dose.unit}';

        for (final s in todaySlots) {
          items.add(
            TodayMedicationCheckinItem(
              planId: agg.plan.id,
              medicationName: agg.plan.medicationName,
              doseText: doseText,
              scheduledDate: todayDate,
              timeId: s.timeId,
              timeOfDay: s.timeOfDay,
              status: statusByKey[s.key],
            ),
          );
        }
      }

      items.sort((a, b) {
        final t = a.timeOfDay.compareTo(b.timeOfDay);
        if (t != 0) return t;
        return a.medicationName.compareTo(b.medicationName);
      });
      return items;
    });

/// 今日用药提醒项（首页「今日提醒」；一条对应一个今日槽位）
class TodayMedicationReminder {
  final String planId;
  final String medicationName;
  final String doseText;
  final String timeOfDay;
  final String timeId;
  final DateTime scheduledDate;

  const TodayMedicationReminder({
    required this.planId,
    required this.medicationName,
    required this.doseText,
    required this.timeOfDay,
    required this.timeId,
    required this.scheduledDate,
  });
}

/// 今日应服槽位中尚未打卡的项（与打卡 sheet 同源）
final todayMedicationRemindersProvider =
    FutureProvider<List<TodayMedicationReminder>>((ref) async {
      final currentId = ref.watch(currentBabyIdProvider);
      if (currentId == null) return [];

      final items = await ref.watch(todayMedicationCheckinItemsProvider.future);
      final pending = items.where((i) => i.status == null).toList();

      final reminders = pending
          .map(
            (i) => TodayMedicationReminder(
              planId: i.planId,
              medicationName: i.medicationName,
              doseText: i.doseText,
              timeOfDay: i.timeOfDay,
              timeId: i.timeId,
              scheduledDate: i.scheduledDate,
            ),
          )
          .toList()
        ..sort((a, b) {
          final t = a.timeOfDay.compareTo(b.timeOfDay);
          if (t != 0) return t;
          final n = a.medicationName.compareTo(b.medicationName);
          if (n != 0) return n;
          return a.timeId.compareTo(b.timeId);
        });

      return reminders;
    });

/// 按 planId，用计划槽位 + 打卡记录计算依从性（[totalDays] = 槽位总数）
final medicationPlanSlotComplianceProvider =
    FutureProvider.family<MedicationCompliance, String>((ref, planId) async {
      final planRepo = ref.watch(medicationPlanRepositoryProvider);
      final agg = await planRepo.getAggregateById(planId);
      if (agg == null) {
        return const MedicationCompliance(
          totalDays: 0,
          takenDays: 0,
          missedDays: 0,
          skippedDays: 0,
          complianceRate: 0,
        );
      }

      final intakeRepo = ref.watch(medicationIntakeStatusRepositoryProvider);
      const svc = slot.MedicationSlotService();

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final allSlots = svc.computeSlots(agg: agg, today: todayDate);
      final statuses = await intakeRepo.listByPlanId(planId);
      final slotResult = svc.computeCompliance(slots: allSlots, statuses: statuses);

      return MedicationCompliance(
        totalDays: slotResult.totalSlots,
        takenDays: slotResult.takenSlots,
        missedDays: slotResult.missedSlots,
        skippedDays: slotResult.skippedSlots,
        complianceRate: slotResult.complianceRate,
      );
    });

void invalidateMedicationPlanDerivedProviders(Ref ref, {String? planId}) {
  ref.invalidate(medicationPlanAggregatesProvider);
  ref.invalidate(activeMedicationPlanAggregatesProvider);
  ref.invalidate(todayMedicationCheckinItemsProvider);
  ref.invalidate(todayMedicationRemindersProvider);
  if (planId != null) {
    ref.invalidate(medicationPlanSlotComplianceProvider(planId));
  }
}

class MedicationPlanNotifier
    extends StateNotifier<AsyncValue<List<MedicationPlanAggregate>>> {
  MedicationPlanNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    _ref.listen<String?>(currentBabyIdProvider, (previous, next) {
      if (previous != next) {
        loadPlans();
      }
    });
    loadPlans();
  }

  final MedicationPlanRepository _repository;
  final Ref _ref;

  String? get _babyId => _ref.read(currentBabyIdProvider);

  Future<void> loadPlans() async {
    final babyId = _babyId;
    if (babyId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final list = await _repository.listAggregatesByBabyId(babyId);
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<MedicationPlanAggregate?> upsertPlan(MedicationPlanUpsertInput input) async {
    try {
      final agg = await _repository.upsertWithDetails(input);
      invalidateMedicationPlanDerivedProviders(_ref, planId: agg.plan.id);
      await loadPlans();
      return agg;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> deletePlan(String planId) async {
    try {
      await _repository.deletePlan(planId);
      invalidateMedicationPlanDerivedProviders(_ref, planId: planId);
      await loadPlans();
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> endPlan(String planId, DateTime endDate) async {
    try {
      final ok = await _repository.updatePlanEndDate(planId, endDate);
      if (!ok) return false;
      invalidateMedicationPlanDerivedProviders(_ref, planId: planId);
      await loadPlans();
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final medicationPlanNotifierProvider = StateNotifierProvider<
  MedicationPlanNotifier,
  AsyncValue<List<MedicationPlanAggregate>>
>((ref) {
  final repository = ref.watch(medicationPlanRepositoryProvider);
  return MedicationPlanNotifier(repository, ref);
});
