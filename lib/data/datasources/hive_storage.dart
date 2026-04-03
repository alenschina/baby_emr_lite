import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../encryption/encryption_service.dart';

/// Hive 存储数据源
/// 负责本地数据的加密存储
class HiveStorage {
  late final Box<String> _encryptedBox;
  final EncryptionService _encryption;

  HiveStorage(this._encryption);

  /// 初始化 Hive
  Future<void> initialize() async {
    await Hive.initFlutter();
    _encryptedBox = await Hive.openBox<String>(AppConstants.storageKey);
  }

  /// 保存数据（自动加密）
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final encrypted = _encryption.encrypt(jsonString);
    await _encryptedBox.put(key, encrypted);
  }

  /// 获取数据（自动解密）
  Map<String, dynamic>? getData(String key) {
    final encrypted = _encryptedBox.get(key);
    if (encrypted == null) return null;

    try {
      final decrypted = _encryption.decrypt(encrypted);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      // 解密失败，返回 null
      return null;
    }
  }

  /// 删除数据
  Future<void> deleteData(String key) async {
    await _encryptedBox.delete(key);
  }

  /// 获取所有键
  Iterable<String> getKeys() {
    return _encryptedBox.keys.cast<String>();
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    await _encryptedBox.clear();
  }

  /// 关闭存储
  Future<void> close() async {
    await _encryptedBox.close();
  }
}
