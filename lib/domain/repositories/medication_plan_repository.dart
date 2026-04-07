import '../entities/medication_plan_aggregate.dart';
import '../entities/medication_plan_upsert_input.dart';

abstract class MedicationPlanRepository {
  Future<MedicationPlanAggregate> upsertWithDetails(
    MedicationPlanUpsertInput input,
  );

  Future<MedicationPlanAggregate?> getAggregateById(String planId);

  Future<List<MedicationPlanAggregate>> listAggregatesByBabyId(String babyId);

  Future<void> deletePlan(String planId);
}

