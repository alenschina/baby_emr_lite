import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_time.freezed.dart';
part 'medication_time.g.dart';

@freezed
class MedicationTime with _$MedicationTime {
  const factory MedicationTime({
    required String id,
    required String planId,
    required String timeOfDay,
    required bool isEnabled,
    required DateTime createdAt,
  }) = _MedicationTime;

  const MedicationTime._();

  factory MedicationTime.fromJson(Map<String, dynamic> json) =>
      _$MedicationTimeFromJson(json);

  factory MedicationTime.create({
    required String planId,
    required String timeOfDay,
  }) {
    return MedicationTime(
      id: '',
      planId: planId,
      timeOfDay: timeOfDay,
      isEnabled: true,
      createdAt: DateTime.now(),
    );
  }
}

