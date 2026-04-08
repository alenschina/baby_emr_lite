/// 用药频率类型
enum MedicationFrequencyType {
  /// 未设置频率
  none,

  /// 每天
  daily,

  /// 每几天
  everyNDays,

  /// 每几周
  everyNWeeks;

  String get label => switch (this) {
    MedicationFrequencyType.none => '未设置',
    MedicationFrequencyType.daily => '每天',
    MedicationFrequencyType.everyNDays => '每几天',
    MedicationFrequencyType.everyNWeeks => '每几周',
  };
}

