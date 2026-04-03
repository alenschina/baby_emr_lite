import '../entities/medication_record.dart';

/// 用药记录数据仓库接口
abstract class MedicationRecordRepository {
  /// 获取指定宝宝的所有用药记录
  Future<List<MedicationRecord>> getByBabyId(String babyId);

  /// 根据 ID 获取用药记录
  Future<MedicationRecord?> getById(String id);

  /// 获取正在进行的用药记录
  Future<List<MedicationRecord>> getActive(String babyId);

  /// 获取已结束的用药记录
  Future<List<MedicationRecord>> getInactive(String babyId);

  /// 创建用药记录
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
  });

  /// 更新用药记录
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
  });

  /// 更新库存
  Future<MedicationRecord> updateStock(String id, int newQuantity);

  /// 结束用药
  Future<MedicationRecord> endMedication(String id, DateTime endDate);

  /// 删除用药记录
  Future<void> delete(String id);

  /// 删除指定宝宝的所有用药记录
  Future<void> deleteByBabyId(String babyId);
}
