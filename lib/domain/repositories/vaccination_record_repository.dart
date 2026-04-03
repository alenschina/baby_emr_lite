import '../entities/vaccination_record.dart';

/// 疫苗接种记录数据仓库接口
abstract class VaccinationRecordRepository {
  /// 获取指定宝宝的所有疫苗接种记录
  Future<List<VaccinationRecord>> getByBabyId(String babyId);

  /// 根据 ID 获取疫苗接种记录
  Future<VaccinationRecord?> getById(String id);

  /// 获取待接种的疫苗列表
  Future<List<VaccinationRecord>> getPending(String babyId);

  /// 获取已完成的疫苗列表
  Future<List<VaccinationRecord>> getCompleted(String babyId);

  /// 创建疫苗接种记录
  Future<VaccinationRecord> create({
    required String babyId,
    required String vaccineName,
    required DateTime scheduledDate,
    String? batchNumber,
    String? injectionSite,
  });

  /// 更新疫苗接种记录
  Future<VaccinationRecord> update(
    String id, {
    String? vaccineName,
    DateTime? scheduledDate,
    DateTime? actualDate,
    String? batchNumber,
    String? injectionSite,
    bool? isCompleted,
  });

  /// 标记疫苗为已完成
  Future<VaccinationRecord> markAsCompleted(
    String id, {
    DateTime? actualDate,
    String? batchNumber,
    String? injectionSite,
  });

  /// 删除疫苗接种记录
  Future<void> delete(String id);

  /// 删除指定宝宝的所有疫苗接种记录
  Future<void> deleteByBabyId(String babyId);
}
