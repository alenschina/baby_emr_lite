import 'package:flutter_test/flutter_test.dart';

import 'package:baby_emr_lite/data/repositories/medication_intake_status_repository_impl.dart';
import 'package:baby_emr_lite/domain/entities/medication_intake_status.dart';
import 'package:baby_emr_lite/domain/enums/medication_intake_status_type.dart';

void main() {
  group('MedicationIntakeStatusRepositoryImpl.upsertInList', () {
    test('creates new record when slot not exists', () {
      final now = DateTime(2026, 4, 7, 12, 0);
      final result = MedicationIntakeStatusRepositoryImpl.upsertInList(
        const [],
        planId: 'p1',
        scheduledDate: DateTime(2026, 4, 7, 18, 30),
        timeId: 't1',
        status: MedicationIntakeStatusType.taken,
        now: now,
        notes: ' ok ',
        stockDelta: -1,
      );

      expect(result.list, hasLength(1));
      expect(result.record.planId, 'p1');
      expect(result.record.timeId, 't1');
      expect(result.record.scheduledDate, DateTime(2026, 4, 7)); // normalized
      expect(result.record.status, MedicationIntakeStatusType.taken);
      expect(result.record.notes, 'ok');
      expect(result.record.stockDelta, -1);
      expect(result.record.recordedAt, now);
    });

    test('updates existing record for same slot key', () {
      final existing = MedicationIntakeStatus(
        id: 's1',
        planId: 'p1',
        scheduledDate: DateTime(2026, 4, 7),
        timeId: 't1',
        status: MedicationIntakeStatusType.missed,
        recordedAt: DateTime(2026, 4, 7, 10, 0),
      );

      final now = DateTime(2026, 4, 7, 20, 0);
      final result = MedicationIntakeStatusRepositoryImpl.upsertInList(
        [existing],
        planId: 'p1',
        scheduledDate: DateTime(2026, 4, 7, 23, 59),
        timeId: 't1',
        status: MedicationIntakeStatusType.taken,
        now: now,
        notes: null,
        stockDelta: -0.5,
      );

      expect(result.list, hasLength(1));
      expect(result.record.id, 's1'); // keep id
      expect(result.record.status, MedicationIntakeStatusType.taken);
      expect(result.record.recordedAt, now);
      expect(result.record.stockDelta, -0.5);
    });
  });
}

