import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/medication_intake_status_type.dart';

part 'medication_intake_status.freezed.dart';
part 'medication_intake_status.g.dart';

@freezed
class MedicationIntakeStatus with _$MedicationIntakeStatus {
  const factory MedicationIntakeStatus({
    required String id,
    required String planId,
    required DateTime scheduledDate,
    required String timeId,
    required MedicationIntakeStatusType status,
    required DateTime recordedAt,
    String? notes,
    num? stockDelta,
  }) = _MedicationIntakeStatus;

  const MedicationIntakeStatus._();

  factory MedicationIntakeStatus.fromJson(Map<String, dynamic> json) =>
      _$MedicationIntakeStatusFromJson(json);

  factory MedicationIntakeStatus.create({
    required String planId,
    required DateTime scheduledDate,
    required String timeId,
    required MedicationIntakeStatusType status,
    String? notes,
    num? stockDelta,
  }) {
    return MedicationIntakeStatus(
      id: '',
      planId: planId,
      scheduledDate: scheduledDate,
      timeId: timeId,
      status: status,
      recordedAt: DateTime.now(),
      notes: notes,
      stockDelta: stockDelta,
    );
  }
}

