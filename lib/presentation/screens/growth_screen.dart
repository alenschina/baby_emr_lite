import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/growth_data.dart';
import '../providers/growth_data_providers.dart';
import '../providers/baby_providers.dart';
import '../utils/baby_record_guard.dart';
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
        child: Stack(
          children: [
            // 主要内容
            SafeArea(
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

                  // 趋势图表
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: recordsAsync.when(
                      data: (records) {
                        if (records.isEmpty || records.length < 2) {
                          return const SizedBox.shrink();
                        }
                        return _GrowthTrendChart(records: records);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),

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
            // 右上角添加按钮
            AdaptiveFloatingActionButton(
              onPressed: () => _showAddRecordSheet(context),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(14),
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '我的健康',
                    style: const TextStyle(
                      fontSize: 15,
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
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
              Container(width: 1, height: 32, color: AppTheme.slate200),
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
            '点击右上角按钮添加记录',
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    if (!ensureCurrentBabyForNewRecord(ref, context)) return;
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
                      horizontal: 8,
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
                          size: 12,
                          color: AppTheme.brandPrimary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            record.height.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontFamily: AppTheme.fontFamily,
                            ),
                            overflow: TextOverflow.fade,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                        const SizedBox(width: 1),
                        Text(
                          'cm',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textTertiary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (heightDiff != null && heightDiff != 0) ...[
                          const SizedBox(width: 4),
                          _buildDiffBadge(heightDiff!, AppTheme.brandPrimary),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 体重数据
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
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
                          size: 12,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            record.weight.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontFamily: AppTheme.fontFamily,
                            ),
                            overflow: TextOverflow.fade,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                        const SizedBox(width: 1),
                        Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textTertiary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (weightDiff != null && weightDiff != 0) ...[
                          const SizedBox(width: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 9,
            color: color,
          ),
          const SizedBox(width: 1),
          Flexible(
            child: Text(
              diff.abs().toStringAsFixed(1),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: AppTheme.fontFamily,
              ),
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
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

/// 生长趋势图表组件
/// 显示身高和体重的双轴折线图，带有动画效果
/// 使用玻璃拟态设计风格
/// ignore: must_be_immutable
class _GrowthTrendChart extends StatefulWidget {
  final List<GrowthData> records;

  const _GrowthTrendChart({required this.records});

  @override
  State<_GrowthTrendChart> createState() => _GrowthTrendChartState();
}

class _GrowthTrendChartState extends State<_GrowthTrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 按日期排序（从旧到新）
    final sortedRecords = List.of(widget.records)
      ..sort((a, b) => a.measurementDate.compareTo(b.measurementDate));

    // 计算数据范围
    final heights = sortedRecords.map((r) => r.height).toList();
    final weights = sortedRecords.map((r) => r.weight).toList();
    final minHeight = heights.reduce((a, b) => a < b ? a : b);
    final maxHeight = heights.reduce((a, b) => a > b ? a : b);
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    // 计算Y轴范围（添加一些边距）
    final heightMin = (minHeight - 2).floorToDouble();
    final heightMax = (maxHeight + 2).ceilToDouble();
    final weightMin = (minWeight - 0.5).floorToDouble();
    final weightMax = (maxWeight + 0.5).ceilToDouble();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: AppTheme.glassCardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图表标题
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.brandPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '成长趋势',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const Spacer(),
                    // 图例
                    _buildLegend(AppTheme.brandPrimary, '身高'),
                    const SizedBox(width: 10),
                    _buildLegend(AppTheme.success, '体重'),
                  ],
                ),
                const SizedBox(height: 10),
                // 图表区域 - 增加左右留白，减小图表宽度
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: LineChart(
                      _buildLineChartData(
                        sortedRecords: sortedRecords,
                        heightMin: heightMin,
                        heightMax: heightMax,
                        weightMin: weightMin,
                        weightMax: weightMax,
                        progress: _animation.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textTertiary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData({
    required List<GrowthData> sortedRecords,
    required double heightMin,
    required double heightMax,
    required double weightMin,
    required double weightMax,
    required double progress,
  }) {
    // 生成数据点
    final heightSpots = <FlSpot>[];
    final weightSpots = <FlSpot>[];

    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      final x = i.toDouble();

      // 身高数据点（左侧Y轴）
      heightSpots.add(FlSpot(x, record.height));

      // 体重数据点（右侧Y轴，需要映射到身高轴范围）
      // 正确映射：将体重值映射到 [heightMin, heightMax] 范围
      final normalizedWeight =
          heightMin +
          (record.weight - weightMin) /
              (weightMax - weightMin) *
              (heightMax - heightMin);
      weightSpots.add(FlSpot(x, normalizedWeight));
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white.withOpacity(0.95),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipMargin: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final index = touchedSpot.x.toInt();
              if (index < 0 || index >= sortedRecords.length) {
                return null;
              }
              final record = sortedRecords[index];
              final isHeight = touchedSpot.barIndex == 0;
              return LineTooltipItem(
                isHeight
                    ? '${record.height.toStringAsFixed(1)} cm'
                    : '${record.weight.toStringAsFixed(1)} kg',
                TextStyle(
                  color: isHeight ? AppTheme.brandPrimary : AppTheme.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFamily: AppTheme.fontFamily,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 5, // 与Y轴刻度间隔保持一致
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.slate200.withOpacity(0.5),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= sortedRecords.length) {
                return const SizedBox.shrink();
              }
              // 只显示首尾日期
              if (index == 0 || index == sortedRecords.length - 1) {
                final date = sortedRecords[index].measurementDate;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textTertiary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false, // 隐藏左侧Y轴数值标签
            reservedSize: 0,
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false, // 隐藏右侧Y轴数值标签
            reservedSize: 0,
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (sortedRecords.length - 1).toDouble(),
      minY: heightMin,
      maxY: heightMax,
      lineBarsData: [
        // 身高折线
        LineChartBarData(
          spots: heightSpots
              .map(
                (spot) => FlSpot(
                  spot.x,
                  spot.y * progress + heightMin * (1 - progress),
                ),
              )
              .toList(),
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppTheme.brandPrimary,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: AppTheme.brandPrimary,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.brandPrimary.withOpacity(0.15),
                AppTheme.brandPrimary.withOpacity(0.02),
              ],
            ),
          ),
        ),
        // 体重折线
        LineChartBarData(
          spots: weightSpots
              .map(
                (spot) => FlSpot(
                  spot.x,
                  spot.y * progress + heightMin * (1 - progress),
                ),
              )
              .toList(),
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppTheme.success,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: AppTheme.success,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.success.withOpacity(0.15),
                AppTheme.success.withOpacity(0.02),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
