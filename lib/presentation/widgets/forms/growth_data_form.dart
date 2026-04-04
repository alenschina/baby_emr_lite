import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bottom_sheet_utils.dart';
import '../../../domain/entities/growth_data.dart';
import '../../providers/growth_data_providers.dart';
import '../glass_card.dart';

/// 生长发育表单组件
class GrowthDataForm extends ConsumerStatefulWidget {
  final GrowthData? existingRecord;
  final VoidCallback? onSuccess;

  const GrowthDataForm({super.key, this.existingRecord, this.onSuccess});

  @override
  ConsumerState<GrowthDataForm> createState() => _GrowthDataFormState();
}

class _GrowthDataFormState extends ConsumerState<GrowthDataForm> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _selectedDate = record.measurementDate;
      _heightController.text = record.height.toString();
      _weightController.text = record.weight.toString();
      _notesController.text = record.notes ?? '';
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
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
                    isEditing ? '编辑生长记录' : '添加生长记录',
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

              // 测量日期
              _buildDateField(),
              const SizedBox(height: 16),

              // 身高和体重
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      controller: _heightController,
                      label: '身高',
                      hint: '如：75.5',
                      suffix: 'cm',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                      controller: _weightController,
                      label: '体重',
                      hint: '如：10.2',
                      suffix: 'kg',
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
                hint: '可选备注信息',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(
                        text: isEditing ? '保存修改' : '添加记录',
                        onPressed: _submit,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '测量日期',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.slate600,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
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
                  _formatDate(_selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.brandDark,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
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
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return '请输入有效的数值';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(growthDataNotifierProvider.notifier);
      final height = double.parse(_heightController.text.trim());
      final weight = double.parse(_weightController.text.trim());

      if (isEditing) {
        await notifier.update(
          widget.existingRecord!.id,
          measurementDate: _selectedDate,
          height: height,
          weight: weight,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
      } else {
        await notifier.create(
          measurementDate: _selectedDate,
          height: height,
          weight: weight,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
      }

      // 先校验 mounted，再获取 messenger 并关闭 bottom sheet，避免在 pop 后继续使用已失效 context
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      final navigator = Navigator.maybeOf(context);

      widget.onSuccess?.call();
      messenger?.showSnackBar(
        SnackBar(content: Text(isEditing ? '生长记录已更新' : '生长记录添加成功')),
      );

      // 延迟到下一帧关闭，避免与当前导航栈变更冲突导致 Navigator lock
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator?.maybePop();
      });
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

/// 生长发育记录卡片组件
class GrowthDataCard extends ConsumerWidget {
  final GrowthData record;
  final GrowthData? previousRecord;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GrowthDataCard({
    super.key,
    required this.record,
    this.previousRecord,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 计算与上次记录的差异
    double? heightDiff;
    double? weightDiff;

    if (previousRecord != null) {
      heightDiff = record.height - previousRecord!.height;
      weightDiff = record.weight - previousRecord!.weight;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：日期和操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppTheme.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(record.measurementDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.brandPrimary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 身高和体重数据
          Row(
            children: [
              // 身高
              Expanded(
                child: _buildDataCard(
                  icon: Icons.height_rounded,
                  label: '身高',
                  value: '${record.height.toStringAsFixed(1)}',
                  unit: 'cm',
                  diff: heightDiff,
                  color: AppTheme.brandPrimary,
                ),
              ),
              const SizedBox(width: 12),
              // 体重
              Expanded(
                child: _buildDataCard(
                  icon: Icons.monitor_weight_rounded,
                  label: '体重',
                  value: '${record.weight.toStringAsFixed(1)}',
                  unit: 'kg',
                  diff: weightDiff,
                  color: AppTheme.success,
                ),
              ),
            ],
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
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    double? diff,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
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
              const SizedBox(width: 4),
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
          if (diff != null && diff != 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: diff > 0 ? AppTheme.success : AppTheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${diff.abs().toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: diff > 0 ? AppTheme.success : AppTheme.error,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

/// 生长发育统计卡片
class GrowthStatsCard extends StatelessWidget {
  final GrowthData? latestData;
  final GrowthData? previousData;

  const GrowthStatsCard({super.key, this.latestData, this.previousData});

  @override
  Widget build(BuildContext context) {
    if (latestData == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最新数据',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate500,
              letterSpacing: 1,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.height_rounded,
                label: '身高',
                value: '${latestData!.height.toStringAsFixed(1)} cm',
                color: AppTheme.brandPrimary,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.monitor_weight_rounded,
                label: '体重',
                value: '${latestData!.weight.toStringAsFixed(1)} kg',
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
