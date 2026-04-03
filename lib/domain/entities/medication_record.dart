import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_record.freezed.dart';
part 'medication_record.g.dart';

/// 用药记录实体
/// 对应 Web 版 MedicationRecord interface (types/index.ts)
@freezed
class MedicationRecord with _$MedicationRecord {
  const factory MedicationRecord({
    required String id,
    required String babyId,
    required String name,
    required String dosage,
    required String frequency,
    String? scheduledTime,
    required DateTime startDate,
    DateTime? endDate,
    required int stockQuantity,
    required String unit,
    String? notes,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MedicationRecord;

  const MedicationRecord._();

  factory MedicationRecord.fromJson(Map<String, dynamic> json) =>
      _$MedicationRecordFromJson(json);

  factory MedicationRecord.create({
    required String babyId,
    required String name,
    required String dosage,
    required String frequency,
    String? scheduledTime,
    required DateTime startDate,
    DateTime? endDate,
    required int stockQuantity,
    required String unit,
    String? notes,
  }) {
    final now = DateTime.now();
    return MedicationRecord(
      id: '',
      babyId: babyId,
      name: name,
      dosage: dosage,
      frequency: frequency,
      scheduledTime: scheduledTime,
      startDate: startDate,
      endDate: endDate,
      stockQuantity: stockQuantity,
      unit: unit,
      notes: notes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}
