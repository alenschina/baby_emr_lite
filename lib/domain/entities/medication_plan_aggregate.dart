import 'package:freezed_annotation/freezed_annotation.dart';
import 'medication_plan.dart';
import 'medication_frequency.dart';
import 'medication_dose.dart';
import 'medication_time.dart';

part 'medication_plan_aggregate.freezed.dart';
part 'medication_plan_aggregate.g.dart';

@freezed
class MedicationPlanAggregate with _$MedicationPlanAggregate {
  const factory MedicationPlanAggregate({
    required MedicationPlan plan,
    required MedicationFrequency frequency,
    required MedicationDose dose,
    required List<MedicationTime> times,
  }) = _MedicationPlanAggregate;

  const MedicationPlanAggregate._();

  factory MedicationPlanAggregate.fromJson(Map<String, dynamic> json) =>
      _$MedicationPlanAggregateFromJson(json);
}

