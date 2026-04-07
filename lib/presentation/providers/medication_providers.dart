import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/medication_record.dart';
import '../../domain/entities/medication_status.dart';
import '../../domain/entities/medication_reminder.dart';
import '../../domain/entities/medication_plan_aggregate.dart';
import '../../domain/enums/medication_status_type.dart';
import '../../domain/enums/medication_intake_status_type.dart';
import '../../domain/repositories/medication_record_repository.dart';
import '../../domain/repositories/medication_status_repository.dart';
import '../../domain/repositories/medication_reminder_repository.dart';
import '../../domain/repositories/medication_plan_repository.dart';
import '../../domain/repositories/medication_intake_status_repository.dart';
import 'core_providers.dart';
import 'baby_providers.dart';
import '../../domain/services/medication_slot_service.dart' as slot;

// ============== MedicationRecord Providers ==============

/// 当前宝宝的用药记录列表 Provider
final medicationRecordsProvider = FutureProvider<List<MedicationRecord>>((
  ref,
) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return [];

  final repository = ref.watch(medicationRecordRepositoryProvider);
  return repository.getByBabyId(currentId);
});

/// 正在进行的用药记录 Provider
final activeMedicationsProvider = FutureProvider<List<MedicationRecord>>((
  ref,
) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return [];

  final repository = ref.watch(medicationRecordRepositoryProvider);
  return repository.getActive(currentId);
});

/// 已结束的用药记录 Provider
final inactiveMedicationsProvider = FutureProvider<List<MedicationRecord>>((
  ref,
) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return [];

  final repository = ref.watch(medicationRecordRepositoryProvider);
  return repository.getInactive(currentId);
});

/// 今日用药提醒项
class TodayMedicationReminder {
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String scheduledTime;

  const TodayMedicationReminder({
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
  });
}

/// 今日用药提醒 Provider
/// 监听用药记录变化，自动刷新提醒列表
final todayMedicationRemindersProvider =
    FutureProvider<List<TodayMedicationReminder>>((ref) async {
      final currentId = ref.watch(currentBabyIdProvider);
      if (currentId == null) return [];

      // 监听用药记录变化以触发刷新
      final _ = ref.watch(medicationRecordNotifierProvider);

      final repository = ref.watch(medicationRecordRepositoryProvider);
      final statusRepository = ref.watch(medicationStatusRepositoryProvider);
      final activeMedications = await repository.getActive(currentId);

      final reminders = <TodayMedicationReminder>[];
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      for (final medication in activeMedications) {
        // 检查今天是否已有记录
        final statuses = await statusRepository.getByMedicationId(
          medication.id,
        );
        final hasTodayRecord = statuses.any((s) {
          final sDate = DateTime(s.date.year, s.date.month, s.date.day);
          return sDate.isAtSameMomentAs(todayDate);
        });

        // 如果今天没有记录，添加提醒
        if (!hasTodayRecord) {
          reminders.add(
            TodayMedicationReminder(
              medicationId: medication.id,
              medicationName: medication.name,
              dosage: medication.dosage,
              scheduledTime: medication.scheduledTime ?? '09:00',
            ),
          );
        }
      }

      // 按时间排序
      reminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return reminders;
    });

/// 用药记录操作 Notifier
/// 能够响应当前宝宝变化并自动刷新数据
class MedicationRecordNotifier
    extends StateNotifier<AsyncValue<List<MedicationRecord>>> {
  final MedicationRecordRepository _repository;
  final Ref _ref;

  MedicationRecordNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    // 监听当前宝宝 ID 变化
    _ref.listen<String?>(currentBabyIdProvider, (previous, next) {
      if (previous != next) {
        loadRecords();
      }
    });
    // 初始加载
    loadRecords();
  }

  String? get _babyId => _ref.read(currentBabyIdProvider);

  Future<void> loadRecords() async {
    final babyId = _babyId;
    if (babyId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final records = await _repository.getByBabyId(babyId);
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<MedicationRecord?> create({
    required String name,
    required String dosage,
    required String frequency,
    String? scheduledTime,
    required DateTime startDate,
    DateTime? endDate,
    required int stockQuantity,
    required String unit,
    String? notes,
  }) async {
    final babyId = _babyId;
    if (babyId == null) return null;

    try {
      final record = await _repository.create(
        babyId: babyId,
        name: name,
        dosage: dosage,
        frequency: frequency,
        scheduledTime: scheduledTime,
        startDate: startDate,
        endDate: endDate,
        stockQuantity: stockQuantity,
        unit: unit,
        notes: notes,
      );
      // 重新加载以确保数据同步
      await loadRecords();
      return record;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<MedicationRecord?> update(
    String id, {
    String? name,
    String? dosage,
    String? frequency,
    String? scheduledTime,
    DateTime? startDate,
    DateTime? endDate,
    int? stockQuantity,
    String? unit,
    String? notes,
    bool? isActive,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        name: name,
        dosage: dosage,
        frequency: frequency,
        scheduledTime: scheduledTime,
        startDate: startDate,
        endDate: endDate,
        stockQuantity: stockQuantity,
        unit: unit,
        notes: notes,
        isActive: isActive,
      );

      final records = state.value ?? [];
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        records[index] = updated;
        state = AsyncValue.data([...records]);
      }
      return updated;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<MedicationRecord?> updateStock(String id, int newQuantity) async {
    try {
      final updated = await _repository.updateStock(id, newQuantity);

      final records = state.value ?? [];
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        records[index] = updated;
        state = AsyncValue.data([...records]);
      }
      return updated;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<MedicationRecord?> endMedication(String id, DateTime endDate) async {
    try {
      final updated = await _repository.endMedication(id, endDate);

      final records = state.value ?? [];
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        records[index] = updated;
        state = AsyncValue.data([...records]);
      }
      return updated;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      state = AsyncValue.data(
        state.value?.where((r) => r.id != id).toList() ?? [],
      );
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// 用药记录 Notifier Provider
final medicationRecordNotifierProvider =
    StateNotifierProvider<
      MedicationRecordNotifier,
      AsyncValue<List<MedicationRecord>>
    >((ref) {
      final repository = ref.watch(medicationRecordRepositoryProvider);
      return MedicationRecordNotifier(repository, ref);
    });

// ============== MedicationStatus Providers ==============

/// 指定用药记录的状态列表 Provider
final medicationStatusProvider =
    FutureProvider.family<List<MedicationStatus>, String>((
      ref,
      medicationId,
    ) async {
      final repository = ref.watch(medicationStatusRepositoryProvider);
      return repository.getByMedicationId(medicationId);
    });

/// 今日待记录的状态 Provider
final todayPendingStatusProvider =
    FutureProvider.family<List<MedicationStatus>, String>((
      ref,
      medicationId,
    ) async {
      final repository = ref.watch(medicationStatusRepositoryProvider);
      return repository.getTodayPending(medicationId);
    });

/// 用药状态操作 Notifier
class MedicationStatusNotifier
    extends StateNotifier<AsyncValue<List<MedicationStatus>>> {
  final MedicationStatusRepository _repository;
  final String _medicationId;

  MedicationStatusNotifier(this._repository, this._medicationId)
    : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getByMedicationId(_medicationId);
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<MedicationStatus?> create({
    required DateTime date,
    required MedicationStatusType status,
    String? notes,
    int? stockDelta,
  }) async {
    try {
      final record = await _repository.create(
        medicationId: _medicationId,
        date: date,
        status: status,
        notes: notes,
        stockDelta: stockDelta,
      );
      state = AsyncValue.data([record, ...state.value ?? []]);
      return record;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<MedicationStatus?> update(
    String id, {
    MedicationStatusType? status,
    String? notes,
    int? stockDelta,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        status: status,
        notes: notes,
        stockDelta: stockDelta,
      );

      final records = state.value ?? [];
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        records[index] = updated;
        state = AsyncValue.data([...records]);
      }
      return updated;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      state = AsyncValue.data(
        state.value?.where((r) => r.id != id).toList() ?? [],
      );
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// 用药状态 Notifier Provider
final medicationStatusNotifierProvider =
    StateNotifierProvider.family<
      MedicationStatusNotifier,
      AsyncValue<List<MedicationStatus>>,
      String
    >((ref, medicationId) {
      final repository = ref.watch(medicationStatusRepositoryProvider);
      return MedicationStatusNotifier(repository, medicationId);
    });

// ============== MedicationReminder Providers ==============

/// 指定用药记录的提醒列表 Provider
final medicationRemindersProvider =
    FutureProvider.family<List<MedicationReminder>, String>((
      ref,
      medicationId,
    ) async {
      final repository = ref.watch(medicationReminderRepositoryProvider);
      return repository.getByMedicationId(medicationId);
    });

/// 所有已启用的提醒 Provider
final allEnabledRemindersProvider = FutureProvider<List<MedicationReminder>>((
  ref,
) async {
  final repository = ref.watch(medicationReminderRepositoryProvider);
  return repository.getAllEnabled();
});

/// 用药提醒操作 Notifier
class MedicationReminderNotifier
    extends StateNotifier<AsyncValue<List<MedicationReminder>>> {
  final MedicationReminderRepository _repository;
  final String _medicationId;

  MedicationReminderNotifier(this._repository, this._medicationId)
    : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getByMedicationId(_medicationId);
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<MedicationReminder?> create({required String reminderTime}) async {
    try {
      final record = await _repository.create(
        medicationId: _medicationId,
        reminderTime: reminderTime,
      );
      state = AsyncValue.data([record, ...state.value ?? []]);
      return record;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<MedicationReminder?> update(
    String id, {
    String? reminderTime,
    bool? isEnabled,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        reminderTime: reminderTime,
        isEnabled: isEnabled,
      );

      final records = state.value ?? [];
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        records[index] = updated;
        state = AsyncValue.data([...records]);
      }
      return updated;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<MedicationReminder?> toggleEnabled(String id) async {
    try {
      final updated = await _repository.toggleEnabled(id);

      final records = state.value ?? [];
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        records[index] = updated;
        state = AsyncValue.data([...records]);
      }
      return updated;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      state = AsyncValue.data(
        state.value?.where((r) => r.id != id).toList() ?? [],
      );
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// 用药提醒 Notifier Provider
final medicationReminderNotifierProvider =
    StateNotifierProvider.family<
      MedicationReminderNotifier,
      AsyncValue<List<MedicationReminder>>,
      String
    >((ref, medicationId) {
      final repository = ref.watch(medicationReminderRepositoryProvider);
      return MedicationReminderNotifier(repository, medicationId);
    });

// ============== 用药依从性统计 Provider ==============

/// 用药依从性统计
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

/// 计算用药依从性
MedicationCompliance calculateCompliance(List<MedicationStatus> statuses) {
  if (statuses.isEmpty) {
    return const MedicationCompliance(
      totalDays: 0,
      takenDays: 0,
      missedDays: 0,
      skippedDays: 0,
      complianceRate: 0,
    );
  }

  final takenDays = statuses
      .where((s) => s.status == MedicationStatusType.taken)
      .length;
  final missedDays = statuses
      .where((s) => s.status == MedicationStatusType.missed)
      .length;
  final skippedDays = statuses
      .where((s) => s.status == MedicationStatusType.skipped)
      .length;
  final totalDays = statuses.length;
  final complianceRate = takenDays / totalDays;

  return MedicationCompliance(
    totalDays: totalDays,
    takenDays: takenDays,
    missedDays: missedDays,
    skippedDays: skippedDays,
    complianceRate: complianceRate,
  );
}

/// 用药依从性 Provider
final medicationComplianceProvider =
    FutureProvider.family<MedicationCompliance, String>((
      ref,
      medicationId,
    ) async {
      final repository = ref.watch(medicationStatusRepositoryProvider);
      final statuses = await repository.getByMedicationId(medicationId);
      return calculateCompliance(statuses);
    });

// ============== 方案 C：按时间点打卡（最小接入） ==============

/// 当前宝宝的用药计划聚合列表（方案 C）
final medicationPlanAggregatesProvider =
    FutureProvider<List<MedicationPlanAggregate>>((ref) async {
      final babyId = ref.watch(currentBabyIdProvider);
      if (babyId == null) return [];

      final repository = ref.watch(medicationPlanRepositoryProvider);
      return repository.listAggregatesByBabyId(babyId);
    });

/// 进行中的用药计划聚合（endDate 为空或 >= 今日）
final activeMedicationPlanAggregatesProvider =
    FutureProvider<List<MedicationPlanAggregate>>((ref) async {
      final all = await ref.watch(medicationPlanAggregatesProvider.future);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      return all.where((agg) {
        final end = agg.plan.endDate;
        return end == null ||
            !DateTime(end.year, end.month, end.day).isBefore(todayDate);
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

      // 先按时间，再按药名
      items.sort((a, b) {
        final t = a.timeOfDay.compareTo(b.timeOfDay);
        if (t != 0) return t;
        return a.medicationName.compareTo(b.medicationName);
      });
      return items;
    });
