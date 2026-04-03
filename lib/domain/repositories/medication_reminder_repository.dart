import '../entities/medication_reminder.dart';

/// 用药提醒数据仓库接口
abstract class MedicationReminderRepository {
  /// 获取指定用药记录的所有提醒
  Future<List<MedicationReminder>> getByMedicationId(String medicationId);

  /// 根据 ID 获取提醒
  Future<MedicationReminder?> getById(String id);

  /// 获取所有已启用的提醒
  Future<List<MedicationReminder>> getAllEnabled();

  /// 创建提醒
  Future<MedicationReminder> create({
    required String medicationId,
    required String reminderTime,
  });

  /// 更新提醒
  Future<MedicationReminder> update(
    String id, {
    String? reminderTime,
    bool? isEnabled,
  });

  /// 切换提醒启用状态
  Future<MedicationReminder> toggleEnabled(String id);

  /// 删除提醒
  Future<void> delete(String id);

  /// 删除指定用药记录的所有提醒
  Future<void> deleteByMedicationId(String medicationId);
}
