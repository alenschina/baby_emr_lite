import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_reminder.freezed.dart';
part 'medication_reminder.g.dart';

/// 用药提醒实体
/// 对应 Web 版 MedicationReminder interface (types/index.ts)
@freezed
class MedicationReminder with _$MedicationReminder {
  const factory MedicationReminder({
    required String id,
    required String medicationId,
    required String reminderTime,
    required bool isEnabled,
    required DateTime createdAt,
  }) = _MedicationReminder;

  factory MedicationReminder.fromJson(Map<String, dynamic> json) =>
      _$MedicationReminderFromJson(json);

  factory MedicationReminder.create({
    required String medicationId,
    required String reminderTime,
  }) {
    return MedicationReminder(
      id: '',
      medicationId: medicationId,
      reminderTime: reminderTime,
      isEnabled: true,
      createdAt: DateTime.now(),
    );
  }
}
