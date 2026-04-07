import 'package:uuid/uuid.dart';

import '../../domain/entities/medication_dose.dart';
import '../../domain/entities/medication_frequency.dart';
import '../../domain/entities/medication_plan.dart';
import '../../domain/entities/medication_plan_aggregate.dart';
import '../../domain/entities/medication_plan_upsert_input.dart';
import '../../domain/entities/medication_time.dart';
import '../../domain/entities/medication_intake_status.dart';
import '../../domain/repositories/medication_plan_repository.dart';
import '../datasources/hive_storage.dart';

class MedicationPlanRepositoryImpl implements MedicationPlanRepository {
  final HiveStorage _storage;

  static const _plansKey = 'medication_plans';
  static const _frequenciesKey = 'medication_frequencies';
  static const _timesKey = 'medication_times';
  static const _dosesKey = 'medication_doses';

  // Intake statuses 先用于 deletePlan 的级联清理（Task 4 会抽到独立 repo）
  static const _intakeStatusesKey = 'medication_intake_statuses';

  MedicationPlanRepositoryImpl(this._storage);

  List<MedicationPlan> _getPlans() {
    final data = _storage.getData(_plansKey);
    if (data == null) return [];
    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _savePlans(List<MedicationPlan> plans) async {
    await _storage.saveData(_plansKey, {'list': plans.map((e) => e.toJson()).toList()});
  }

  List<MedicationFrequency> _getFrequencies() {
    final data = _storage.getData(_frequenciesKey);
    if (data == null) return [];
    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationFrequency.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveFrequencies(List<MedicationFrequency> freqs) async {
    await _storage.saveData(
      _frequenciesKey,
      {'list': freqs.map((e) => e.toJson()).toList()},
    );
  }

  List<MedicationDose> _getDoses() {
    final data = _storage.getData(_dosesKey);
    if (data == null) return [];
    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationDose.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveDoses(List<MedicationDose> doses) async {
    await _storage.saveData(_dosesKey, {'list': doses.map((e) => e.toJson()).toList()});
  }

  List<MedicationTime> _getTimes() {
    final data = _storage.getData(_timesKey);
    if (data == null) return [];
    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationTime.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveTimes(List<MedicationTime> times) async {
    await _storage.saveData(_timesKey, {'list': times.map((e) => e.toJson()).toList()});
  }

  List<MedicationIntakeStatus> _getIntakeStatuses() {
    final data = _storage.getData(_intakeStatusesKey);
    if (data == null) return [];
    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicationIntakeStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveIntakeStatuses(List<MedicationIntakeStatus> statuses) async {
    await _storage.saveData(
      _intakeStatusesKey,
      {'list': statuses.map((e) => e.toJson()).toList()},
    );
  }

  static ({List<String> toAdd, List<MedicationTime> toRemove}) diffTimes({
    required List<MedicationTime> existing,
    required List<String> desiredTimeOfDay,
  }) {
    final desired = desiredTimeOfDay.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    final existingSet = existing.map((t) => t.timeOfDay).toSet();

    final toAdd = desired.difference(existingSet).toList()..sort();
    final toRemove = existing.where((t) => !desired.contains(t.timeOfDay)).toList();
    return (toAdd: toAdd, toRemove: toRemove);
  }

  @override
  Future<MedicationPlanAggregate> upsertWithDetails(
    MedicationPlanUpsertInput input,
  ) async {
    final now = DateTime.now();
    final planId = input.planId ?? const Uuid().v4();

    // 1) upsert plan
    final plans = _getPlans();
    final planIndex = plans.indexWhere((p) => p.id == planId);
    final plan = MedicationPlan(
      id: planId,
      babyId: input.babyId,
      medicationName: input.medicationName.trim(),
      startDate: input.startDate,
      endDate: input.endDate,
      notes: input.notes?.trim().isNotEmpty == true ? input.notes!.trim() : null,
      createdAt: planIndex == -1 ? now : plans[planIndex].createdAt,
      updatedAt: now,
    );
    if (planIndex == -1) {
      plans.add(plan);
    } else {
      plans[planIndex] = plan;
    }
    await _savePlans(plans);

    // 2) upsert frequency (by planId overwrite)
    final freqs = _getFrequencies();
    final freqIndex = freqs.indexWhere((f) => f.planId == planId);
    final freq = input.frequency.copyWith(planId: planId);
    if (freqIndex == -1) {
      freqs.add(freq);
    } else {
      freqs[freqIndex] = freq;
    }
    await _saveFrequencies(freqs);

    // 3) upsert dose (by planId overwrite)
    final doses = _getDoses();
    final doseIndex = doses.indexWhere((d) => d.planId == planId);
    final dose = input.dose.copyWith(planId: planId);
    if (doseIndex == -1) {
      doses.add(dose);
    } else {
      doses[doseIndex] = dose;
    }
    await _saveDoses(doses);

    // 4) sync times (final-set semantics)
    final times = _getTimes();
    final existingTimes = times.where((t) => t.planId == planId).toList();
    final diff = diffTimes(existing: existingTimes, desiredTimeOfDay: input.times);

    if (diff.toRemove.isNotEmpty) {
      final removeIds = diff.toRemove.map((t) => t.id).toSet();
      times.removeWhere((t) => removeIds.contains(t.id));
      await _saveTimes(times);
    }

    if (diff.toAdd.isNotEmpty) {
      final created = diff.toAdd.map((timeOfDay) {
        return MedicationTime(
          id: const Uuid().v4(),
          planId: planId,
          timeOfDay: timeOfDay,
          isEnabled: true,
          createdAt: now,
        );
      }).toList();
      times.addAll(created);
      await _saveTimes(times);
    }

    // return aggregate with latest children
    final newTimes = _getTimes()
        .where((t) => t.planId == planId)
        .toList()
      ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));

    return MedicationPlanAggregate(
      plan: plan,
      frequency: freq,
      dose: dose,
      times: newTimes,
    );
  }

  @override
  Future<MedicationPlanAggregate?> getAggregateById(String planId) async {
    final plan = _getPlans().where((p) => p.id == planId).firstOrNull;
    if (plan == null) return null;

    final freq =
        _getFrequencies().where((f) => f.planId == planId).firstOrNull ??
            MedicationFrequency.none(planId: planId);
    final dose = _getDoses().where((d) => d.planId == planId).firstOrNull;
    if (dose == null) return null;

    final times = _getTimes().where((t) => t.planId == planId).toList()
      ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));

    return MedicationPlanAggregate(
      plan: plan,
      frequency: freq,
      dose: dose,
      times: times,
    );
  }

  @override
  Future<List<MedicationPlanAggregate>> listAggregatesByBabyId(
    String babyId,
  ) async {
    final plans = _getPlans().where((p) => p.babyId == babyId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final freqs = _getFrequencies();
    final doses = _getDoses();
    final times = _getTimes();

    return plans.map((plan) {
      final freq = freqs.where((f) => f.planId == plan.id).firstOrNull ??
          MedicationFrequency.none(planId: plan.id);
      final dose = doses.where((d) => d.planId == plan.id).firstOrNull ??
          MedicationDose(planId: plan.id, amount: 1, unit: '片');
      final planTimes = times.where((t) => t.planId == plan.id).toList()
        ..sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));
      return MedicationPlanAggregate(
        plan: plan,
        frequency: freq,
        dose: dose,
        times: planTimes,
      );
    }).toList();
  }

  @override
  Future<void> deletePlan(String planId) async {
    final plans = _getPlans()..removeWhere((p) => p.id == planId);
    await _savePlans(plans);

    final freqs = _getFrequencies()..removeWhere((f) => f.planId == planId);
    await _saveFrequencies(freqs);

    final doses = _getDoses()..removeWhere((d) => d.planId == planId);
    await _saveDoses(doses);

    final times = _getTimes()..removeWhere((t) => t.planId == planId);
    await _saveTimes(times);

    // intake statuses 级联清理
    final statuses =
        _getIntakeStatuses()..removeWhere((s) => s.planId == planId);
    await _saveIntakeStatuses(statuses);
  }

  @override
  Future<bool> updatePlanEndDate(String planId, DateTime endDate) async {
    final plans = _getPlans();
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return false;
    final normalized = DateTime(endDate.year, endDate.month, endDate.day);
    final p = plans[idx];
    plans[idx] = p.copyWith(
      endDate: normalized,
      updatedAt: DateTime.now(),
    );
    await _savePlans(plans);
    return true;
  }
}

