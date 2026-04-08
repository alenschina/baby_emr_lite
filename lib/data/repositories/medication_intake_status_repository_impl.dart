import 'package:uuid/uuid.dart';

import '../../domain/entities/medication_intake_status.dart';
import '../../domain/enums/medication_intake_status_type.dart';
import '../../domain/repositories/medication_intake_status_repository.dart';
import '../datasources/hive_storage.dart';

class MedicationIntakeStatusRepositoryImpl
    implements MedicationIntakeStatusRepository {
  final HiveStorage _storage;
  static const _key = 'medication_intake_statuses';

  MedicationIntakeStatusRepositoryImpl(this._storage);

  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String slotKey({
    required String planId,
    required DateTime scheduledDate,
    required String timeId,
  }) {
    final d = normalizeDate(scheduledDate);
    return '$planId|${d.toIso8601String()}|$timeId';
  }

  List<MedicationIntakeStatus> _getAll() {
    final data = _storage.getData(_key);
    if (data == null) return [];
    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationIntakeStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<MedicationIntakeStatus> statuses) async {
    await _storage.saveData(_key, {
      'list': statuses.map((e) => e.toJson()).toList(),
    });
  }

  /// 纯逻辑：在 list 中按槽位唯一键 upsert，用于测试与复用。
  static ({
    List<MedicationIntakeStatus> list,
    MedicationIntakeStatus record,
  }) upsertInList(
    List<MedicationIntakeStatus> existing, {
    required String planId,
    required DateTime scheduledDate,
    required String timeId,
    required MedicationIntakeStatusType status,
    required DateTime now,
    String? notes,
    num? stockDelta,
  }) {
    final key = slotKey(
      planId: planId,
      scheduledDate: scheduledDate,
      timeId: timeId,
    );

    final list = [...existing];
    final index = list.indexWhere((s) {
      return slotKey(planId: s.planId, scheduledDate: s.scheduledDate, timeId: s.timeId) ==
          key;
    });

    if (index == -1) {
      final record = MedicationIntakeStatus(
        id: const Uuid().v4(),
        planId: planId,
        scheduledDate: normalizeDate(scheduledDate),
        timeId: timeId,
        status: status,
        recordedAt: now,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
        stockDelta: stockDelta,
      );
      list.add(record);
      return (list: list, record: record);
    }

    final existingRecord = list[index];
    final updated = existingRecord.copyWith(
      status: status,
      recordedAt: now,
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      stockDelta: stockDelta,
      // scheduledDate/timeId/planId/id 保持不变
    );
    list[index] = updated;
    return (list: list, record: updated);
  }

  @override
  Future<List<MedicationIntakeStatus>> listByPlanId(String planId) async {
    final all = _getAll();
    final list = all.where((s) => s.planId == planId).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  @override
  Future<MedicationIntakeStatus> upsertForSlot({
    required String planId,
    required DateTime scheduledDate,
    required String timeId,
    required MedicationIntakeStatusType status,
    String? notes,
    num? stockDelta,
  }) async {
    final all = _getAll();
    final now = DateTime.now();

    final result = upsertInList(
      all,
      planId: planId,
      scheduledDate: scheduledDate,
      timeId: timeId,
      status: status,
      now: now,
      notes: notes,
      stockDelta: stockDelta,
    );

    await _saveAll(result.list);
    return result.record;
  }

  @override
  Future<void> deleteByPlanId(String planId) async {
    final all = _getAll();
    final filtered = all.where((s) => s.planId != planId).toList();
    await _saveAll(filtered);
  }
}

