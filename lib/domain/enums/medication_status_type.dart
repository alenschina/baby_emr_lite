/// 用药状态类型枚举
/// 对应 Web 版 status: 'taken' | 'missed' | 'skipped'
enum MedicationStatusType {
  taken,
  missed,
  skipped;

  String get label => switch (this) {
    MedicationStatusType.taken => '已服用',
    MedicationStatusType.missed => '漏服',
    MedicationStatusType.skipped => '跳过',
  };
}
