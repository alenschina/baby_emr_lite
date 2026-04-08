import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/baby.dart';
import '../../domain/enums/gender.dart';
import '../../domain/repositories/baby_repository.dart';
import 'core_providers.dart';

/// 所有宝宝列表 Provider
final babiesProvider = FutureProvider<List<Baby>>((ref) async {
  final repository = ref.watch(babyRepositoryProvider);
  return repository.getAll();
});

/// 当前宝宝 ID Notifier
/// 能够响应 baby 创建和切换事件
final currentBabyIdProvider =
    StateNotifierProvider<CurrentBabyIdNotifier, String?>((ref) {
  final repository = ref.watch(babyRepositoryProvider);
  return CurrentBabyIdNotifier(repository);
});

class CurrentBabyIdNotifier extends StateNotifier<String?> {
  final BabyRepository _repository;

  CurrentBabyIdNotifier(this._repository) : super(_repository.currentBabyId) {
    // 监听 repository 中的变化
    _repository.watchCurrentBabyId().listen((id) {
      state = id;
    });
  }

  Future<void> setCurrentBaby(String id) async {
    await _repository.setCurrentBaby(id);
    state = id;
  }
}

/// 当前宝宝 Provider
final currentBabyProvider = FutureProvider<Baby?>((ref) async {
  final currentId = ref.watch(currentBabyIdProvider);
  if (currentId == null) return null;

  final repository = ref.watch(babyRepositoryProvider);
  return repository.getById(currentId);
});

/// 是否有宝宝 Provider
/// 监听 babyNotifierProvider 的状态变化
final hasBabiesProvider = Provider<bool>((ref) {
  final babiesAsync = ref.watch(babyNotifierProvider);
  return babiesAsync.when(
    data: (babies) => babies.isNotEmpty,
    loading: () => false,
    error: (err, stack) => false,
  );
});

/// 宝宝操作 Notifier
class BabyNotifier extends StateNotifier<AsyncValue<List<Baby>>> {
  final BabyRepository _repository;

  BabyNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBabies();
  }

  Future<void> loadBabies() async {
    state = const AsyncValue.loading();
    try {
      final babies = await _repository.getAll();
      state = AsyncValue.data(babies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createBaby({
    required String name,
    required Gender gender,
    required DateTime birthDate,
    String? avatarPath,
  }) async {
    try {
      final baby = await _repository.create(
        name: name,
        gender: gender,
        birthDate: birthDate,
        avatarPath: avatarPath,
      );
      // 确保状态正确更新
      final currentList = state.valueOrNull ?? [];
      state = AsyncValue.data([...currentList, baby]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBaby(String id) async {
    try {
      await _repository.delete(id);
      final currentList = state.valueOrNull ?? [];
      state = AsyncValue.data(
        currentList.where((b) => b.id != id).toList(),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setCurrentBaby(String id) async {
    await _repository.setCurrentBaby(id);
  }
}

/// 宝宝 Notifier Provider
final babyNotifierProvider =
    StateNotifierProvider<BabyNotifier, AsyncValue<List<Baby>>>((ref) {
      final repository = ref.watch(babyRepositoryProvider);
      return BabyNotifier(repository);
    });
