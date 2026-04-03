import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_record.freezed.dart';
part 'medical_record.g.dart';

/// 病例记录实体
/// 对应 Web 版 MedicalRecord interface (types/index.ts)
@freezed
class MedicalRecord with _$MedicalRecord {
  const factory MedicalRecord({
    required String id,
    required String babyId,
    required DateTime visitDate,
    required String symptoms,
    required String diagnosis,
    required String hospital,
    required String doctor,
    required String medications,
    required String notes,
    required DateTime createdAt,
  }) = _MedicalRecord;

  factory MedicalRecord.fromJson(Map<String, dynamic> json) =>
      _$MedicalRecordFromJson(json);

  factory MedicalRecord.create({
    required String babyId,
    required DateTime visitDate,
    required String symptoms,
    required String diagnosis,
    required String hospital,
    required String doctor,
    required String medications,
    required String notes,
  }) {
    return MedicalRecord(
      id: '',
      babyId: babyId,
      visitDate: visitDate,
      symptoms: symptoms,
      diagnosis: diagnosis,
      hospital: hospital,
      doctor: doctor,
      medications: medications,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}
