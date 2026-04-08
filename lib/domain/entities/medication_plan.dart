import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_plan.freezed.dart';
part 'medication_plan.g.dart';

@freezed
class MedicationPlan with _$MedicationPlan {
  const factory MedicationPlan({
    required String id,
    required String babyId,
    required String medicationName,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MedicationPlan;

  const MedicationPlan._();

  factory MedicationPlan.fromJson(Map<String, dynamic> json) =>
      _$MedicationPlanFromJson(json);

  factory MedicationPlan.create({
    required String babyId,
    required String medicationName,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  }) {
    final now = DateTime.now();
    return MedicationPlan(
      id: '',
      babyId: babyId,
      medicationName: medicationName,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }
}

