import '../entities/medical_record.dart';

/// 病例记录数据仓库接口
abstract class MedicalRecordRepository {
  /// 获取指定宝宝的所有病例记录
  Future<List<MedicalRecord>> getByBabyId(String babyId);

  /// 根据 ID 获取病例记录
  Future<MedicalRecord?> getById(String id);

  /// 创建病例记录
  Future<MedicalRecord> create({
    required String babyId,
    required DateTime visitDate,
    required String symptoms,
    required String diagnosis,
    required String hospital,
    required String doctor,
    required String medications,
    required String notes,
  });

  /// 更新病例记录
  Future<MedicalRecord> update(
    String id, {
    DateTime? visitDate,
    String? symptoms,
    String? diagnosis,
    String? hospital,
    String? doctor,
    String? medications,
    String? notes,
  });

  /// 删除病例记录
  Future<void> delete(String id);

  /// 删除指定宝宝的所有病例记录
  Future<void> deleteByBabyId(String babyId);
}
