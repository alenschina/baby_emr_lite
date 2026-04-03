import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/gender.dart';

part 'baby.freezed.dart';
part 'baby.g.dart';

/// 宝宝实体
/// 对应 Web 版 Baby interface (types/index.ts)
@freezed
class Baby with _$Baby {
  const factory Baby({
    required String id,
    required String name,
    required Gender gender,
    required DateTime birthDate,
    String? avatarPath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Baby;

  factory Baby.fromJson(Map<String, dynamic> json) => _$BabyFromJson(json);

  /// 创建新宝宝（用于新增时）
  factory Baby.create({
    required String name,
    required Gender gender,
    required DateTime birthDate,
    String? avatarPath,
  }) {
    final now = DateTime.now();
    return Baby(
      id: '', // 由 Repository 生成 UUID
      name: name,
      gender: gender,
      birthDate: birthDate,
      avatarPath: avatarPath,
      createdAt: now,
      updatedAt: now,
    );
  }
}
