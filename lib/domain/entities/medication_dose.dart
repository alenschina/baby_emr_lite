import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_dose.freezed.dart';
part 'medication_dose.g.dart';

@freezed
class MedicationDose with _$MedicationDose {
  const factory MedicationDose({
    required String planId,
    required num amount,
    required String unit,
  }) = _MedicationDose;

  const MedicationDose._();

  factory MedicationDose.fromJson(Map<String, dynamic> json) =>
      _$MedicationDoseFromJson(json);
}

