/// 用药打卡状态（按时间点）
enum MedicationIntakeStatusType {
  taken,
  missed,
  skipped;

  String get label => switch (this) {
    MedicationIntakeStatusType.taken => '已服用',
    MedicationIntakeStatusType.missed => '漏服',
    MedicationIntakeStatusType.skipped => '跳过',
  };
}

