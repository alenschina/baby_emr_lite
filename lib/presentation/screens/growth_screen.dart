import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/growth_data_providers.dart';
import '../providers/baby_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/forms/growth_data_form.dart';

/// 生长发育屏幕
/// 对齐 Design Spec：全局背景 + 玻璃拟态组件
class GrowthScreen extends ConsumerStatefulWidget {
  const GrowthScreen({super.key});

  @override
  ConsumerState<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends ConsumerState<GrowthScreen> {
  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(growthDataNotifierProvider);
    final latestDataAsync = ref.watch(latestGrowthDataProvider);
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

              // 最新数据统计卡片
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: latestDataAsync.when(
                  data: (latest) {
                    if (latest == null) return const SizedBox.shrink();
                    return _buildHealthCard(latest);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),

              // 记录列表
              Expanded(
                child: recordsAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return _buildEmptyState();
                    }

                    // 按日期排序（最新在前）
                    final sortedRecords = List.of(records)
                      ..sort(
                        (a, b) =>
                            b.measurementDate.compareTo(a.measurementDate),
                      );

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: sortedRecords.length,
                      itemBuilder: (context, index) {
                        final record = sortedRecords[index];
                        final previousRecord = index < sortedRecords.length - 1
                            ? sortedRecords[index + 1]
                            : null;
                        return GrowthDataCard(
                          record: record,
                          previousRecord: previousRecord,
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
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80), // 上移避免被底部导航栏遮挡
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.fabShadow,
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddRecordSheet(context),
          backgroundColor: AppTheme.brandPrimary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
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
                '生长发育',
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
                  baby != null ? '${baby.name}的生长记录' : '记录宝宝的成长',
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

  Widget _buildHealthCard(latest) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 18,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '我的健康',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
              Text(
                '· 更新于 ${_formatTime(latest.measurementDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 健康指标
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.height_rounded,
                  value: '${latest.height.toStringAsFixed(1)}',
                  unit: 'cm',
                  label: '身高',
                  color: AppTheme.brandPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.slate200),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.monitor_weight_rounded,
                  value: '${latest.weight.toStringAsFixed(1)}',
                  unit: 'kg',
                  label: '体重',
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up_rounded, size: 64, color: AppTheme.slate300),
          const SizedBox(height: 16),
          Text(
            '暂无生长记录',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角按钮记录身高体重',
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
      backgroundColor: Colors.transparent,
      builder: (context) => const GrowthDataForm(),
    );
  }

  void _showEditRecordSheet(BuildContext context, record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GrowthDataForm(existingRecord: record),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条生长记录吗？此操作无法撤销。'),
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
          .read(growthDataNotifierProvider.notifier)
          .delete(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '记录已删除' : '删除失败')));
      }
    }
  }
}
