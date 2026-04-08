import '../entities/medication_plan_aggregate.dart';
import '../entities/medication_intake_status.dart';
import '../enums/medication_frequency_type.dart';
import '../enums/medication_intake_status_type.dart';

class MedicationSlot {
  final String planId;
  final DateTime scheduledDate; // date-only semantic (local midnight)
  final String timeId;
  final String timeOfDay; // "HH:mm"

  const MedicationSlot({
    required this.planId,
    required this.scheduledDate,
    required this.timeId,
    required this.timeOfDay,
  });

  String get key => '$planId|${scheduledDate.toIso8601String()}|$timeId';
}

class MedicationCompliance {
  final int totalSlots;
  final int takenSlots;
  final int missedSlots;
  final int skippedSlots;
  final double complianceRate;

  const MedicationCompliance({
    required this.totalSlots,
    required this.takenSlots,
    required this.missedSlots,
    required this.skippedSlots,
    required this.complianceRate,
  });
}

class MedicationSlotService {
  const MedicationSlotService();

  DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  List<DateTime> computeOccurrenceDates({
    required DateTime start,
    required DateTime endInclusive,
    required MedicationFrequencyType type,
    required int? interval,
  }) {
    final s = normalizeDate(start);
    final e = normalizeDate(endInclusive);
    if (e.isBefore(s)) return [];

    if (type == MedicationFrequencyType.none) return [];

    int stepDays;
    switch (type) {
      case MedicationFrequencyType.daily:
        stepDays = 1;
        break;
      case MedicationFrequencyType.everyNDays:
        stepDays = (interval ?? 1).clamp(1, 365000);
        break;
      case MedicationFrequencyType.everyNWeeks:
        stepDays = ((interval ?? 1) * 7).clamp(1, 365000);
        break;
      case MedicationFrequencyType.none:
        stepDays = 0;
        break;
    }

    final dates = <DateTime>[];
    for (var d = s; !d.isAfter(e); d = d.add(Duration(days: stepDays))) {
      dates.add(d);
      if (stepDays <= 0) break;
    }
    return dates;
  }

  List<MedicationSlot> computeSlots({
    required MedicationPlanAggregate agg,
    required DateTime today,
  }) {
    final freq = agg.frequency;
    final end = agg.plan.endDate ?? today;
    final occurrenceDates = computeOccurrenceDates(
      start: agg.plan.startDate,
      endInclusive: end,
      type: freq.type,
      interval: freq.interval,
    );

    final enabledTimes = agg.times.where((t) => t.isEnabled).toList()
      ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));

    final slots = <MedicationSlot>[];
    for (final date in occurrenceDates) {
      for (final t in enabledTimes) {
        slots.add(
          MedicationSlot(
            planId: agg.plan.id,
            scheduledDate: normalizeDate(date),
            timeId: t.id,
            timeOfDay: t.timeOfDay,
          ),
        );
      }
    }
    return slots;
  }

  MedicationCompliance computeCompliance({
    required List<MedicationSlot> slots,
    required List<MedicationIntakeStatus> statuses,
  }) {
    if (slots.isEmpty) {
      return const MedicationCompliance(
        totalSlots: 0,
        takenSlots: 0,
        missedSlots: 0,
        skippedSlots: 0,
        complianceRate: 0,
      );
    }

    final statusByKey = <String, MedicationIntakeStatus>{};
    for (final s in statuses) {
      final key = '${s.planId}|${normalizeDate(s.scheduledDate).toIso8601String()}|${s.timeId}';
      statusByKey[key] = s;
    }

    var taken = 0;
    var missed = 0;
    var skipped = 0;

    for (final slot in slots) {
      final s = statusByKey[slot.key];
      if (s == null) continue;
      switch (s.status) {
        case MedicationIntakeStatusType.taken:
          taken++;
          break;
        case MedicationIntakeStatusType.missed:
          missed++;
          break;
        case MedicationIntakeStatusType.skipped:
          skipped++;
          break;
      }
    }

    final total = slots.length;
    final rate = total == 0 ? 0.0 : taken / total;
    return MedicationCompliance(
      totalSlots: total,
      takenSlots: taken,
      missedSlots: missed,
      skippedSlots: skipped,
      complianceRate: rate,
    );
  }
}

