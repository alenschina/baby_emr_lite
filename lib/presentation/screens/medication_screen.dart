import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/medication_plan_aggregate.dart';
import '../providers/medication_providers.dart';
import '../providers/baby_providers.dart';
import '../utils/baby_record_guard.dart';
import '../widgets/medication_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/forms/medication_plan_card.dart';
import '../widgets/forms/medication_plan_form.dart';
import '../widgets/adaptive_fab.dart';
import '../widgets/medication_today_checkin_sheet.dart';

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
    final plansAsync = ref.watch(medicationPlanNotifierProvider);
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
                    child: plansAsync.when(
                      data: (plans) {
                        final now = DateTime.now();
                        final todayDate = DateTime(now.year, now.month, now.day);
                        bool isActivePlan(MedicationPlanAggregate a) {
                          final end = a.plan.endDate;
                          if (end == null) return true;
                          final endD = DateTime(end.year, end.month, end.day);
                          return !endD.isBefore(todayDate);
                        }

                        final activePlans =
                            plans.where(isActivePlan).toList();
                        final endedPlans =
                            plans.where((a) => !isActivePlan(a)).toList();

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            // 当前用药
                            _buildCurrentMedications(context, activePlans),
                            // 用药历史
                            _buildHistoryMedications(context, endedPlans),
                            // 依从性统计（方案 C：按 plan 槽位）
                            Consumer(
                              builder: (context, ref, _) {
                                final plansAsync = ref.watch(
                                  activeMedicationPlanAggregatesProvider,
                                );
                                return plansAsync.when(
                                  data: (plans) =>
                                      _buildPlanComplianceStats(ref, plans),
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (e, _) => Center(
                                    child: Text(
                                      '加载失败: $e',
                                      style: TextStyle(color: AppTheme.error),
                                    ),
                                  ),
                                );
                              },
                            ),
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
          IconButton(
            tooltip: '今日打卡',
            onPressed: () => _showTodayCheckinSheet(context),
            icon: const Icon(
              Icons.fact_check_outlined,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showTodayCheckinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MedicationTodayCheckinSheet(),
    );
  }

  Widget _buildCurrentMedications(
    BuildContext context,
    List<MedicationPlanAggregate> plans,
  ) {
    if (plans.isEmpty) {
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
              '点击右上角按钮添加用药计划',
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
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final agg = plans[index];
        return MedicationPlanCard(
          aggregate: agg,
          onEdit: () => _showEditPlanSheet(context, agg),
          onDelete: () => _confirmDeletePlan(context, agg.plan.id),
          onEndPlan: () => _endPlan(context, agg.plan.id),
        );
      },
    );
  }

  Widget _buildHistoryMedications(
    BuildContext context,
    List<MedicationPlanAggregate> plans,
  ) {
    if (plans.isEmpty) {
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
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final agg = plans[index];
        return MedicationPlanCard(
          aggregate: agg,
          onEdit: () => _showEditPlanSheet(context, agg),
          onDelete: () => _confirmDeletePlan(context, agg.plan.id),
        );
      },
    );
  }

  Widget _buildPlanComplianceStats(
    WidgetRef ref,
    List<MedicationPlanAggregate> activePlans,
  ) {
    if (activePlans.isEmpty) {
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

    return FutureBuilder<double>(
      future: _calculateOverallWeightedPlanCompliance(ref, activePlans),
      builder: (context, snapshot) {
        final overallRate = snapshot.data ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Column(
            children: [
              GlassCard(
                child: Column(
                  children: [
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
                      '基于当前用药计划（按时间点槽位；总览按应服次数加权）',
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

              ...activePlans.map((agg) {
                final complianceAsync = ref.watch(
                  medicationPlanSlotComplianceProvider(agg.plan.id),
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
                                agg.plan.medicationName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '应服 ${compliance.totalDays} 次（截至今日）',
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

  /// 各 active 计划的槽位加权：总已服 / 总应服（与简单平均各计划率相比更公平）
  Future<double> _calculateOverallWeightedPlanCompliance(
    WidgetRef ref,
    List<MedicationPlanAggregate> plans,
  ) async {
    var totalSlots = 0;
    var takenSlots = 0;
    for (final agg in plans) {
      final compliance = await ref.read(
        medicationPlanSlotComplianceProvider(agg.plan.id).future,
      );
      totalSlots += compliance.totalDays;
      takenSlots += compliance.takenDays;
    }
    if (totalSlots <= 0) return 0.0;
    return takenSlots / totalSlots;
  }

  void _showAddRecordSheet(BuildContext context) {
    if (!ensureCurrentBabyForNewRecord(ref, context)) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MedicationPlanForm(),
    );
  }

  void _showEditPlanSheet(BuildContext context, MedicationPlanAggregate agg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MedicationPlanForm(existingAggregate: agg),
    );
  }

  Future<void> _endPlan(BuildContext context, String planId) async {
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
      final ok = await ref
          .read(medicationPlanNotifierProvider.notifier)
          .endPlan(planId, DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? '用药计划已结束' : '操作失败')),
        );
      }
    }
  }

  Future<void> _confirmDeletePlan(BuildContext context, String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除该用药计划吗？打卡记录将一并清除，且无法撤销。'),
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
          .read(medicationPlanNotifierProvider.notifier)
          .deletePlan(planId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '计划已删除' : '删除失败')));
      }
    }
  }
}
