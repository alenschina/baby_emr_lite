import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/growth_data.dart';
import '../providers/growth_data_providers.dart';
import '../providers/baby_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/forms/growth_data_form.dart';
import '../widgets/adaptive_fab.dart';

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

              // 历史记录标题
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '历史记录',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textTertiary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),

              // 记录列表 - 时间轴展示
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

                    return _buildTimeline(sortedRecords);
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

  /// 构建时间轴展示
  Widget _buildTimeline(List<GrowthData> records) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isFirst = index == 0;
        final isLast = index == records.length - 1;
        final previousRecord = index < records.length - 1
            ? records[index + 1]
            : null;

        return _buildTimelineItem(
          record: record,
          previousRecord: previousRecord,
          isFirst: isFirst,
          isLast: isLast,
          onEdit: () => _showEditRecordSheet(context, record),
          onDelete: () => _confirmDelete(context, record.id),
        );
      },
    );
  }

  /// 构建时间轴单个节点
  Widget _buildTimelineItem({
    required GrowthData record,
    required GrowthData? previousRecord,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    // 计算差异
    double? heightDiff;
    double? weightDiff;
    if (previousRecord != null) {
      heightDiff = record.height - previousRecord.height;
      weightDiff = record.weight - previousRecord.weight;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧时间轴
        SizedBox(
          width: 44,
          child: Column(
            children: [
              // 时间轴节点
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isFirst
                      ? AppTheme.brandPrimary
                      : AppTheme.brandPrimary.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              // 连接线
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.brandPrimary.withOpacity(0.3),
                        AppTheme.brandPrimary.withOpacity(0.08),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 右侧细长条形卡片
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TimelineGrowthBar(
              record: record,
              heightDiff: heightDiff,
              weightDiff: weightDiff,
              isFirst: isFirst,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddRecordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GrowthDataForm(),
    );
  }

  void _showEditRecordSheet(BuildContext context, GrowthData record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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

/// 细长条形时间轴生长记录组件
class _TimelineGrowthBar extends StatelessWidget {
  final GrowthData record;
  final double? heightDiff;
  final double? weightDiff;
  final bool isFirst;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TimelineGrowthBar({
    required this.record,
    this.heightDiff,
    this.weightDiff,
    this.isFirst = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isFirst
            ? AppTheme.glassCardGradientHigh
            : AppTheme.glassCardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFirst
              ? AppTheme.brandPrimary.withOpacity(0.25)
              : AppTheme.glassBorder,
          width: 1,
        ),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: AppTheme.brandPrimary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：日期
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: isFirst
                      ? AppTheme.brandPrimary
                      : AppTheme.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(record.measurementDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isFirst
                        ? AppTheme.brandPrimary
                        : AppTheme.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const Spacer(),
                // 操作按钮
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: AppTheme.error.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 第二行：数据
            Row(
              children: [
                // 身高数据
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.height_rounded,
                          size: 14,
                          color: AppTheme.brandPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          record.height.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'cm',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (heightDiff != null && heightDiff != 0) ...[
                          const SizedBox(width: 6),
                          _buildDiffBadge(heightDiff!, AppTheme.brandPrimary),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 体重数据
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monitor_weight_rounded,
                          size: 14,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          record.weight.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (weightDiff != null && weightDiff != 0) ...[
                          const SizedBox(width: 6),
                          _buildDiffBadge(weightDiff!, AppTheme.success),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffBadge(double diff, Color baseColor) {
    final isPositive = diff > 0;
    final color = isPositive ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            diff.abs().toStringAsFixed(1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
