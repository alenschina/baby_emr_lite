import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/repositories/vaccination_record_repository.dart';
import 'core_providers.dart';
import 'baby_providers.dart';

/// 当前宝宝的疫苗接种记录列表 Provider
final vaccinationRecordsProvider = FutureProvider<List<VaccinationRecord>>((
  ref,
) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return [];

  final repository = ref.watch(vaccinationRecordRepositoryProvider);
  return repository.getByBabyId(currentId);
});

/// 待接种的疫苗列表 Provider
final pendingVaccinationsProvider = FutureProvider<List<VaccinationRecord>>((
  ref,
) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return [];

  final repository = ref.watch(vaccinationRecordRepositoryProvider);
  return repository.getPending(currentId);
});

/// 已完成的疫苗列表 Provider
final completedVaccinationsProvider = FutureProvider<List<VaccinationRecord>>((
  ref,
) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return [];

  final repository = ref.watch(vaccinationRecordRepositoryProvider);
  return repository.getCompleted(currentId);
});

/// 今日疫苗提醒项
class TodayVaccinationReminder {
  final String recordId;
  final String vaccineName;
  final DateTime scheduledDate;

  const TodayVaccinationReminder({
    required this.recordId,
    required this.vaccineName,
    required this.scheduledDate,
  });
}

/// 今日疫苗提醒 Provider
/// 获取计划日期为今天且未完成的疫苗接种
/// 监听疫苗记录变化，自动刷新提醒列表
final todayVaccinationRemindersProvider =
    FutureProvider<List<TodayVaccinationReminder>>((ref) async {
      final currentId = ref.watch(currentBabyIdProvider);
      if (currentId == null) return [];

      // 监听疫苗记录变化以触发刷新
      final _ = ref.watch(vaccinationRecordNotifierProvider);

      final repository = ref.watch(vaccinationRecordRepositoryProvider);
      final pendingRecords = await repository.getPending(currentId);

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      return pendingRecords
          .where((record) {
            final scheduledDate = DateTime(
              record.scheduledDate.year,
              record.scheduledDate.month,
              record.scheduledDate.day,
            );
            return scheduledDate.isAtSameMomentAs(todayDate);
          })
          .map(
            (record) => TodayVaccinationReminder(
              recordId: record.id,
              vaccineName: record.vaccineName,
              scheduledDate: record.scheduledDate,
            ),
          )
          .toList();
    });

/// 疫苗接种记录操作 Notifier
/// 能够响应当前宝宝变化并自动刷新数据
class VaccinationRecordNotifier
    extends StateNotifier<AsyncValue<List<VaccinationRecord>>> {
  final VaccinationRecordRepository _repository;
  final Ref _ref;

  VaccinationRecordNotifier(this._repository, this._ref)
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

  Future<VaccinationRecord?> create({
    required String vaccineName,
    required DateTime scheduledDate,
    DateTime? actualDate,
    String? batchNumber,
    String? injectionSite,
  }) async {
    final babyId = _babyId;
    if (babyId == null) return null;

    try {
      final record = await _repository.create(
        babyId: babyId,
        vaccineName: vaccineName,
        scheduledDate: scheduledDate,
        actualDate: actualDate,
        batchNumber: batchNumber,
        injectionSite: injectionSite,
      );
      // 重新加载以确保数据同步
      await loadRecords();
      return record;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<VaccinationRecord?> update(
    String id, {
    String? vaccineName,
    DateTime? scheduledDate,
    DateTime? actualDate,
    String? batchNumber,
    String? injectionSite,
    bool? isCompleted,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        vaccineName: vaccineName,
        scheduledDate: scheduledDate,
        actualDate: actualDate,
        batchNumber: batchNumber,
        injectionSite: injectionSite,
        isCompleted: isCompleted,
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

  Future<VaccinationRecord?> markAsCompleted(
    String id, {
    DateTime? actualDate,
    String? batchNumber,
    String? injectionSite,
  }) async {
    try {
      final updated = await _repository.markAsCompleted(
        id,
        actualDate: actualDate,
        batchNumber: batchNumber,
        injectionSite: injectionSite,
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

/// 疫苗接种记录 Notifier Provider
final vaccinationRecordNotifierProvider =
    StateNotifierProvider<
      VaccinationRecordNotifier,
      AsyncValue<List<VaccinationRecord>>
    >((ref) {
      final repository = ref.watch(vaccinationRecordRepositoryProvider);
      return VaccinationRecordNotifier(repository, ref);
    });
