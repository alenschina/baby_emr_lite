import 'package:uuid/uuid.dart';
import '../../domain/entities/medication_status.dart';
import '../../domain/enums/medication_status_type.dart';
import '../../domain/repositories/medication_status_repository.dart';
import '../datasources/hive_storage.dart';

/// 用药状态数据仓库实现
class MedicationStatusRepositoryImpl implements MedicationStatusRepository {
  final HiveStorage _storage;
  static const _recordsKey = 'medication_statuses';

  MedicationStatusRepositoryImpl(this._storage);

  List<MedicationStatus> _getAllFromStorage() {
    final data = _storage.getData(_recordsKey);
    if (data == null) return [];

    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<MedicationStatus> records) async {
    await _storage.saveData(_recordsKey, {
      'list': records.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<List<MedicationStatus>> getByMedicationId(String medicationId) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.medicationId == medicationId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<MedicationStatus?> getById(String id) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<MedicationStatus?> getByDate(
    String medicationId,
    DateTime date,
  ) async {
    final all = _getAllFromStorage();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return all
        .where(
          (r) =>
              r.medicationId == medicationId &&
              r.date.year == normalizedDate.year &&
              r.date.month == normalizedDate.month &&
              r.date.day == normalizedDate.day,
        )
        .firstOrNull;
  }

  @override
  Future<List<MedicationStatus>> getByDateRange(
    String medicationId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final all = await getByMedicationId(medicationId);
    return all
        .where(
          (r) =>
              r.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              r.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  @override
  Future<List<MedicationStatus>> getTodayPending(String medicationId) async {
    // 返回今日未记录的状态（返回空列表，因为需要结合medication记录来判断）
    return [];
  }

  @override
  Future<MedicationStatus> create({
    required String medicationId,
    required DateTime date,
    required MedicationStatusType status,
    String? notes,
    int? stockDelta,
  }) async {
    final record = MedicationStatus(
      id: const Uuid().v4(),
      medicationId: medicationId,
      date: DateTime(date.year, date.month, date.day),
      status: status,
      recordedAt: DateTime.now(),
      notes: notes,
      stockDelta: stockDelta,
    );

    final all = _getAllFromStorage();
    all.add(record);
    await _saveAll(all);

    return record;
  }

  @override
  Future<MedicationStatus> update(
    String id, {
    MedicationStatusType? status,
    String? notes,
    int? stockDelta,
  }) async {
    final all = _getAllFromStorage();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('MedicationStatus not found: $id');
    }

    final existing = all[index];
    final updated = existing.copyWith(
      status: status ?? existing.status,
      notes: notes ?? existing.notes,
      stockDelta: stockDelta ?? existing.stockDelta,
    );

    all[index] = updated;
    await _saveAll(all);

    return updated;
  }

  @override
  Future<void> delete(String id) async {
    final all = _getAllFromStorage();
    final filtered = all.where((r) => r.id != id).toList();
    await _saveAll(filtered);
  }

  @override
  Future<void> deleteByMedicationId(String medicationId) async {
    final all = _getAllFromStorage();
    final filtered = all.where((r) => r.medicationId != medicationId).toList();
    await _saveAll(filtered);
  }
}
