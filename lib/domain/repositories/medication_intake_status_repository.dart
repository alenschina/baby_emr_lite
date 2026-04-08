import '../entities/medication_intake_status.dart';
import '../enums/medication_intake_status_type.dart';

abstract class MedicationIntakeStatusRepository {
  Future<List<MedicationIntakeStatus>> listByPlanId(String planId);

  Future<MedicationIntakeStatus> upsertForSlot({
    required String planId,
    required DateTime scheduledDate,
    required String timeId,
    required MedicationIntakeStatusType status,
    String? notes,
    num? stockDelta,
  });

  Future<void> deleteByPlanId(String planId);
}

