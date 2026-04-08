import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/medication_frequency_type.dart';

part 'medication_frequency.freezed.dart';
part 'medication_frequency.g.dart';

@freezed
class MedicationFrequency with _$MedicationFrequency {
  const factory MedicationFrequency({
    required String planId,
    required MedicationFrequencyType type,
    int? interval,
  }) = _MedicationFrequency;

  const MedicationFrequency._();

  factory MedicationFrequency.fromJson(Map<String, dynamic> json) =>
      _$MedicationFrequencyFromJson(json);

  factory MedicationFrequency.none({required String planId}) =>
      MedicationFrequency(planId: planId, type: MedicationFrequencyType.none);
}

