import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/hive_storage.dart';
import '../../data/encryption/encryption_service.dart';
import '../../data/repositories/baby_repository_impl.dart';
import '../../data/repositories/medical_record_repository_impl.dart';
import '../../data/repositories/vaccination_record_repository_impl.dart';
import '../../data/repositories/growth_data_repository_impl.dart';
import '../../data/repositories/medication_record_repository_impl.dart';
import '../../data/repositories/medication_status_repository_impl.dart';
import '../../data/repositories/medication_reminder_repository_impl.dart';
import '../../data/repositories/medication_plan_repository_impl.dart';
import '../../domain/repositories/baby_repository.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../../domain/repositories/vaccination_record_repository.dart';
import '../../domain/repositories/growth_data_repository.dart';
import '../../domain/repositories/medication_record_repository.dart';
import '../../domain/repositories/medication_status_repository.dart';
import '../../domain/repositories/medication_reminder_repository.dart';
import '../../domain/repositories/medication_plan_repository.dart';

/// 加密服务 Provider
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Hive 存储 Provider
final hiveStorageProvider = Provider<HiveStorage>((ref) {
  final encryption = ref.watch(encryptionServiceProvider);
  return HiveStorage(encryption);
});

/// 宝宝仓库 Provider
final babyRepositoryProvider = Provider<BabyRepository>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return BabyRepositoryImpl(storage);
});

/// 病例记录仓库 Provider
final medicalRecordRepositoryProvider = Provider<MedicalRecordRepository>((
  ref,
) {
  final storage = ref.watch(hiveStorageProvider);
  return MedicalRecordRepositoryImpl(storage);
});

/// 疫苗接种记录仓库 Provider
final vaccinationRecordRepositoryProvider =
    Provider<VaccinationRecordRepository>((ref) {
      final storage = ref.watch(hiveStorageProvider);
      return VaccinationRecordRepositoryImpl(storage);
    });

/// 生长发育数据仓库 Provider
final growthDataRepositoryProvider = Provider<GrowthDataRepository>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return GrowthDataRepositoryImpl(storage);
});

/// 用药记录仓库 Provider
final medicationRecordRepositoryProvider = Provider<MedicationRecordRepository>(
  (ref) {
    final storage = ref.watch(hiveStorageProvider);
    return MedicationRecordRepositoryImpl(storage);
  },
);

/// 用药状态仓库 Provider
final medicationStatusRepositoryProvider = Provider<MedicationStatusRepository>(
  (ref) {
    final storage = ref.watch(hiveStorageProvider);
    return MedicationStatusRepositoryImpl(storage);
  },
);

/// 用药提醒仓库 Provider
final medicationReminderRepositoryProvider =
    Provider<MedicationReminderRepository>((ref) {
      final storage = ref.watch(hiveStorageProvider);
      return MedicationReminderRepositoryImpl(storage);
    });

/// 新用药计划仓库 Provider（方案 C）
final medicationPlanRepositoryProvider = Provider<MedicationPlanRepository>((
  ref,
) {
  final storage = ref.watch(hiveStorageProvider);
  return MedicationPlanRepositoryImpl(storage);
});

/// 应用初始化 Provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  // 初始化加密服务
  final encryption = ref.read(encryptionServiceProvider);
  await encryption.initialize();

  // 初始化 Hive 存储
  final storage = ref.read(hiveStorageProvider);
  await storage.initialize();
});
