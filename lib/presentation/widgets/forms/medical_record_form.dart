import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bottom_sheet_utils.dart';
import '../../../domain/entities/medical_record.dart';
import '../../providers/medical_record_providers.dart';
import '../../utils/baby_record_guard.dart';
import '../glass_card.dart';

int _alphaFromOpacity(double opacity) =>
    (opacity * 255).round().clamp(0, 255).toInt();

/// 病例记录表单组件
class MedicalRecordForm extends ConsumerStatefulWidget {
  final MedicalRecord? existingRecord;
  final VoidCallback? onSuccess;

  const MedicalRecordForm({super.key, this.existingRecord, this.onSuccess});

  @override
  ConsumerState<MedicalRecordForm> createState() => _MedicalRecordFormState();
}

class _MedicalRecordFormState extends ConsumerState<MedicalRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _doctorController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _selectedDate = record.visitDate;
      _symptomsController.text = record.symptoms;
      _diagnosisController.text = record.diagnosis;
      _hospitalController.text = record.hospital;
      _doctorController.text = record.doctor;
      _medicationsController.text = record.medications;
      _notesController.text = record.notes;
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _hospitalController.dispose();
    _doctorController.dispose();
    _medicationsController.dispose();
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
                    isEditing ? '编辑病例记录' : '添加病例记录',
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

              // 就诊日期
              _buildDateField(),
              const SizedBox(height: 16),

              // 症状
              _buildTextField(
                controller: _symptomsController,
                label: '症状',
                hint: '请描述宝宝的症状',
                maxLines: 2,
                required: true,
              ),
              const SizedBox(height: 16),

              // 诊断
              _buildTextField(
                controller: _diagnosisController,
                label: '诊断',
                hint: '医生的诊断结果',
                required: true,
              ),
              const SizedBox(height: 16),

              // 医院和医生
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _hospitalController,
                      label: '医院',
                      hint: '就诊医院',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _doctorController,
                      label: '医生',
                      hint: '主治医生',
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 处方药物
              _buildTextField(
                controller: _medicationsController,
                label: '处方药物',
                hint: '医生开具的药物',
                required: true,
              ),
              const SizedBox(height: 16),

              // 备注
              _buildTextField(
                controller: _notesController,
                label: '备注',
                hint: '其他需要记录的信息',
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
          '就诊日期',
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
              color: Colors.white.withAlpha(_alphaFromOpacity(0.6)),
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
            fillColor: Colors.white.withAlpha(_alphaFromOpacity(0.6)),
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
    if (!isEditing && !ensureCurrentBabyForNewRecord(ref, context)) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(medicalRecordNotifierProvider.notifier);

      if (isEditing) {
        final updated = await notifier.update(
          widget.existingRecord!.id,
          visitDate: _selectedDate,
          symptoms: _symptomsController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          hospital: _hospitalController.text.trim(),
          doctor: _doctorController.text.trim(),
          medications: _medicationsController.text.trim(),
          notes: _notesController.text.trim(),
        );
        if (mounted) {
          if (updated != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                duration: AppTheme.snackBarDisplayDuration,
                content: const Text('病例记录已更新'),
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
          visitDate: _selectedDate,
          symptoms: _symptomsController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          hospital: _hospitalController.text.trim(),
          doctor: _doctorController.text.trim(),
          medications: _medicationsController.text.trim(),
          notes: _notesController.text.trim(),
        );
        if (mounted) {
          if (created != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                duration: AppTheme.snackBarDisplayDuration,
                content: const Text('病例记录添加成功'),
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

/// 病例记录卡片组件
class MedicalRecordCard extends ConsumerWidget {
  final MedicalRecord record;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicalRecordCard({
    super.key,
    required this.record,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    _formatDate(record.visitDate),
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
          const SizedBox(height: 12),

          // 诊断
          Text(
            record.diagnosis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),

          // 症状
          Text(
            '症状: ${record.symptoms}',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),

          // 医院和医生
          Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 16,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                record.hospital,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.person_outline,
                size: 16,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                record.doctor,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 药物
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.brandPrimary.withAlpha(_alphaFromOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 16,
                  color: AppTheme.brandPrimary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    record.medications,
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

          // 备注
          if (record.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '备注: ${record.notes}',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textTertiary,
                fontFamily: AppTheme.fontFamily,
                fontStyle: FontStyle.italic,
              ),
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
