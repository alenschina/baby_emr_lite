import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/vaccination_record_providers.dart';
import '../providers/baby_providers.dart';
import '../widgets/forms/vaccination_record_form.dart';
import '../widgets/adaptive_fab.dart';

/// 疫苗接种屏幕
/// 对齐 Design Spec：全局背景 + 玻璃拟态组件
class VaccinationScreen extends ConsumerStatefulWidget {
  const VaccinationScreen({super.key});

  @override
  ConsumerState<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends ConsumerState<VaccinationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(vaccinationRecordNotifierProvider);
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
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: AppTheme.primaryButtonGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      tabs: const [
                        Tab(text: '待接种'),
                        Tab(text: '已完成'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab 内容
                  Expanded(
                    child: recordsAsync.when(
                      data: (records) {
                        final pendingRecords = records
                            .where((r) => !r.isCompleted)
                            .toList();
                        final completedRecords = records
                            .where((r) => r.isCompleted)
                            .toList();

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRecordList(pendingRecords, isPending: true),
                            _buildRecordList(completedRecords, isPending: false),
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
                '疫苗接种',
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
                  baby != null ? '${baby.name}的疫苗接种' : '管理疫苗接种计划',
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

  Widget _buildRecordList(List records, {required bool isPending}) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.event_available : Icons.check_circle_outline,
              size: 64,
              color: AppTheme.slate300,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? '暂无待接种疫苗' : '暂无已接种记录',
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return VaccinationRecordCard(
          record: record,
          onEdit: () => _showEditRecordSheet(context, record),
          onDelete: () => _confirmDelete(context, record.id),
          onMarkCompleted: !record.isCompleted
              ? () => _markAsCompleted(context, record.id)
              : null,
        );
      },
    );
  }

  void _showAddRecordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VaccinationRecordForm(),
    );
  }

  void _showEditRecordSheet(BuildContext context, record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VaccinationRecordForm(existingRecord: record),
    );
  }

  Future<void> _markAsCompleted(BuildContext context, String id) async {
    final result = await ref
        .read(vaccinationRecordNotifierProvider.notifier)
        .markAsCompleted(id, actualDate: DateTime.now());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result != null ? '已标记为完成' : '操作失败')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条疫苗接种记录吗？此操作无法撤销。'),
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
          .read(vaccinationRecordNotifierProvider.notifier)
          .delete(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '记录已删除' : '删除失败')));
      }
    }
  }
}
