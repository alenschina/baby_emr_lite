/// 病例记录过滤器模型
class MedicalRecordFilter {
  /// 年份区间开始（包含）
  final int? startYear;

  /// 年份区间结束（包含）
  final int? endYear;

  /// 医疗机构筛选
  final String? hospital;

  /// 疾病类型筛选（从诊断中提取关键词）
  final String? diagnosisKeyword;

  /// 药品名称筛选
  final String? medicationKeyword;

  const MedicalRecordFilter({
    this.startYear,
    this.endYear,
    this.hospital,
    this.diagnosisKeyword,
    this.medicationKeyword,
  });

  /// 是否有激活的过滤条件
  bool get isActive =>
      startYear != null ||
      endYear != null ||
      hospital != null &&
          hospital!.isNotEmpty ||
      diagnosisKeyword != null &&
          diagnosisKeyword!.isNotEmpty ||
      medicationKeyword != null &&
          medicationKeyword!.isNotEmpty;

  /// 创建过滤器副本
  MedicalRecordFilter copyWith({
    int? startYear,
    int? endYear,
    String? hospital,
    String? diagnosisKeyword,
    String? medicationKeyword,
  }) {
    return MedicalRecordFilter(
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      hospital: hospital ?? this.hospital,
      diagnosisKeyword: diagnosisKeyword ?? this.diagnosisKeyword,
      medicationKeyword: medicationKeyword ?? this.medicationKeyword,
    );
  }

  /// 清空所有过滤条件
  MedicalRecordFilter clear() {
    return const MedicalRecordFilter();
  }

  /// 获取可用的医疗机构列表
  static List<String> getAvailableHospitals(List<dynamic> records) {
    final hospitals = <String>{};
    for (final record in records) {
      if (record.hospital != null && record.hospital.isNotEmpty) {
        hospitals.add(record.hospital);
      }
    }
    return hospitals.toList()..sort();
  }

  /// 获取可用的年份列表
  static List<int> getAvailableYears(List<dynamic> records) {
    final years = <int>{};
    for (final record in records) {
      if (record.visitDate != null) {
        years.add(record.visitDate.year);
      }
    }
    final sortedYears = years.toList()..sort();
    return sortedYears.isEmpty ? [DateTime.now().year] : sortedYears;
  }
}
