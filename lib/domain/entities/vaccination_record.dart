import 'package:freezed_annotation/freezed_annotation.dart';

part 'vaccination_record.freezed.dart';
part 'vaccination_record.g.dart';

/// 疫苗接种记录实体
/// 对应 Web 版 VaccinationRecord interface (types/index.ts)
@freezed
class VaccinationRecord with _$VaccinationRecord {
  const factory VaccinationRecord({
    required String id,
    required String babyId,
    required String vaccineName,
    required DateTime scheduledDate,
    DateTime? actualDate,
    String? batchNumber,
    String? injectionSite,
    required bool isCompleted,
    required DateTime createdAt,
  }) = _VaccinationRecord;

  factory VaccinationRecord.fromJson(Map<String, dynamic> json) =>
      _$VaccinationRecordFromJson(json);

  factory VaccinationRecord.create({
    required String babyId,
    required String vaccineName,
    required DateTime scheduledDate,
    String? batchNumber,
    String? injectionSite,
  }) {
    return VaccinationRecord(
      id: '',
      babyId: babyId,
      vaccineName: vaccineName,
      scheduledDate: scheduledDate,
      batchNumber: batchNumber,
      injectionSite: injectionSite,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }
}
