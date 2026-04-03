import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/medication_status_type.dart';

part 'medication_status.freezed.dart';
part 'medication_status.g.dart';

/// 用药状态实体
/// 对应 Web 版 MedicationStatus interface (types/index.ts)
@freezed
class MedicationStatus with _$MedicationStatus {
  const factory MedicationStatus({
    required String id,
    required String medicationId,
    required DateTime date,
    required MedicationStatusType status,
    required DateTime recordedAt,
    String? notes,
    int? stockDelta,
  }) = _MedicationStatus;

  factory MedicationStatus.fromJson(Map<String, dynamic> json) =>
      _$MedicationStatusFromJson(json);

  factory MedicationStatus.create({
    required String medicationId,
    required DateTime date,
    required MedicationStatusType status,
    String? notes,
    int? stockDelta,
  }) {
    return MedicationStatus(
      id: '',
      medicationId: medicationId,
      date: date,
      status: status,
      recordedAt: DateTime.now(),
      notes: notes,
      stockDelta: stockDelta,
    );
  }
}
