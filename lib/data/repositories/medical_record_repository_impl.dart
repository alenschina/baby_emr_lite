import 'package:uuid/uuid.dart';
import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../datasources/hive_storage.dart';

/// 病例记录数据仓库实现
class MedicalRecordRepositoryImpl implements MedicalRecordRepository {
  final HiveStorage _storage;
  static const _recordsKey = 'medical_records';

  MedicalRecordRepositoryImpl(this._storage);

  List<MedicalRecord> _getAllFromStorage() {
    final data = _storage.getData(_recordsKey);
    if (data == null) return [];

    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicalRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<MedicalRecord> records) async {
    await _storage.saveData(_recordsKey, {
      'list': records.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<List<MedicalRecord>> getByBabyId(String babyId) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.babyId == babyId).toList()
      ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
  }

  @override
  Future<MedicalRecord?> getById(String id) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<MedicalRecord> create({
    required String babyId,
    required DateTime visitDate,
    required String symptoms,
    required String diagnosis,
    required String hospital,
    required String doctor,
    required String medications,
    required String notes,
  }) async {
    final now = DateTime.now();
    final record = MedicalRecord(
      id: const Uuid().v4(),
      babyId: babyId,
      visitDate: visitDate,
      symptoms: symptoms,
      diagnosis: diagnosis,
      hospital: hospital,
      doctor: doctor,
      medications: medications,
      notes: notes,
      createdAt: now,
    );

    final all = _getAllFromStorage();
    all.add(record);
    await _saveAll(all);

    return record;
  }

  @override
  Future<MedicalRecord> update(
    String id, {
    DateTime? visitDate,
    String? symptoms,
    String? diagnosis,
    String? hospital,
    String? doctor,
    String? medications,
    String? notes,
  }) async {
    final all = _getAllFromStorage();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('MedicalRecord not found: $id');
    }

    final existing = all[index];
    final updated = existing.copyWith(
      visitDate: visitDate ?? existing.visitDate,
      symptoms: symptoms ?? existing.symptoms,
      diagnosis: diagnosis ?? existing.diagnosis,
      hospital: hospital ?? existing.hospital,
      doctor: doctor ?? existing.doctor,
      medications: medications ?? existing.medications,
      notes: notes ?? existing.notes,
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
  Future<void> deleteByBabyId(String babyId) async {
    final all = _getAllFromStorage();
    final filtered = all.where((r) => r.babyId != babyId).toList();
    await _saveAll(filtered);
  }
}
