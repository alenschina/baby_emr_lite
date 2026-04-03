import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/baby.dart';
import '../../domain/enums/gender.dart';
import '../../domain/repositories/baby_repository.dart';
import '../datasources/hive_storage.dart';

/// 宝宝数据仓库实现
class BabyRepositoryImpl implements BabyRepository {
  final HiveStorage _storage;
  static const _babiesKey = 'babies';
  static const _currentBabyKey = 'current_baby_id';

  final _currentBabyController = StreamController<String?>.broadcast();

  BabyRepositoryImpl(this._storage);

  @override
  Future<List<Baby>> getAll() async {
    final data = _storage.getData(_babiesKey);
    if (data == null) return [];

    final list = data['list'] as List<dynamic>? ?? [];
    return list.map((e) => Baby.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Baby?> getById(String id) async {
    final babies = await getAll();
    return babies.where((b) => b.id == id).firstOrNull;
  }

  @override
  Future<Baby> create({
    required String name,
    required Gender gender,
    required DateTime birthDate,
    String? avatarPath,
  }) async {
    final now = DateTime.now();
    final baby = Baby(
      id: const Uuid().v4(),
      name: name,
      gender: gender,
      birthDate: birthDate,
      avatarPath: avatarPath,
      createdAt: now,
      updatedAt: now,
    );

    final current = await getAll();
    current.add(baby);
    await _saveAll(current);

    // 如果是第一个宝宝，自动设为当前宝宝
    if (current.length == 1) {
      await setCurrentBaby(baby.id);
    }

    return baby;
  }

  @override
  Future<Baby> update(
    String id, {
    String? name,
    Gender? gender,
    DateTime? birthDate,
    String? avatarPath,
  }) async {
    final babies = await getAll();
    final index = babies.indexWhere((b) => b.id == id);
    if (index == -1) {
      throw Exception('Baby not found: $id');
    }

    final baby = babies[index];
    final updated = baby.copyWith(
      name: name ?? baby.name,
      gender: gender ?? baby.gender,
      birthDate: birthDate ?? baby.birthDate,
      avatarPath: avatarPath ?? baby.avatarPath,
      updatedAt: DateTime.now(),
    );

    babies[index] = updated;
    await _saveAll(babies);
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    var babies = await getAll();
    babies = babies.where((b) => b.id != id).toList();
    await _saveAll(babies);

    // 如果删除的是当前宝宝，切换到第一个或清空
    if (currentBabyId == id) {
      await setCurrentBaby(babies.isNotEmpty ? babies.first.id : null);
    }
  }

  @override
  Future<void> setCurrentBaby(String? id) async {
    if (id != null) {
      await _storage.saveData(_currentBabyKey, {'id': id});
    } else {
      await _storage.deleteData(_currentBabyKey);
    }
    _currentBabyController.add(id);
  }

  @override
  String? get currentBabyId {
    final data = _storage.getData(_currentBabyKey);
    return data?['id'] as String?;
  }

  @override
  Stream<String?> watchCurrentBabyId() {
    return _currentBabyController.stream;
  }

  Future<void> _saveAll(List<Baby> babies) async {
    await _storage.saveData(_babiesKey, {
      'list': babies.map((e) => e.toJson()).toList(),
    });
  }
}
