import 'package:uuid/uuid.dart';
import '../../domain/entities/growth_data.dart';
import '../../domain/repositories/growth_data_repository.dart';
import '../datasources/hive_storage.dart';

/// 生长发育数据仓库实现
class GrowthDataRepositoryImpl implements GrowthDataRepository {
  final HiveStorage _storage;
  static const _recordsKey = 'growth_data';

  GrowthDataRepositoryImpl(this._storage);

  List<GrowthData> _getAllFromStorage() {
    final data = _storage.getData(_recordsKey);
    if (data == null) return [];

    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => GrowthData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<GrowthData> records) async {
    await _storage.saveData(_recordsKey, {
      'list': records.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<List<GrowthData>> getByBabyId(String babyId) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.babyId == babyId).toList()
      ..sort((a, b) => b.measurementDate.compareTo(a.measurementDate));
  }

  @override
  Future<GrowthData?> getById(String id) async {
    final all = _getAllFromStorage();
    return all.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<GrowthData?> getLatest(String babyId) async {
    final records = await getByBabyId(babyId);
    return records.firstOrNull;
  }

  @override
  Future<List<GrowthData>> getByDateRange(
    String babyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final all = await getByBabyId(babyId);
    return all
        .where(
          (r) =>
              r.measurementDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              r.measurementDate.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  @override
  Future<GrowthData> create({
    required String babyId,
    required DateTime measurementDate,
    required double height,
    required double weight,
    String? notes,
  }) async {
    final now = DateTime.now();
    final record = GrowthData(
      id: const Uuid().v4(),
      babyId: babyId,
      measurementDate: measurementDate,
      height: height,
      weight: weight,
      notes: notes,
      createdAt: now,
    );

    final all = _getAllFromStorage();
    all.add(record);
    await _saveAll(all);

    return record;
  }

  @override
  Future<GrowthData> update(
    String id, {
    DateTime? measurementDate,
    double? height,
    double? weight,
    String? notes,
  }) async {
    final all = _getAllFromStorage();
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('GrowthData not found: $id');
    }

    final existing = all[index];
    final updated = existing.copyWith(
      measurementDate: measurementDate ?? existing.measurementDate,
      height: height ?? existing.height,
      weight: weight ?? existing.weight,
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
