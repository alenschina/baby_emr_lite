import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// 加密服务
/// 对应 Web 版 encryption.ts，使用 AES-GCM 算法
class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Key? _key;
  Encrypter? _encrypter;

  /// 初始化加密服务
  Future<void> initialize() async {
    String? keyString = await _storage.read(
      key: AppConstants.encryptionKeyStorageKey,
    );

    if (keyString == null) {
      // 生成 256 位密钥 (32 字节)
      final keyBytes = _generateSecureRandomBytes(32);
      keyString = base64Encode(keyBytes);
      await _storage.write(
        key: AppConstants.encryptionKeyStorageKey,
        value: keyString,
      );
    }

    _key = Key.fromBase64(keyString);
    _encrypter = Encrypter(AES(_key!, mode: AESMode.gcm, padding: null));
  }

  /// 加密数据
  /// 格式: base64(iv):base64(ciphertext+tag)
  String encrypt(String plaintext) {
    _ensureInitialized();

    // 生成 96 位 IV (GCM 推荐)
    final ivBytes = _generateSecureRandomBytes(12);
    final iv = IV(ivBytes);

    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);

    // 格式: iv:ciphertext
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// 解密数据
  String decrypt(String ciphertext) {
    _ensureInitialized();

    final parts = ciphertext.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid ciphertext format: expected 2 parts');
    }

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    return _encrypter!.decrypt(encrypted, iv: iv);
  }

  /// 加密 JSON 对象
  String encryptJson(Map<String, dynamic> data) {
    return encrypt(jsonEncode(data));
  }

  /// 解密为 JSON 对象
  Map<String, dynamic> decryptJson(String ciphertext) {
    final plaintext = decrypt(ciphertext);
    return jsonDecode(plaintext) as Map<String, dynamic>;
  }

  /// 检查是否已初始化
  bool get isInitialized => _key != null && _encrypter != null;

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
        'EncryptionService not initialized. Call initialize() first.',
      );
    }
  }

  /// 生成安全的随机字节
  Uint8List _generateSecureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// 重置密钥（用于测试或用户主动重置）
  Future<void> resetKey() async {
    await _storage.delete(key: AppConstants.encryptionKeyStorageKey);
    _key = null;
    _encrypter = null;
    await initialize();
  }
}
