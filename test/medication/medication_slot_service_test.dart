import 'package:flutter_test/flutter_test.dart';

import 'package:baby_emr_lite/domain/entities/medication_dose.dart';
import 'package:baby_emr_lite/domain/entities/medication_frequency.dart';
import 'package:baby_emr_lite/domain/entities/medication_intake_status.dart';
import 'package:baby_emr_lite/domain/entities/medication_plan.dart';
import 'package:baby_emr_lite/domain/entities/medication_plan_aggregate.dart';
import 'package:baby_emr_lite/domain/entities/medication_time.dart';
import 'package:baby_emr_lite/domain/enums/medication_frequency_type.dart';
import 'package:baby_emr_lite/domain/enums/medication_intake_status_type.dart';
import 'package:baby_emr_lite/domain/services/medication_slot_service.dart';

void main() {
  group('MedicationSlotService', () {
    const service = MedicationSlotService();

    test('daily + 2 times + 3 days -> 6 slots', () {
      final agg = MedicationPlanAggregate(
        plan: MedicationPlan(
          id: 'p1',
          babyId: 'b1',
          medicationName: 'X',
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 3),
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
        frequency: const MedicationFrequency(
          planId: 'p1',
          type: MedicationFrequencyType.daily,
        ),
        dose: const MedicationDose(planId: 'p1', amount: 1, unit: '片'),
        times: [
          MedicationTime(
            id: 't1',
            planId: 'p1',
            timeOfDay: '10:00',
            isEnabled: true,
            createdAt: DateTime(2026, 4, 1),
          ),
          MedicationTime(
            id: 't2',
            planId: 'p1',
            timeOfDay: '20:00',
            isEnabled: true,
            createdAt: DateTime(2026, 4, 1),
          ),
        ],
      );

      final slots = service.computeSlots(agg: agg, today: DateTime(2026, 4, 7));
      expect(slots, hasLength(6));
      expect(slots.first.scheduledDate, DateTime(2026, 4, 1));
      expect(slots.last.scheduledDate, DateTime(2026, 4, 3));
    });

    test('everyNDays interval=2 steps correctly', () {
      final dates = service.computeOccurrenceDates(
        start: DateTime(2026, 4, 1),
        endInclusive: DateTime(2026, 4, 7),
        type: MedicationFrequencyType.everyNDays,
        interval: 2,
      );
      expect(
        dates,
        [
          DateTime(2026, 4, 1),
          DateTime(2026, 4, 3),
          DateTime(2026, 4, 5),
          DateTime(2026, 4, 7),
        ],
      );
    });

    test('none frequency generates 0 slots', () {
      final agg = MedicationPlanAggregate(
        plan: MedicationPlan(
          id: 'p1',
          babyId: 'b1',
          medicationName: 'X',
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 3),
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
        frequency: const MedicationFrequency(
          planId: 'p1',
          type: MedicationFrequencyType.none,
        ),
        dose: const MedicationDose(planId: 'p1', amount: 1, unit: '片'),
        times: const [],
      );

      final slots = service.computeSlots(agg: agg, today: DateTime(2026, 4, 7));
      expect(slots, isEmpty);
    });

    test('endDate null uses today as endInclusive', () {
      final agg = MedicationPlanAggregate(
        plan: MedicationPlan(
          id: 'p1',
          babyId: 'b1',
          medicationName: 'X',
          startDate: DateTime(2026, 4, 5),
          endDate: null,
          createdAt: DateTime(2026, 4, 5),
          updatedAt: DateTime(2026, 4, 5),
        ),
        frequency: const MedicationFrequency(
          planId: 'p1',
          type: MedicationFrequencyType.daily,
        ),
        dose: const MedicationDose(planId: 'p1', amount: 1, unit: '片'),
        times: [
          MedicationTime(
            id: 't1',
            planId: 'p1',
            timeOfDay: '09:00',
            isEnabled: true,
            createdAt: DateTime(2026, 4, 5),
          ),
        ],
      );

      final slots = service.computeSlots(agg: agg, today: DateTime(2026, 4, 7));
      expect(slots, hasLength(3)); // 4/5, 4/6, 4/7
      expect(slots.first.scheduledDate, DateTime(2026, 4, 5));
      expect(slots.last.scheduledDate, DateTime(2026, 4, 7));
    });

    test('compliance counts taken/missed/skipped by slot key', () {
      final slots = [
        MedicationSlot(
          planId: 'p1',
          scheduledDate: DateTime(2026, 4, 7),
          timeId: 't1',
          timeOfDay: '10:00',
        ),
        MedicationSlot(
          planId: 'p1',
          scheduledDate: DateTime(2026, 4, 7),
          timeId: 't2',
          timeOfDay: '20:00',
        ),
      ];

      final statuses = [
        MedicationIntakeStatus(
          id: 's1',
          planId: 'p1',
          scheduledDate: DateTime(2026, 4, 7, 18, 0),
          timeId: 't1',
          status: MedicationIntakeStatusType.taken,
          recordedAt: DateTime(2026, 4, 7, 10, 5),
        ),
        MedicationIntakeStatus(
          id: 's2',
          planId: 'p1',
          scheduledDate: DateTime(2026, 4, 7),
          timeId: 't2',
          status: MedicationIntakeStatusType.missed,
          recordedAt: DateTime(2026, 4, 7, 21, 0),
        ),
      ];

      final compliance = service.computeCompliance(slots: slots, statuses: statuses);
      expect(compliance.totalSlots, 2);
      expect(compliance.takenSlots, 1);
      expect(compliance.missedSlots, 1);
      expect(compliance.skippedSlots, 0);
      expect(compliance.complianceRate, 0.5);
    });
  });
}

