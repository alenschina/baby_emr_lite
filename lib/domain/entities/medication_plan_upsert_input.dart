import 'package:freezed_annotation/freezed_annotation.dart';
import '../entities/medication_frequency.dart';
import '../entities/medication_dose.dart';

part 'medication_plan_upsert_input.freezed.dart';
part 'medication_plan_upsert_input.g.dart';

@freezed
class MedicationPlanUpsertInput with _$MedicationPlanUpsertInput {
  const factory MedicationPlanUpsertInput({
    String? planId,
    required String babyId,
    required String medicationName,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
    required MedicationFrequency frequency,
    required MedicationDose dose,
    required List<String> times,
  }) = _MedicationPlanUpsertInput;

  const MedicationPlanUpsertInput._();

  factory MedicationPlanUpsertInput.fromJson(Map<String, dynamic> json) =>
      _$MedicationPlanUpsertInputFromJson(json);
}

