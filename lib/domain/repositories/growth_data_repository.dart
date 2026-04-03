import '../entities/growth_data.dart';

/// 生长发育数据仓库接口
abstract class GrowthDataRepository {
  /// 获取指定宝宝的所有生长数据
  Future<List<GrowthData>> getByBabyId(String babyId);

  /// 根据 ID 获取生长数据
  Future<GrowthData?> getById(String id);

  /// 获取最新的生长数据
  Future<GrowthData?> getLatest(String babyId);

  /// 获取指定日期范围内的生长数据
  Future<List<GrowthData>> getByDateRange(
    String babyId,
    DateTime startDate,
    DateTime endDate,
  );

  /// 创建生长数据
  Future<GrowthData> create({
    required String babyId,
    required DateTime measurementDate,
    required double height,
    required double weight,
    String? notes,
  });

  /// 更新生长数据
  Future<GrowthData> update(
    String id, {
    DateTime? measurementDate,
    double? height,
    double? weight,
    String? notes,
  });

  /// 删除生长数据
  Future<void> delete(String id);

  /// 删除指定宝宝的所有生长数据
  Future<void> deleteByBabyId(String babyId);
}
