import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/medical_record_providers.dart';
import '../providers/baby_providers.dart';
import '../widgets/forms/medical_record_form.dart';
import '../widgets/adaptive_fab.dart';

/// 病例记录屏幕
/// 对齐 Design Spec：全局背景 + 玻璃拟态组件
class MedicalRecordsScreen extends ConsumerStatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  ConsumerState<MedicalRecordsScreen> createState() =>
      _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends ConsumerState<MedicalRecordsScreen> {
  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(medicalRecordNotifierProvider);
    final currentBabyAsync = ref.watch(currentBabyProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.appBackgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // 顶部标题栏
              _buildHeader(currentBabyAsync),

              // 记录列表
              Expanded(
                child: recordsAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return MedicalRecordCard(
                          record: record,
                          onEdit: () => _showEditRecordSheet(context, record),
                          onDelete: () => _confirmDelete(context, record.id),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '加载失败',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            color: AppTheme.textSecondary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeCaption,
                            color: AppTheme.textTertiary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // 浮动添加按钮
      floatingActionButton: AdaptiveFloatingActionButton(
        onPressed: () => _showAddRecordSheet(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(AsyncValue currentBabyAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '病例记录',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              currentBabyAsync.when(
                data: (baby) => Text(
                  baby != null ? '${baby.name}的病例记录' : '记录就诊信息',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeCaption,
                    color: AppTheme.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: AppTheme.slate300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无病例记录',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角按钮添加就诊记录',
            style: TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              color: AppTheme.textTertiary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRecordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MedicalRecordForm(),
    );
  }

  void _showEditRecordSheet(BuildContext context, record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MedicalRecordForm(existingRecord: record),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条病例记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(medicalRecordNotifierProvider.notifier)
          .delete(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '记录已删除' : '删除失败')));
      }
    }
  }
}
