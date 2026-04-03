import 'package:freezed_annotation/freezed_annotation.dart';

part 'growth_data.freezed.dart';
part 'growth_data.g.dart';

/// 生长发育数据实体
/// 对应 Web 版 GrowthData interface (types/index.ts)
@freezed
class GrowthData with _$GrowthData {
  const factory GrowthData({
    required String id,
    required String babyId,
    required DateTime measurementDate,
    required double height,
    required double weight,
    String? notes,
    required DateTime createdAt,
  }) = _GrowthData;

  factory GrowthData.fromJson(Map<String, dynamic> json) =>
      _$GrowthDataFromJson(json);

  factory GrowthData.create({
    required String babyId,
    required DateTime measurementDate,
    required double height,
    required double weight,
    String? notes,
  }) {
    return GrowthData(
      id: '',
      babyId: babyId,
      measurementDate: measurementDate,
      height: height,
      weight: weight,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}
