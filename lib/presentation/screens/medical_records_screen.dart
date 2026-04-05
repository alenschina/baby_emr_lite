import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/medical_record.dart';
import '../providers/medical_record_providers.dart';
import '../providers/baby_providers.dart';
import '../widgets/forms/medical_record_form.dart';
import '../widgets/glass_card.dart';
import '../widgets/medical_record_filter_panel.dart';
import '../models/medical_record_filter.dart';

/// 病例记录屏幕
/// 对齐 Design Spec：全局背景 + 玻璃拟态组件
class MedicalRecordsScreen extends ConsumerStatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  ConsumerState<MedicalRecordsScreen> createState() =>
      _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends ConsumerState<MedicalRecordsScreen> {
  bool _showFilter = false;
  MedicalRecordFilter _currentFilter = const MedicalRecordFilter();

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(medicalRecordNotifierProvider);
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

                  // 过滤面板
                  if (_showFilter)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MedicalRecordFilterPanel(
                        currentFilter: _currentFilter,
                        availableHospitals: _getAvailableHospitals(
                          recordsAsync.value ?? [],
                        ),
                        availableYears: _getAvailableYears(
                          recordsAsync.value ?? [],
                        ),
                        onFilterChanged: (filter) {
                          setState(() {
                            _currentFilter = filter;
                          });
                        },
                        onClear: () {
                          setState(() {
                            _currentFilter = const MedicalRecordFilter();
                          });
                        },
                      ),
                    ),

                  // 记录列表 - 时间轴展示
                  Expanded(
                    child: recordsAsync.when(
                      data: (records) {
                        if (records.isEmpty) {
                          return _buildEmptyState();
                        }

                        // 应用过滤器
                        final filteredRecords =
                            _currentFilter.isActive
                                ? ref
                                    .read(medicalRecordNotifierProvider.notifier)
                                    .filterRecords(_currentFilter)
                                : records;

                        if (filteredRecords.isEmpty && _currentFilter.isActive) {
                          return _buildEmptyFilterState();
                        }

                        // 按时间倒序排列（最新的在最上方）
                        final sortedRecords = List.of(filteredRecords)
                          ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
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
            // 右上角操作按钮组
            _buildTopActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue currentBabyAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
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

  Widget _buildTopActionButtons(BuildContext context) {
    const double buttonSize = 40;
    const double gap = 12;
    const double spacing = 16;

    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: spacing, right: spacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopActionButton(
                icon: Icons.filter_list_rounded,
                size: buttonSize,
                onTap: () {
                  setState(() {
                    _showFilter = !_showFilter;
                  });
                },
              ),
              const SizedBox(width: gap),
              _buildTopActionButton(
                icon: Icons.add_rounded,
                size: buttonSize,
                onTap: () => _showAddRecordSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassIconContainer(
            icon: icon,
            size: size,
            iconSize: 20,
            iconColor: AppTheme.textSecondary,
            onTap: onTap,
          ),
          if (icon == Icons.filter_list_rounded && _currentFilter.isActive)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.brandPrimary.withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
              ),
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

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_outlined,
            size: 64,
            color: AppTheme.slate300,
          ),
          const SizedBox(height: 16),
          Text(
            '没有符合条件的记录',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请调整筛选条件',
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
  Widget _buildTimeline(List<MedicalRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isFirst = index == 0;
        final isLast = index == records.length - 1;

        return _buildTimelineItem(
          record: record,
          isFirst: isFirst,
          isLast: isLast,
          index: index,
          onEdit: () => _showEditRecordSheet(context, record),
          onDelete: () => _confirmDelete(context, record.id),
        );
      },
    );
  }

  /// 构建时间轴单个节点
  Widget _buildTimelineItem({
    required MedicalRecord record,
    required bool isFirst,
    required bool isLast,
    required int index,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    // 所有记录默认折叠
    final shouldCollapse = true;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧时间轴
        SizedBox(
          width: 40,
          child: Column(
            children: [
              // 时间轴节点
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFirst
                      ? AppTheme.brandPrimary
                      : AppTheme.brandPrimary.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandPrimary.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // 连接线
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.brandPrimary.withOpacity(0.4),
                        AppTheme.brandPrimary.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 右侧内容卡片
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _TimelineRecordCard(
              record: record,
              isFirst: isFirst,
              shouldCollapse: shouldCollapse,
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
      builder: (context) => const MedicalRecordForm(),
    );
  }

  void _showEditRecordSheet(BuildContext context, MedicalRecord record) {
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

  List<String> _getAvailableHospitals(List<MedicalRecord> records) {
    return MedicalRecordFilter.getAvailableHospitals(records);
  }

  List<int> _getAvailableYears(List<MedicalRecord> records) {
    return MedicalRecordFilter.getAvailableYears(records);
  }
}

/// 时间轴病例记录卡片组件
class _TimelineRecordCard extends StatefulWidget {
  final MedicalRecord record;
  final bool isFirst;
  final bool shouldCollapse;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TimelineRecordCard({
    required this.record,
    this.isFirst = false,
    this.shouldCollapse = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_TimelineRecordCard> createState() => _TimelineRecordCardState();
}

class _TimelineRecordCardState extends State<_TimelineRecordCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    // 前两条记录默认展开，从第三条开始默认折叠
    _isExpanded = !widget.shouldCollapse;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.isFirst
            ? AppTheme.glassCardGradientHigh
            : AppTheme.glassCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isFirst
              ? AppTheme.brandPrimary.withOpacity(0.3)
              : AppTheme.glassBorder,
          width: 1,
        ),
        boxShadow: widget.isFirst
            ? [
                BoxShadow(
                  color: AppTheme.brandPrimary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：日期标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.brandPrimary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 16,
                  color: AppTheme.brandPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.record.visitDate),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandPrimary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const Spacer(),
                // 展开/折叠按钮
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                // 操作按钮
                if (widget.onEdit != null)
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 内容区域
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 医院名称（始终展开）
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.record.hospital,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // 诊断结果（始终展开）
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 16,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.record.diagnosis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.success,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 可折叠区域：症状、医生
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 症状
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.sick_outlined,
                                  size: 16,
                                  color: AppTheme.textTertiary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                        child: Text(
                          '症状: ${widget.record.symptoms}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 医生
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                  color: AppTheme.textTertiary,
                                ),
                                const SizedBox(width: 6),
                                                     Text(
                        '主治医生: ${widget.record.doctor}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textTertiary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                // 处方药物（始终展开）
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPrimary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.medication_rounded,
                        size: 16,
                        color: AppTheme.brandPrimary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.record.medications,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.brandPrimary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 备注（如果有，始终展开）
                if (widget.record.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.record.notes,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                            fontStyle: FontStyle.italic,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
