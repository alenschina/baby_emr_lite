import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/medication_plan_aggregate.dart';
import '../providers/medication_providers.dart';
import '../providers/baby_providers.dart';
import '../utils/baby_record_guard.dart';
import '../widgets/medication_compliance_overview_card.dart';
import '../widgets/medication_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/forms/medication_plan_card.dart';
import '../widgets/forms/medication_plan_form.dart';
import '../widgets/adaptive_fab.dart';
import '../widgets/medication_today_checkin_sheet.dart';

/// 用药管理屏幕
/// 对齐 Design Spec：全局背景 + 玻璃拟态组件
///
/// [initialCheckInPlanId]：从首页「今日提醒」进入时由路由 query 传入，首帧打开对应计划的打卡 sheet。
class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({
    super.key,
    this.initialCheckInPlanId,
    this.initialCheckInPlanName,
  });

  final String? initialCheckInPlanId;
  final String? initialCheckInPlanName;

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _pendingCheckInPlanId;
  String? _pendingCheckInPlanName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scheduleCheckInFromRoute(
      widget.initialCheckInPlanId,
      widget.initialCheckInPlanName,
    );
  }

  @override
  void didUpdateWidget(MedicationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCheckInPlanId != oldWidget.initialCheckInPlanId ||
        widget.initialCheckInPlanName != oldWidget.initialCheckInPlanName) {
      _scheduleCheckInFromRoute(
        widget.initialCheckInPlanId,
        widget.initialCheckInPlanName,
      );
    }
  }

  void _scheduleCheckInFromRoute(String? planId, String? planName) {
    final pid = planId?.trim();
    if (pid == null || pid.isEmpty) return;
    _pendingCheckInPlanId = pid;
    _pendingCheckInPlanName = planName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingCheckInSheet();
    });
  }

  void _openPendingCheckInSheet() {
    final pid = _pendingCheckInPlanId;
    final pname = _pendingCheckInPlanName;
    if (!mounted || pid == null || pid.isEmpty) return;
    _pendingCheckInPlanId = null;
    _pendingCheckInPlanName = null;
    _showTodayCheckinSheet(
      context,
      filterPlanId: pid,
      filterPlanName: pname,
    );
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          // 与「结束用药」一致：end 落在当天即视为已结束，进入历史
                          return endD.isAfter(todayDate);
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
            // 右上角：添加用药计划 + 今日全部打卡（同 Glass 样式、纵向排列）
            AdaptiveFloatingActionButton(
              onPressed: () => _showAddRecordSheet(context),
              tooltip: '添加用药计划',
              secondaryOnPressed: () => _showTodayCheckinSheet(context),
              secondaryIcon: Icons.fact_check_outlined,
              secondaryTooltip: '今日全部打卡（所有用药计划）',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue currentBabyAsync) {
    // 右侧留给顶部横向两颗玻璃图标（打卡 + 添加），避免标题与 Stack 重叠
    // 须占满行宽：外层 Column 默认会按子节点宽度居中窄 Container，导致标题看起来像「居中」
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 108, 12),
      child: Column(
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
    );
  }

  void _showTodayCheckinSheet(
    BuildContext context, {
    String? filterPlanId,
    String? filterPlanName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MedicationTodayCheckinSheet(
        filterPlanId: filterPlanId,
        filterPlanName: filterPlanName,
      ),
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
          onOpenTodayCheckin: () => _showTodayCheckinSheet(
            context,
            filterPlanId: agg.plan.id,
            filterPlanName: agg.plan.medicationName,
          ),
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

    return FutureBuilder<MedicationCompliance>(
      future: _aggregateActivePlansCompliance(ref, activePlans),
      builder: (context, snapshot) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
          child: Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 8,
                        ),
                        child: Text(
                          '加载依从性数据失败',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            color: AppTheme.error,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      )
                    : MedicationComplianceOverviewCard(
                        isLoading:
                            snapshot.connectionState == ConnectionState.waiting,
                        aggregate: snapshot.data,
                      ),
              ),
              const SizedBox(height: 12),

              ...activePlans.map((agg) {
                final complianceAsync = ref.watch(
                  medicationPlanSlotComplianceProvider(agg.plan.id),
                );
                return complianceAsync.when(
                  data: (compliance) => GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agg.plan.medicationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '应服 ${compliance.totalDays} 次 · 截至今日',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMiniStat(
                              '已服',
                              compliance.takenDays,
                              AppTheme.success,
                            ),
                            const SizedBox(width: 6),
                            _buildMiniStat(
                              '漏服',
                              compliance.missedDays,
                              AppTheme.error,
                            ),
                            const SizedBox(width: 6),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  /// 汇总各进行中计划的槽位统计（加权与环形图分段一致）
  Future<MedicationCompliance> _aggregateActivePlansCompliance(
    WidgetRef ref,
    List<MedicationPlanAggregate> plans,
  ) async {
    var total = 0;
    var taken = 0;
    var missed = 0;
    var skipped = 0;
    for (final agg in plans) {
      final c = await ref.read(
        medicationPlanSlotComplianceProvider(agg.plan.id).future,
      );
      total += c.totalDays;
      taken += c.takenDays;
      missed += c.missedDays;
      skipped += c.skippedDays;
    }
    final rate = total <= 0 ? 0.0 : taken / total;
    return MedicationCompliance(
      totalDays: total,
      takenDays: taken,
      missedDays: missed,
      skippedDays: skipped,
      complianceRate: rate,
    );
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
