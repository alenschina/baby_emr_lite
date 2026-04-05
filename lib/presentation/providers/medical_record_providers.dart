import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../models/medical_record_filter.dart';
import 'core_providers.dart';
import 'baby_providers.dart';

/// 当前宝宝的病例记录列表 Provider
final medicalRecordsProvider = FutureProvider<List<MedicalRecord>>((ref) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return [];

  final repository = ref.watch(medicalRecordRepositoryProvider);
  return repository.getByBabyId(currentId);
});

/// 病例记录操作 Notifier
/// 能够响应当前宝宝变化并自动刷新数据
class MedicalRecordNotifier
    extends StateNotifier<AsyncValue<List<MedicalRecord>>> {
  final MedicalRecordRepository _repository;
  final Ref _ref;

  MedicalRecordNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    // 监听当前宝宝 ID 变化
    _ref.listen<String?>(currentBabyIdProvider, (previous, next) {
      if (previous != next) {
        loadRecords();
      }
    });
    // 初始加载
    loadRecords();
  }

  String? get _babyId => _ref.read(currentBabyIdProvider);

  Future<void> loadRecords() async {
    final babyId = _babyId;
    if (babyId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final records = await _repository.getByBabyId(babyId);
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 根据过滤器筛选记录
  List<MedicalRecord> filterRecords(MedicalRecordFilter filter) {
    final records = state.value ?? [];
    if (!filter.isActive) return records;

    return records.where((record) {
      // 年份区间筛选
      if (filter.startYear != null &&
          record.visitDate.year < filter.startYear!) {
        return false;
      }
      if (filter.endYear != null && record.visitDate.year > filter.endYear!) {
        return false;
      }

      // 医疗机构筛选
      if (filter.hospital != null && filter.hospital!.isNotEmpty) {
        if (!record.hospital.contains(filter.hospital!)) {
          return false;
        }
      }

      // 疾病类型筛选（诊断关键词）
      if (filter.diagnosisKeyword != null &&
          filter.diagnosisKeyword!.isNotEmpty) {
        if (!record.diagnosis
            .toLowerCase()
            .contains(filter.diagnosisKeyword!.toLowerCase())) {
          return false;
        }
      }

      // 药品名称筛选
      if (filter.medicationKeyword != null &&
          filter.medicationKeyword!.isNotEmpty) {
        if (!record.medications
            .toLowerCase()
            .contains(filter.medicationKeyword!.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<MedicalRecord?> create({
    required DateTime visitDate,
    required String symptoms,
    required String diagnosis,
    required String hospital,
    required String doctor,
    required String medications,
    required String notes,
  }) async {
    final babyId = _babyId;
    if (babyId == null) return null;

    try {
      final record = await _repository.create(
        babyId: babyId,
        visitDate: visitDate,
        symptoms: symptoms,
        diagnosis: diagnosis,
        hospital: hospital,
        doctor: doctor,
        medications: medications,
        notes: notes,
      );
      // 重新加载以确保数据同步
      await loadRecords();
      return record;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<MedicalRecord?> update(
    String id, {
    DateTime? visitDate,
    String? symptoms,
    String? diagnosis,
    String? hospital,
    String? doctor,
    String? medications,
    String? notes,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        visitDate: visitDate,
        symptoms: symptoms,
        diagnosis: diagnosis,
        hospital: hospital,
        doctor: doctor,
        medications: medications,
        notes: notes,
      );

      final records = state.value ?? [];
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        records[index] = updated;
        state = AsyncValue.data([...records]);
      }
      return updated;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      state = AsyncValue.data(
        state.value?.where((r) => r.id != id).toList() ?? [],
      );
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// 病例记录 Notifier Provider
final medicalRecordNotifierProvider =
    StateNotifierProvider<
      MedicalRecordNotifier,
      AsyncValue<List<MedicalRecord>>
    >((ref) {
      final repository = ref.watch(medicalRecordRepositoryProvider);
      return MedicalRecordNotifier(repository, ref);
    });
