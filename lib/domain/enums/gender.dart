/// 性别枚举
/// 对应 Web 版 gender: 'male' | 'female'
enum Gender {
  male,
  female;

  String get label => switch (this) {
    Gender.male => '小王子',
    Gender.female => '小公主',
  };

  String get shortLabel => switch (this) {
    Gender.male => '小王子',
    Gender.female => '小公主',
  };

  /// 默认头像路径
  String get defaultAvatarPath => switch (this) {
    Gender.male => 'assets/images/avatar_boy.jpg',
    Gender.female => 'assets/images/avatar_girl.jpg',
  };
}
