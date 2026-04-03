import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bottom_sheet_utils.dart';
import '../../../domain/entities/medication_record.dart';
import '../../../domain/entities/medication_status.dart';
import '../../../domain/enums/medication_status_type.dart';
import '../../providers/medication_providers.dart';
import '../glass_card.dart';

/// 用药记录表单组件
class MedicationRecordForm extends ConsumerStatefulWidget {
  final MedicationRecord? existingRecord;
  final VoidCallback? onSuccess;

  const MedicationRecordForm({super.key, this.existingRecord, this.onSuccess});

  @override
  ConsumerState<MedicationRecordForm> createState() =>
      _MedicationRecordFormState();
}

class _MedicationRecordFormState extends ConsumerState<MedicationRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _scheduledTimeController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _nameController.text = record.name;
      _dosageController.text = record.dosage;
      _frequencyController.text = record.frequency;
      _scheduledTimeController.text = record.scheduledTime ?? '';
      _stockController.text = record.stockQuantity.toString();
      _unitController.text = record.unit;
      _notesController.text = record.notes ?? '';
      _startDate = record.startDate;
      _endDate = record.endDate;
    } else {
      _unitController.text = '片';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _scheduledTimeController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _notesController.dispose();
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
                    isEditing ? '编辑用药计划' : '添加用药计划',
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

              // 药品名称
              _buildTextField(
                controller: _nameController,
                label: '药品名称',
                hint: '如：阿莫西林颗粒',
                required: true,
              ),
              const SizedBox(height: 16),

              // 剂量和频率
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _dosageController,
                      label: '剂量',
                      hint: '如：每次1袋',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _frequencyController,
                      label: '频率',
                      hint: '如：每日3次',
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 计划用药时间
              _buildTextField(
                controller: _scheduledTimeController,
                label: '计划用药时间',
                hint: '如：早8点、晚8点',
              ),
              const SizedBox(height: 16),

              // 开始日期和结束日期
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: '开始日期',
                      date: _startDate,
                      onTap: _selectStartDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: '结束日期',
                      date: _endDate,
                      hint: '可选',
                      onTap: _selectEndDate,
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 库存数量和单位
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildNumberField(
                      controller: _stockController,
                      label: '库存数量',
                      hint: '当前库存',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _unitController,
                      label: '单位',
                      hint: '片/袋',
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 备注
              _buildTextField(
                controller: _notesController,
                label: '备注',
                hint: '用药注意事项等',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(
                        text: isEditing ? '保存修改' : '开始计划',
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
    int maxLines = 1,
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
          maxLines: maxLines,
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

  Widget _buildNumberField({
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
          keyboardType: TextInputType.number,
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
                  final number = int.tryParse(value);
                  if (number == null || number < 0) {
                    return '请输入有效数值';
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

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(medicationRecordNotifierProvider.notifier);
      final stock = int.parse(_stockController.text.trim());

      if (isEditing) {
        await notifier.update(
          widget.existingRecord!.id,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          frequency: _frequencyController.text.trim(),
          scheduledTime: _scheduledTimeController.text.trim().isNotEmpty
              ? _scheduledTimeController.text.trim()
              : null,
          startDate: _startDate,
          endDate: _endDate,
          stockQuantity: stock,
          unit: _unitController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('用药计划已更新')));
        }
      } else {
        await notifier.create(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          frequency: _frequencyController.text.trim(),
          scheduledTime: _scheduledTimeController.text.trim().isNotEmpty
              ? _scheduledTimeController.text.trim()
              : null,
          startDate: _startDate,
          endDate: _endDate,
          stockQuantity: stock,
          unit: _unitController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('用药计划添加成功')));
        }
      }

      widget.onSuccess?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// 用药记录卡片组件
class MedicationRecordCard extends ConsumerWidget {
  final MedicationRecord record;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onEndMedication;

  const MedicationRecordCard({
    super.key,
    required this.record,
    this.onEdit,
    this.onDelete,
    this.onEndMedication,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = record.isActive;

    // 获取依从性统计
    final complianceAsync = ref.watch(medicationComplianceProvider(record.id));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：药品名称和状态
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              StatusBadge(
                text: isActive ? '进行中' : '已结束',
                type: isActive ? StatusType.success : StatusType.info,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 剂量和频率
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.medication_outlined,
                text: record.dosage,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(icon: Icons.schedule, text: record.frequency),
            ],
          ),

          // 计划用药时间
          if (record.scheduledTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.textTertiary),
                const SizedBox(width: 8),
                Text(
                  '计划时间: ${record.scheduledTime}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // 日期范围
          Row(
            children: [
              Icon(Icons.date_range, size: 16, color: AppTheme.textTertiary),
              const SizedBox(width: 8),
              Text(
                '${_formatDate(record.startDate)} - ${record.endDate != null ? _formatDate(record.endDate!) : "进行中"}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),

          // 库存
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: record.stockQuantity <= 5
                    ? AppTheme.warning
                    : AppTheme.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                '库存: ${record.stockQuantity} ${record.unit}',
                style: TextStyle(
                  fontSize: 13,
                  color: record.stockQuantity <= 5
                      ? AppTheme.warning
                      : AppTheme.textSecondary,
                  fontWeight: record.stockQuantity <= 5
                      ? FontWeight.w500
                      : FontWeight.normal,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              if (record.stockQuantity <= 5) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '库存不足',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.warning,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // 依从性统计
          if (isActive)
            complianceAsync.when(
              data: (compliance) {
                if (compliance.totalDays == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: compliance.complianceRate,
                            backgroundColor: AppTheme.slate200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              compliance.complianceRate >= 0.8
                                  ? AppTheme.success
                                  : compliance.complianceRate >= 0.5
                                  ? AppTheme.warning
                                  : AppTheme.error,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(compliance.complianceRate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // 备注
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.slate50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notes_outlined,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 操作按钮
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isActive && onEndMedication != null)
                TextButton.icon(
                  onPressed: onEndMedication,
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text('结束用药'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                  ),
                ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppTheme.textTertiary,
                  ),
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppTheme.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.brandPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.brandPrimary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.brandPrimary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }
}

/// 用药状态记录卡片
class MedicationStatusCard extends ConsumerWidget {
  final MedicationStatus status;
  final VoidCallback? onTap;

  const MedicationStatusCard({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color, bgColor) = switch (status.status) {
      MedicationStatusType.taken => (
        Icons.check_circle,
        AppTheme.success,
        AppTheme.success.withOpacity(0.1),
      ),
      MedicationStatusType.missed => (
        Icons.cancel,
        AppTheme.error,
        AppTheme.error.withOpacity(0.1),
      ),
      MedicationStatusType.skipped => (
        Icons.remove_circle_outline,
        AppTheme.warning,
        AppTheme.warning.withOpacity(0.1),
      ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(status.date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  if (status.notes != null && status.notes!.isNotEmpty)
                    Text(
                      status.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              status.status.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }
}
