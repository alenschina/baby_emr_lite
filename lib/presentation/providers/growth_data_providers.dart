import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/growth_data.dart';
import '../../domain/repositories/growth_data_repository.dart';
import 'core_providers.dart';
import 'baby_providers.dart';

/// 当前宝宝的生长数据列表 Provider
final growthDataListProvider = FutureProvider<List<GrowthData>>((ref) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return [];

  final repository = ref.watch(growthDataRepositoryProvider);
  return repository.getByBabyId(currentId);
});

/// 最新生长数据 Provider
final latestGrowthDataProvider = FutureProvider<GrowthData?>((ref) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return null;

  final repository = ref.watch(growthDataRepositoryProvider);
  return repository.getLatest(currentId);
});

/// 生长数据操作 Notifier
/// 能够响应当前宝宝变化并自动刷新数据
class GrowthDataNotifier extends StateNotifier<AsyncValue<List<GrowthData>>> {
  final GrowthDataRepository _repository;
  final Ref _ref;

  GrowthDataNotifier(this._repository, this._ref)
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

  Future<GrowthData?> create({
    required DateTime measurementDate,
    required double height,
    required double weight,
    String? notes,
  }) async {
    final babyId = _babyId;
    if (babyId == null) return null;

    try {
      final record = await _repository.create(
        babyId: babyId,
        measurementDate: measurementDate,
        height: height,
        weight: weight,
        notes: notes,
      );
      // 重新加载以确保数据同步
      await loadRecords();
      // 使最新数据 provider 失效，强制刷新首页显示
      _ref.invalidate(latestGrowthDataProvider);
      return record;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<GrowthData?> update(
    String id, {
    DateTime? measurementDate,
    double? height,
    double? weight,
    String? notes,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        measurementDate: measurementDate,
        height: height,
        weight: weight,
        notes: notes,
      );

      final records = state.value ?? [];
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        records[index] = updated;
        state = AsyncValue.data([...records]);
      }
      // 使最新数据 provider 失效，强制刷新首页显示
      _ref.invalidate(latestGrowthDataProvider);
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

/// 生长数据 Notifier Provider
final growthDataNotifierProvider =
    StateNotifierProvider<GrowthDataNotifier, AsyncValue<List<GrowthData>>>(
      (ref) {
        final repository = ref.watch(growthDataRepositoryProvider);
        return GrowthDataNotifier(repository, ref);
      });
