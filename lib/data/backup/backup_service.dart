import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/hive_storage.dart';
import '../../data/encryption/encryption_service.dart';

/// 备份数据结构
class BackupData {
  final int schemaVersion;
  final String exportedAt;
  final String exportedFrom;
  final Map<String, dynamic> payload;

  BackupData({
    required this.schemaVersion,
    required this.exportedAt,
    required this.exportedFrom,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt,
    'exportedFrom': exportedFrom,
    'payload': payload,
  };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
    schemaVersion: json['schemaVersion'] as int,
    exportedAt: json['exportedAt'] as String,
    exportedFrom: json['exportedFrom'] as String,
    payload: json['payload'] as Map<String, dynamic>,
  );
}

/// 备份服务
/// 负责数据导出和导入
class BackupService {
  final HiveStorage _storage;
  final EncryptionService _encryption;

  BackupService(this._storage, this._encryption);

  /// 导出所有数据
  Future<String> export() async {
    // 收集所有数据
    final payload = <String, dynamic>{};

    // 获取所有存储的键
    final keys = _storage.getKeys();
    for (final key in keys) {
      final data = _storage.getData(key);
      if (data != null) {
        payload[key] = data;
      }
    }

    // 创建备份数据
    final backup = BackupData(
      schemaVersion: AppConstants.backupSchemaVersion,
      exportedAt: DateTime.now().toIso8601String(),
      exportedFrom: 'flutter',
      payload: payload,
    );

    // 加密备份数据
    final jsonString = jsonEncode(backup.toJson());
    return _encryption.encrypt(jsonString);
  }

  /// 导出并分享文件
  Future<void> exportAndShare() async {
    final encrypted = await export();

    // 创建临时文件
    final tempDir = await getTemporaryDirectory();
    final fileName =
        '${AppConstants.backupFilePrefix}_${DateTime.now().toIso8601String().split('T')[0]}.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(encrypted);

    // 分享文件
    await Share.shareXFiles([XFile(file.path)], subject: '幼儿病例记录备份');
  }

  /// 导入数据
  Future<void> import(String encryptedData) async {
    // 解密数据
    final decrypted = _encryption.decrypt(encryptedData);
    final json = jsonDecode(decrypted) as Map<String, dynamic>;

    // 解析备份数据
    final backup = BackupData.fromJson(json);

    // 版本检查
    if (backup.schemaVersion > AppConstants.backupSchemaVersion) {
      throw UnsupportedError(
        '不支持的备份版本: ${backup.schemaVersion}，当前支持版本: ${AppConstants.backupSchemaVersion}',
      );
    }

    // 恢复数据
    final payload = backup.payload;
    for (final entry in payload.entries) {
      await _storage.saveData(entry.key, entry.value as Map<String, dynamic>);
    }
  }

  /// 验证备份文件格式
  bool validateFormat(String encryptedData) {
    try {
      final decrypted = _encryption.decrypt(encryptedData);
      final json = jsonDecode(decrypted) as Map<String, dynamic>;

      // 检查必需字段
      return json.containsKey('schemaVersion') &&
          json.containsKey('exportedAt') &&
          json.containsKey('payload');
    } catch (e) {
      return false;
    }
  }
}
