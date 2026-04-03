/// 应用常量定义
class AppConstants {
  // 存储键名
  static const String storageKey = 'baby_emr_data';
  static const String encryptionKeyStorageKey = 'baby_emr_encryption_key';
  static const String currentBabyIdKey = 'current_baby_id';

  // 备份文件
  static const int backupSchemaVersion = 1;
  static const String backupFilePrefix = 'baby_emr_backup';

  // 通知渠道
  static const String medicationChannelId = 'medication_channel';
  static const String medicationChannelName = '用药提醒';
  static const String medicationChannelDesc = '宝宝用药时间提醒';

  // 性别选项
  static const Map<String, String> genderLabels = {
    'male': '小王子',
    'female': '小公主',
  };

  // 用药状态
  static const Map<String, String> medicationStatusLabels = {
    'taken': '已服用',
    'missed': '漏服',
    'skipped': '跳过',
  };

  // 默认单位
  static const String defaultMedicationUnit = '片';

  // 日期格式
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String timeFormat = 'HH:mm';
}
