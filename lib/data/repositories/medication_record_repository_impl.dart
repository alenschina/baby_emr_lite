import 'package:uuid/uuid.dart';
import '../../domain/entities/medication_record.dart';
import '../../domain/repositories/medication_record_repository.dart';
import '../datasources/hive_storage.dart';

/// 用药记录数据仓库实现
class MedicationRecordRepositoryImpl implements MedicationRecordRepository {
  final HiveStorage _storage;
  static const _recordsKey = 'medication_records';

  MedicationRecordRepositoryImpl(this._storage);

  List<MedicationRecord> _getAllFromStorage() {
    final data = _storage.getData(_recordsKey);
    if (data == null) return [];

    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<MedicationRecord> records) async {
    await _storage.saveData(_recordsKey, {
      'list': records.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<List<MedicationRecord>> getByBabyId(String babyId) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.babyId == babyId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<MedicationRecord?> getById(String id) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<List<MedicationRecord>> getActive(String babyId) async {
    final all = await getByBabyId(babyId);
    return all.where((r) => r.isActive).toList();
  }

  @override
  Future<List<MedicationRecord>> getInactive(String babyId) async {
    final all = await getByBabyId(babyId);
    return all.where((r) => !r.isActive).toList();
  }

  @override
  Future<MedicationRecord> create({
    required String babyId,
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
    final now = DateTime.now();
    final record = MedicationRecord(
      id: const Uuid().v4(),
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
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final all = _getAllFromStorage();
    all.add(record);
    await _saveAll(all);

    return record;
  }

  @override
  Future<MedicationRecord> update(
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
    final all = _getAllFromStorage();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('MedicationRecord not found: $id');
    }

    final existing = all[index];
    final updated = existing.copyWith(
      name: name ?? existing.name,
      dosage: dosage ?? existing.dosage,
      frequency: frequency ?? existing.frequency,
      scheduledTime: scheduledTime ?? existing.scheduledTime,
      startDate: startDate ?? existing.startDate,
      endDate: endDate ?? existing.endDate,
      stockQuantity: stockQuantity ?? existing.stockQuantity,
      unit: unit ?? existing.unit,
      notes: notes ?? existing.notes,
      isActive: isActive ?? existing.isActive,
      updatedAt: DateTime.now(),
    );

    all[index] = updated;
    await _saveAll(all);

    return updated;
  }

  @override
  Future<MedicationRecord> updateStock(String id, int newQuantity) async {
    return update(id, stockQuantity: newQuantity);
  }

  @override
  Future<MedicationRecord> endMedication(String id, DateTime endDate) async {
    return update(id, endDate: endDate, isActive: false);
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
