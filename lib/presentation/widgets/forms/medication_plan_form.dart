import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bottom_sheet_utils.dart';
import '../../../domain/entities/medication_dose.dart';
import '../../../domain/entities/medication_frequency.dart';
import '../../../domain/entities/medication_plan_aggregate.dart';
import '../../../domain/entities/medication_plan_upsert_input.dart';
import '../../../domain/enums/medication_frequency_type.dart';
import '../../providers/baby_providers.dart';
import '../../providers/medication_providers.dart';
import '../../utils/baby_record_guard.dart';
import '../glass_card.dart';
import 'medication_plan_card.dart';

/// 方案 C：用药计划表单（频率 / 多时间点 / 剂量 / 周期）
class MedicationPlanForm extends ConsumerStatefulWidget {
  final MedicationPlanAggregate? existingAggregate;
  final VoidCallback? onSuccess;

  const MedicationPlanForm({super.key, this.existingAggregate, this.onSuccess});

  @override
  ConsumerState<MedicationPlanForm> createState() => _MedicationPlanFormState();
}

class _MedicationPlanFormState extends ConsumerState<MedicationPlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitController = TextEditingController();
  final _intervalController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  MedicationFrequencyType _freqType = MedicationFrequencyType.daily;
  List<String> _times = [];
  bool _isLoading = false;

  bool get isEditing => widget.existingAggregate != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingAggregate != null) {
      final a = widget.existingAggregate!;
      _nameController.text = a.plan.medicationName;
      _startDate = a.plan.startDate;
      _endDate = a.plan.endDate;
      _notesController.text = a.plan.notes ?? '';
      _freqType = a.frequency.type;
      _intervalController.text = '${a.frequency.interval ?? 1}';
      final amt = a.dose.amount;
      _amountController.text = amt == amt.roundToDouble()
          ? amt.toInt().toString()
          : amt.toString();
      _unitController.text = a.dose.unit;
      _times = a.times.map((t) => t.timeOfDay).toList()..sort();
    } else {
      _unitController.text = '片';
      _amountController.text = '1';
      _intervalController.text = '1';
      _freqType = MedicationFrequencyType.daily;
      _times = ['09:00'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _intervalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  MedicationFrequency _buildFrequencyForUpsert() {
    final interval = int.tryParse(_intervalController.text.trim()) ?? 1;
    final safe = interval.clamp(1, 365000);
    return switch (_freqType) {
      MedicationFrequencyType.none => MedicationFrequency.none(planId: ''),
      MedicationFrequencyType.daily => const MedicationFrequency(
        planId: '',
        type: MedicationFrequencyType.daily,
        interval: null,
      ),
      MedicationFrequencyType.everyNDays => MedicationFrequency(
        planId: '',
        type: MedicationFrequencyType.everyNDays,
        interval: safe,
      ),
      MedicationFrequencyType.everyNWeeks => MedicationFrequency(
        planId: '',
        type: MedicationFrequencyType.everyNWeeks,
        interval: safe,
      ),
    };
  }

  Future<void> _addTimeSlot() async {
    final initial = _times.isNotEmpty
        ? _parseTimeOfDay(_times.last) ?? const TimeOfDay(hour: 9, minute: 0)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;
    final s = _formatTimeOfDay(picked);
    if (_times.contains(s)) return;
    setState(() {
      _times = [..._times, s]..sort();
    });
  }

  TimeOfDay? _parseTimeOfDay(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
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
              _buildTextField(
                controller: _nameController,
                label: '药品名称',
                hint: '如：阿莫西林颗粒',
                required: true,
              ),
              const SizedBox(height: 16),
              Text(
                '服用频率',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.slate600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MedicationFrequencyType>(
                value: _freqType,
                decoration: _fieldDecoration(),
                items: MedicationFrequencyType.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _freqType = v);
                },
              ),
              if (_freqType == MedicationFrequencyType.everyNDays ||
                  _freqType == MedicationFrequencyType.everyNWeeks) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _intervalController,
                  label: _freqType == MedicationFrequencyType.everyNDays
                      ? '间隔天数'
                      : '间隔周数',
                  hint: '正整数，如 2',
                  required: true,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入间隔';
                    }
                    final n = int.tryParse(value.trim());
                    if (n == null || n < 1) {
                      return '请输入 ≥ 1 的整数';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              Text(
                '用药时间点',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.slate600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '打卡按每个时间点计次；可添加多个时间',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 8),
              ..._times.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.brandDark,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _times = _times.where((e) => e != t).toList());
                        },
                        icon: Icon(Icons.close_rounded, color: AppTheme.error),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addTimeSlot,
                  icon: const Icon(Icons.add_alarm, size: 20),
                  label: const Text('添加时间点'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _amountController,
                      label: '每次剂量',
                      hint: '如：1 或 0.5',
                      required: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入剂量';
                        }
                        final n = num.tryParse(value.trim());
                        if (n == null || n <= 0) {
                          return '请输入大于 0 的数';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _unitController,
                      label: '单位',
                      hint: '片 / ml',
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              Text(
                '当前频率：${medicationFrequencyDisplay(_previewFrequency())}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _notesController,
                label: '备注',
                hint: '用药注意事项等',
                maxLines: 2,
              ),
              const SizedBox(height: 24),
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

  MedicationFrequency _previewFrequency() {
    final interval = int.tryParse(_intervalController.text.trim()) ?? 1;
    return MedicationFrequency(
      planId: '',
      type: _freqType,
      interval: (_freqType == MedicationFrequencyType.everyNDays ||
              _freqType == MedicationFrequencyType.everyNWeeks)
          ? interval.clamp(1, 365000)
          : null,
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
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
        borderSide: const BorderSide(color: AppTheme.brandPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
          keyboardType: keyboardType,
          decoration: _fieldDecoration().copyWith(hintText: hint),
          validator:
              validator ??
              (required
                  ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入$label';
                      }
                      return null;
                    }
                  : null),
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
      setState(() {
        _startDate = date;
        if (_endDate != null &&
            DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
                .isBefore(DateTime(date.year, date.month, date.day))) {
          _endDate = null;
        }
      });
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
    if (_freqType == MedicationFrequencyType.everyNDays ||
        _freqType == MedicationFrequencyType.everyNWeeks) {
      final n = int.tryParse(_intervalController.text.trim());
      if (n == null || n < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: AppTheme.snackBarDisplayDuration,
            content: const Text('请填写有效的间隔数值'),
          ),
        );
        return;
      }
    }

    if (!isEditing && !ensureCurrentBabyForNewRecord(ref, context)) return;

    final babyId = ref.read(currentBabyIdProvider);
    if (babyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          duration: AppTheme.snackBarDisplayDuration,
          content: const Text('请先选择宝宝'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = num.parse(_amountController.text.trim());
      final input = MedicationPlanUpsertInput(
        planId: widget.existingAggregate?.plan.id,
        babyId: babyId,
        medicationName: _nameController.text.trim(),
        startDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
        endDate: _endDate == null
            ? null
            : DateTime(_endDate!.year, _endDate!.month, _endDate!.day),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        frequency: _buildFrequencyForUpsert(),
        dose: MedicationDose(
          planId: '',
          amount: amount,
          unit: _unitController.text.trim(),
        ),
        times: List<String>.from(_times),
      );

      final notifier = ref.read(medicationPlanNotifierProvider.notifier);
      final agg = await notifier.upsertPlan(input);

      if (!mounted) return;
      if (agg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: AppTheme.snackBarDisplayDuration,
            content: Text(isEditing ? '用药计划已更新' : '用药计划已添加'),
          ),
        );
        widget.onSuccess?.call();
        Navigator.pop(context);
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
