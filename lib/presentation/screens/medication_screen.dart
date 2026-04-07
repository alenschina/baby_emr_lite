import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/medication_providers.dart';
import '../providers/baby_providers.dart';
import '../utils/baby_record_guard.dart';
import '../widgets/medication_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/forms/medication_record_form.dart';
import '../widgets/adaptive_fab.dart';

/// 用药管理屏幕
/// 对齐 Design Spec：全局背景 + 玻璃拟态组件
class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(medicationRecordNotifierProvider);
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

                  // Tab 栏
                  MedicationTabBar(controller: _tabController),

                  const SizedBox(height: 16),

                  // Tab 内容
                  Expanded(
                    child: recordsAsync.when(
                      data: (records) {
                        final activeRecords = records
                            .where((r) => r.isActive)
                            .toList();
                        final inactiveRecords = records
                            .where((r) => !r.isActive)
                            .toList();

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            // 当前用药
                            _buildCurrentMedications(activeRecords),
                            // 用药历史
                            _buildHistoryMedications(inactiveRecords),
                            // 依从性统计
                            _buildComplianceStats(activeRecords),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text(
                          '加载失败: $error',
                          style: TextStyle(color: AppTheme.error),
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
                '用药管理',
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
                  baby != null ? '${baby.name}的用药计划' : '管理宝宝用药',
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

  Widget _buildCurrentMedications(List records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: AppTheme.slate300),
            const SizedBox(height: 16),
            Text(
              '暂无正在进行的用药',
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return MedicationRecordCard(
          record: record,
          onEdit: () => _showEditRecordSheet(context, record),
          onDelete: () => _confirmDelete(context, record.id),
          onEndMedication: () => _endMedication(context, record.id),
        );
      },
    );
  }

  Widget _buildHistoryMedications(List records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.slate300),
            const SizedBox(height: 16),
            Text(
              '暂无历史记录',
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return MedicationRecordCard(
          record: record,
          onEdit: () => _showEditRecordSheet(context, record),
          onDelete: () => _confirmDelete(context, record.id),
        );
      },
    );
  }

  Widget _buildComplianceStats(List activeRecords) {
    if (activeRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: AppTheme.slate300),
            const SizedBox(height: 16),
            Text(
              '暂无数据统计',
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '添加用药计划后可查看依从性统计',
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

    // 计算总体依从性
    return FutureBuilder<List<double>>(
      future: _calculateOverallCompliance(activeRecords),
      builder: (context, snapshot) {
        final complianceRates = snapshot.data ?? [];
        final overallRate = complianceRates.isEmpty
            ? 0.0
            : complianceRates.reduce((a, b) => a + b) / complianceRates.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Column(
            children: [
              // 总体依从性
              GlassCard(
                child: Column(
                  children: [
                    // 环形进度指示器
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: overallRate,
                            strokeWidth: 12,
                            backgroundColor: AppTheme.slate200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              overallRate >= 0.8
                                  ? AppTheme.success
                                  : overallRate >= 0.5
                                  ? AppTheme.warning
                                  : AppTheme.error,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(overallRate * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                              Text(
                                '总用药依从性',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '基于当前所有用药记录分析',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeCaption,
                        color: AppTheme.textTertiary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 各药品依从性
              ...activeRecords.map((record) {
                return Consumer(
                  builder: (context, ref, _) {
                    final complianceAsync = ref.watch(
                      medicationComplianceProvider(record.id),
                    );
                    return complianceAsync.when(
                      data: (compliance) => GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '已记录 ${compliance.totalDays} 天',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildMiniStat(
                                  '已服',
                                  compliance.takenDays,
                                  AppTheme.success,
                                ),
                                const SizedBox(width: 8),
                                _buildMiniStat(
                                  '漏服',
                                  compliance.missedDays,
                                  AppTheme.error,
                                ),
                                const SizedBox(width: 8),
                                _buildMiniStat(
                                  '跳过',
                                  compliance.skippedDays,
                                  AppTheme.warning,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textTertiary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  Future<List<double>> _calculateOverallCompliance(List records) async {
    final rates = <double>[];
    for (final record in records) {
      final compliance = await ref.read(
        medicationComplianceProvider(record.id).future,
      );
      if (compliance.totalDays > 0) {
        rates.add(compliance.complianceRate);
      }
    }
    return rates;
  }

  void _showAddRecordSheet(BuildContext context) {
    if (!ensureCurrentBabyForNewRecord(ref, context)) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MedicationRecordForm(),
    );
  }

  void _showEditRecordSheet(BuildContext context, record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MedicationRecordForm(existingRecord: record),
    );
  }

  Future<void> _endMedication(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束用药'),
        content: const Text('确定要结束这个用药计划吗？结束后将移至历史记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await ref
          .read(medicationRecordNotifierProvider.notifier)
          .endMedication(id, DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result != null ? '用药计划已结束' : '操作失败')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条用药记录吗？此操作无法撤销。'),
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
          .read(medicationRecordNotifierProvider.notifier)
          .delete(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '记录已删除' : '删除失败')));
      }
    }
  }
}
