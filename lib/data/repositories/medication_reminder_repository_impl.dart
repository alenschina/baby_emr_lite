import 'package:uuid/uuid.dart';
import '../../domain/entities/medication_reminder.dart';
import '../../domain/repositories/medication_reminder_repository.dart';
import '../datasources/hive_storage.dart';

/// 用药提醒数据仓库实现
class MedicationReminderRepositoryImpl implements MedicationReminderRepository {
  final HiveStorage _storage;
  static const _recordsKey = 'medication_reminders';

  MedicationReminderRepositoryImpl(this._storage);

  List<MedicationReminder> _getAllFromStorage() {
    final data = _storage.getData(_recordsKey);
    if (data == null) return [];

    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationReminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<MedicationReminder> records) async {
    await _storage.saveData(_recordsKey, {
      'list': records.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<List<MedicationReminder>> getByMedicationId(
    String medicationId,
  ) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.medicationId == medicationId).toList();
  }

  @override
  Future<MedicationReminder?> getById(String id) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<List<MedicationReminder>> getAllEnabled() async {
    final all = _getAllFromStorage();
    return all.where((r) => r.isEnabled).toList();
  }

  @override
  Future<MedicationReminder> create({
    required String medicationId,
    required String reminderTime,
  }) async {
    final record = MedicationReminder(
      id: const Uuid().v4(),
      medicationId: medicationId,
      reminderTime: reminderTime,
      isEnabled: true,
      createdAt: DateTime.now(),
    );

    final all = _getAllFromStorage();
    all.add(record);
    await _saveAll(all);

    return record;
  }

  @override
  Future<MedicationReminder> update(
    String id, {
    String? reminderTime,
    bool? isEnabled,
  }) async {
    final all = _getAllFromStorage();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('MedicationReminder not found: $id');
    }

    final existing = all[index];
    final updated = existing.copyWith(
      reminderTime: reminderTime ?? existing.reminderTime,
      isEnabled: isEnabled ?? existing.isEnabled,
    );

    all[index] = updated;
    await _saveAll(all);

    return updated;
  }

  @override
  Future<MedicationReminder> toggleEnabled(String id) async {
    final all = _getAllFromStorage();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('MedicationReminder not found: $id');
    }

    final existing = all[index];
    return update(id, isEnabled: !existing.isEnabled);
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
