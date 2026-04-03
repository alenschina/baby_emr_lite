import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/backup/backup_service.dart';
import '../../presentation/providers/baby_providers.dart';
import '../../presentation/providers/core_providers.dart';
import '../widgets/baby_list_item.dart';
import '../widgets/add_baby_form.dart';
import '../widgets/glass_card.dart';

/// 数据管理屏幕
/// 对齐 Design Spec：全局背景 + 玻璃拟态卡片
class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babiesAsync = ref.watch(babyNotifierProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('管理与备份'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Container(
        decoration: AppTheme.appBackgroundDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 宝宝管理标题
                _buildSectionTitle(
                  icon: Icons.child_care_rounded,
                  title: '宝宝管理',
                ),
                const SizedBox(height: 16),

                // 宝宝列表
                babiesAsync.when(
                  data: (babies) {
                    if (babies.isEmpty) {
                      return _buildEmptyState();
                    }
                    return Column(
                      children: babies.map((baby) {
                        return BabyListItem(
                          baby: baby,
                          onTap: () =>
                              _showSwitchBabyDialog(context, ref, baby.id),
                          onDelete: () => _showDeleteConfirm(
                            context,
                            ref,
                            baby.id,
                            baby.name,
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      '加载失败: $error',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 添加新宝宝表单
                const AddBabyForm(),

                const SizedBox(height: 32),

                // 数据备份与导出
                _buildSectionTitle(
                  icon: Icons.download_rounded,
                  title: '数据备份与导出',
                ),
                const SizedBox(height: 16),

                _buildBackupSection(context, ref),

                const SizedBox(height: 16),

                // 提示信息
                const Center(
                  child: Text(
                    '所有数据均已通过 AES-256 加密存储在您的本地设备上，导出文件也包含加密数据。',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeCaption,
                      color: AppTheme.textTertiary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 100), // 底部留白
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.brandPrimary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeSectionTitle,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.cardPaddingXLarge),
      child: const Center(
        child: Text(
          '暂无宝宝信息，请添加',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildBackupButton(
            icon: Icons.download,
            label: '导出备份',
            color: AppTheme.info,
            onTap: () => _handleExport(context, ref),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBackupButton(
            icon: Icons.upload,
            label: '导入恢复',
            color: AppTheme.success,
            onTap: null, // TODO: 实现导入功能
          ),
        ),
      ],
    );
  }

  Widget _buildBackupButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24),
        backgroundColor: isEnabled ? null : AppTheme.slate100,
        boxShadow: isEnabled ? AppTheme.cardShadow : [],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppTheme.radiusIconContainer,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                fontWeight: FontWeight.w500,
                color: isEnabled ? AppTheme.textPrimary : AppTheme.textTertiary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitchBabyDialog(
    BuildContext context,
    WidgetRef ref,
    String babyId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('切换宝宝'),
        content: const Text('确定要切换到这个宝宝吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(babyNotifierProvider.notifier).setCurrentBaby(babyId);
              ref.read(currentBabyIdProvider.notifier).state = babyId;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已切换宝宝')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    String babyId,
    String babyName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除 "$babyName" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(babyNotifierProvider.notifier).deleteBaby(babyId);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('"$babyName" 已删除')));
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    try {
      final storage = ref.read(hiveStorageProvider);
      final encryption = ref.read(encryptionServiceProvider);
      final backupService = BackupService(storage, encryption);

      await backupService.exportAndShare();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('备份文件已生成')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }
}
