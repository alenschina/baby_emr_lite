import '../entities/medication_status.dart';
import '../enums/medication_status_type.dart';

/// 用药状态数据仓库接口
abstract class MedicationStatusRepository {
  /// 获取指定用药记录的所有状态记录
  Future<List<MedicationStatus>> getByMedicationId(String medicationId);

  /// 根据 ID 获取状态记录
  Future<MedicationStatus?> getById(String id);

  /// 获取指定日期的状态记录
  Future<MedicationStatus?> getByDate(String medicationId, DateTime date);

  /// 获取指定日期范围内所有状态记录
  Future<List<MedicationStatus>> getByDateRange(
    String medicationId,
    DateTime startDate,
    DateTime endDate,
  );

  /// 获取今日待记录的状态
  Future<List<MedicationStatus>> getTodayPending(String medicationId);

  /// 创建状态记录
  Future<MedicationStatus> create({
    required String medicationId,
    required DateTime date,
    required MedicationStatusType status,
    String? notes,
    int? stockDelta,
  });

  /// 更新状态记录
  Future<MedicationStatus> update(
    String id, {
    MedicationStatusType? status,
    String? notes,
    int? stockDelta,
  });

  /// 删除状态记录
  Future<void> delete(String id);

  /// 删除指定用药记录的所有状态记录
  Future<void> deleteByMedicationId(String medicationId);
}
