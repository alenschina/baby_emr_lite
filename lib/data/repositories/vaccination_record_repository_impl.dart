import 'package:uuid/uuid.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/repositories/vaccination_record_repository.dart';
import '../datasources/hive_storage.dart';

/// 疫苗接种记录数据仓库实现
class VaccinationRecordRepositoryImpl implements VaccinationRecordRepository {
  final HiveStorage _storage;
  static const _recordsKey = 'vaccination_records';

  VaccinationRecordRepositoryImpl(this._storage);

  List<VaccinationRecord> _getAllFromStorage() {
    final data = _storage.getData(_recordsKey);
    if (data == null) return [];

    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => VaccinationRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<VaccinationRecord> records) async {
    await _storage.saveData(_recordsKey, {
      'list': records.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<List<VaccinationRecord>> getByBabyId(String babyId) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.babyId == babyId).toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  }

  @override
  Future<VaccinationRecord?> getById(String id) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<List<VaccinationRecord>> getPending(String babyId) async {
    final all = await getByBabyId(babyId);
    return all.where((r) => !r.isCompleted).toList();
  }

  @override
  Future<List<VaccinationRecord>> getCompleted(String babyId) async {
    final all = await getByBabyId(babyId);
    return all.where((r) => r.isCompleted).toList();
  }

  @override
  Future<VaccinationRecord> create({
    required String babyId,
    required String vaccineName,
    required DateTime scheduledDate,
    String? batchNumber,
    String? injectionSite,
  }) async {
    final now = DateTime.now();
    final record = VaccinationRecord(
      id: const Uuid().v4(),
      babyId: babyId,
      vaccineName: vaccineName,
      scheduledDate: scheduledDate,
      batchNumber: batchNumber,
      injectionSite: injectionSite,
      isCompleted: false,
      createdAt: now,
    );

    final all = _getAllFromStorage();
    all.add(record);
    await _saveAll(all);

    return record;
  }

  @override
  Future<VaccinationRecord> update(
    String id, {
    String? vaccineName,
    DateTime? scheduledDate,
    DateTime? actualDate,
    String? batchNumber,
    String? injectionSite,
    bool? isCompleted,
  }) async {
    final all = _getAllFromStorage();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('VaccinationRecord not found: $id');
    }

    final existing = all[index];
    final nextIsCompleted = isCompleted ?? existing.isCompleted;
    final updated = existing.copyWith(
      vaccineName: vaccineName ?? existing.vaccineName,
      scheduledDate: scheduledDate ?? existing.scheduledDate,
      actualDate: nextIsCompleted ? (actualDate ?? existing.actualDate) : null,
      batchNumber: batchNumber ?? existing.batchNumber,
      injectionSite: injectionSite ?? existing.injectionSite,
      isCompleted: nextIsCompleted,
    );

    all[index] = updated;
    await _saveAll(all);

    return updated;
  }

  @override
  Future<VaccinationRecord> markAsCompleted(
    String id, {
    DateTime? actualDate,
    String? batchNumber,
    String? injectionSite,
  }) async {
    return update(
      id,
      actualDate: actualDate ?? DateTime.now(),
      batchNumber: batchNumber,
      injectionSite: injectionSite,
      isCompleted: true,
    );
  }

  @override
  Future<void> delete(String id) async {
    final all = _getAllFromStorage();
    final filtered = all.where((r) => r.id != id).toList();
    await _saveAll(filtered);
  }

  @override
  Future<void> deleteByBabyId(String babyId) async {
    final all = _getAllFromStorage();
    final filtered = all.where((r) => r.babyId != babyId).toList();
    await _saveAll(filtered);
  }
}
