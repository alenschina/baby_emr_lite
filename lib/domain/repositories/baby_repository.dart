import '../entities/baby.dart';
import '../enums/gender.dart';

/// 宝宝数据仓库接口
abstract class BabyRepository {
  /// 获取所有宝宝
  Future<List<Baby>> getAll();

  /// 根据 ID 获取宝宝
  Future<Baby?> getById(String id);

  /// 创建宝宝
  Future<Baby> create({
    required String name,
    required Gender gender,
    required DateTime birthDate,
    String? avatarPath,
  });

  /// 更新宝宝
  Future<Baby> update(
    String id, {
    String? name,
    Gender? gender,
    DateTime? birthDate,
    String? avatarPath,
  });

  /// 删除宝宝
  Future<void> delete(String id);

  /// 设置当前选中的宝宝
  Future<void> setCurrentBaby(String? id);

  /// 获取当前选中的宝宝 ID
  String? get currentBabyId;

  /// 监听当前宝宝 ID 变化
  Stream<String?> watchCurrentBabyId();
}
