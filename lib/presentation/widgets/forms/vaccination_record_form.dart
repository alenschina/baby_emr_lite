import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bottom_sheet_utils.dart';
import '../../../domain/entities/vaccination_record.dart';
import '../../providers/vaccination_record_providers.dart';
import '../../utils/baby_record_guard.dart';
import '../card_outlined_action_button.dart';
import '../glass_card.dart';

/// 疫苗接种表单组件
class VaccinationRecordForm extends ConsumerStatefulWidget {
  final VaccinationRecord? existingRecord;
  final VoidCallback? onSuccess;

  const VaccinationRecordForm({super.key, this.existingRecord, this.onSuccess});

  @override
  ConsumerState<VaccinationRecordForm> createState() =>
      _VaccinationRecordFormState();
}

class _VaccinationRecordFormState extends ConsumerState<VaccinationRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _vaccineNameController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _injectionSiteController = TextEditingController();
  DateTime _scheduledDate = DateTime.now();
  DateTime? _actualDate;
  bool _isLoading = false;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _vaccineNameController.text = record.vaccineName;
      _batchNumberController.text = record.batchNumber ?? '';
      _injectionSiteController.text = record.injectionSite ?? '';
      _scheduledDate = record.scheduledDate;
      _actualDate = record.actualDate;
    }
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _batchNumberController.dispose();
    _injectionSiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取底部安全区域 + 导航栏高度 + 额外间距
    final bottomPadding = BottomSheetUtils.getFullBottomPadding(context);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomPadding,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.glassCardGradientHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? '编辑疫苗记录' : '添加疫苗计划',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 疫苗名称
              _buildTextField(
                controller: _vaccineNameController,
                label: '疫苗名称',
                hint: '如：乙肝疫苗、脊灰疫苗等',
                required: true,
              ),
              const SizedBox(height: 16),

              // 计划接种日期
              _buildDateField(
                label: '计划接种日期',
                date: _scheduledDate,
                onTap: _selectScheduledDate,
              ),
              const SizedBox(height: 16),

              // 实际接种日期（可选）
              _buildDateField(
                label: '实际接种日期',
                date: _actualDate,
                hint: '未接种',
                onTap: _selectActualDate,
                onClear: () => setState(() => _actualDate = null),
              ),
              const SizedBox(height: 16),

              // 批号和接种部位
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _batchNumberController,
                      label: '疫苗批号',
                      hint: '选填',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _injectionSiteController,
                      label: '接种部位',
                      hint: '如：左上臂',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(
                        text: isEditing ? '保存修改' : '添加计划',
                        onPressed: _submit,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.slate600,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.brandPrimary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入$label';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    String hint = '请选择日期',
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.slate600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            if (onClear != null && date != null)
              GestureDetector(
                onTap: onClear,
                child: Text(
                  '清除',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.error,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppTheme.brandPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  date != null ? _formatDate(date) : hint,
                  style: TextStyle(
                    fontSize: 14,
                    color: date != null
                        ? AppTheme.brandDark
                        : AppTheme.slate400,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _scheduledDate = date);
    }
  }

  Future<void> _selectActualDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _actualDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _actualDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!isEditing && !ensureCurrentBabyForNewRecord(ref, context)) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(vaccinationRecordNotifierProvider.notifier);

      if (isEditing) {
        final updated = await notifier.update(
          widget.existingRecord!.id,
          vaccineName: _vaccineNameController.text.trim(),
          scheduledDate: _scheduledDate,
          actualDate: _actualDate,
          batchNumber: _batchNumberController.text.trim().isNotEmpty
              ? _batchNumberController.text.trim()
              : null,
          injectionSite: _injectionSiteController.text.trim().isNotEmpty
              ? _injectionSiteController.text.trim()
              : null,
          isCompleted: _actualDate != null,
        );
        if (mounted) {
          if (updated != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                duration: AppTheme.snackBarDisplayDuration,
                content: const Text('疫苗记录已更新'),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                duration: AppTheme.snackBarDisplayDuration,
                content: const Text('保存失败，请重试'),
              ),
            );
          }
        }
        if (updated == null) return;
      } else {
        final created = await notifier.create(
          vaccineName: _vaccineNameController.text.trim(),
          scheduledDate: _scheduledDate,
          actualDate: _actualDate,
          batchNumber: _batchNumberController.text.trim().isNotEmpty
              ? _batchNumberController.text.trim()
              : null,
          injectionSite: _injectionSiteController.text.trim().isNotEmpty
              ? _injectionSiteController.text.trim()
              : null,
        );
        if (mounted) {
          if (created != null) {
            final message =
                _actualDate != null ? '疫苗接种记录添加成功' : '疫苗计划添加成功';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                duration: AppTheme.snackBarDisplayDuration,
                content: Text(message),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                duration: AppTheme.snackBarDisplayDuration,
                content: const Text('保存失败，请重试'),
              ),
            );
          }
        }
        if (created == null) return;
      }

      widget.onSuccess?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            duration: AppTheme.snackBarDisplayDuration,
            content: Text('操作失败: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// 疫苗接种记录卡片组件
class VaccinationRecordCard extends ConsumerWidget {
  final VaccinationRecord record;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkCompleted;

  const VaccinationRecordCard({
    super.key,
    required this.record,
    this.onEdit,
    this.onDelete,
    this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = record.isCompleted;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDateOnly = DateTime(
      record.scheduledDate.year,
      record.scheduledDate.month,
      record.scheduledDate.day,
    );
    final isOverdue = !isCompleted && scheduledDateOnly.isBefore(today);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.cardPadding,
        AppTheme.cardPadding,
        AppTheme.cardPadding,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：疫苗名称和状态
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.vaccineName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              StatusBadge(
                text: isCompleted
                    ? '已完成'
                    : isOverdue
                    ? '已逾期'
                    : '待接种',
                type: isCompleted
                    ? StatusType.success
                    : isOverdue
                    ? StatusType.error
                    : StatusType.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 计划接种日期
          Row(
            children: [
              Icon(Icons.event, size: 16, color: AppTheme.textTertiary),
              const SizedBox(width: 8),
              Text(
                '计划: ${_formatDate(record.scheduledDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),

          // 实际接种日期
          if (record.isCompleted && record.actualDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                Text(
                  '实际: ${_formatDate(record.actualDate!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.success,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ],

          // 批号和接种部位
          if (record.batchNumber != null || record.injectionSite != null) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record.batchNumber != null)
                  Text(
                    '批号: ${record.batchNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                if (record.injectionSite != null) ...[
                  if (record.batchNumber != null) const SizedBox(height: 4),
                  Text(
                    '部位: ${record.injectionSite}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ],
            ),
          ],

          // 操作按钮（与用药计划卡片：主操作 Elevated + 次要 Outlined 一致）
          const SizedBox(height: 12),
          if (!isCompleted && onMarkCompleted != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkCompleted!,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  '标记完成',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (onEdit != null)
                  CardOutlinedActionButton(
                    icon: Icons.edit_outlined,
                    label: '编辑',
                    foreground: AppTheme.textSecondary,
                    onPressed: onEdit!,
                  ),
                if (onDelete != null)
                  CardOutlinedActionButton(
                    icon: Icons.delete_outline,
                    label: '删除',
                    foreground: AppTheme.error,
                    onPressed: onDelete!,
                  ),
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
