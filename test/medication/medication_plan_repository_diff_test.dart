import 'package:flutter_test/flutter_test.dart';

import 'package:baby_emr_lite/data/repositories/medication_plan_repository_impl.dart';
import 'package:baby_emr_lite/domain/entities/medication_time.dart';

void main() {
  group('MedicationPlanRepositoryImpl.diffTimes', () {
    test('adds new times and removes missing times', () {
      final existing = [
        MedicationTime(
          id: 't1',
          planId: 'p1',
          timeOfDay: '10:00',
          isEnabled: true,
          createdAt: DateTime(2026, 1, 1),
        ),
        MedicationTime(
          id: 't2',
          planId: 'p1',
          timeOfDay: '20:00',
          isEnabled: true,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final diff = MedicationPlanRepositoryImpl.diffTimes(
        existing: existing,
        desiredTimeOfDay: ['08:00', '20:00'],
      );

      expect(diff.toAdd, ['08:00']);
      expect(diff.toRemove.map((e) => e.id).toList(), ['t1']);
    });

    test('trims, drops empty, and de-duplicates desired times', () {
      final existing = <MedicationTime>[];
      final diff = MedicationPlanRepositoryImpl.diffTimes(
        existing: existing,
        desiredTimeOfDay: [' 09:00 ', '', '09:00', '21:00'],
      );

      expect(diff.toAdd, ['09:00', '21:00']);
      expect(diff.toRemove, isEmpty);
    });
  });
}

