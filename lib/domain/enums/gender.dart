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
    Gender.male => '王子',
    Gender.female => '公主',
  };
}
