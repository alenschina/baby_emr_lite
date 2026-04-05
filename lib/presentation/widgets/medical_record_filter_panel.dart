import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../models/medical_record_filter.dart';

/// 病例记录过滤面板组件
class MedicalRecordFilterPanel extends StatefulWidget {
  final MedicalRecordFilter currentFilter;
  final List<String> availableHospitals;
  final List<int> availableYears;
  final ValueChanged<MedicalRecordFilter> onFilterChanged;
  final VoidCallback onClear;

  const MedicalRecordFilterPanel({
    super.key,
    required this.currentFilter,
    required this.availableHospitals,
    required this.availableYears,
    required this.onFilterChanged,
    required this.onClear,
  });

  @override
  State<MedicalRecordFilterPanel> createState() =>
      _MedicalRecordFilterPanelState();
}

class _MedicalRecordFilterPanelState extends State<MedicalRecordFilterPanel> {
  late int? selectedStartYear;
  late int? selectedEndYear;
  late String? selectedHospital;
  late TextEditingController diagnosisController;
  late TextEditingController medicationController;

  @override
  void initState() {
    super.initState();
    selectedStartYear = widget.currentFilter.startYear;
    selectedEndYear = widget.currentFilter.endYear;
    selectedHospital = widget.currentFilter.hospital;
    diagnosisController =
        TextEditingController(text: widget.currentFilter.diagnosisKeyword ?? '');
    medicationController =
        TextEditingController(text: widget.currentFilter.medicationKeyword ?? '');

    diagnosisController.addListener(_onChanged);
    medicationController.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(MedicalRecordFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentFilter != widget.currentFilter) {
      selectedStartYear = widget.currentFilter.startYear;
      selectedEndYear = widget.currentFilter.endYear;
      selectedHospital = widget.currentFilter.hospital;
      if (widget.currentFilter.diagnosisKeyword != diagnosisController.text) {
        diagnosisController.text = widget.currentFilter.diagnosisKeyword ?? '';
      }
      if (widget.currentFilter.medicationKeyword !=
          medicationController.text) {
        medicationController.text = widget.currentFilter.medicationKeyword ?? '';
      }
    }
  }

  @override
  void dispose() {
    diagnosisController.dispose();
    medicationController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final filter = widget.currentFilter.copyWith(
      startYear: selectedStartYear,
      endYear: selectedEndYear,
      hospital: selectedHospital?.isEmpty == true ? null : selectedHospital,
      diagnosisKeyword: diagnosisController.text.isEmpty
          ? null
          : diagnosisController.text.trim(),
      medicationKeyword: medicationController.text.isEmpty
          ? null
          : medicationController.text.trim(),
    );
    widget.onFilterChanged(filter);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.glassCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.brandPrimary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: AppTheme.brandPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '筛选条件',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
                if (widget.currentFilter.isActive)
                  TextButton.icon(
                    onPressed: widget.onClear,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('清空'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.brandPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 筛选内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 年份区间筛选
                _buildYearFilter(),
                const SizedBox(height: 16),

                // 医疗机构筛选
                _buildHospitalFilter(),
                const SizedBox(height: 16),

                // 疾病类型筛选
                _buildDiagnosisFilter(),
                const SizedBox(height: 16),

                // 药品名称筛选
                _buildMedicationFilter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            const Text(
              '年份区间',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDropdown<int>(
                value: selectedStartYear,
                hint: '起始年份',
                items: widget.availableYears,
                onChanged: (value) {
                  setState(() {
                    selectedStartYear = value;
                  });
                  _onChanged();
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '至',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
            Expanded(
              child: _buildDropdown<int>(
                value: selectedEndYear,
                hint: '结束年份',
                items: widget.availableYears,
                onChanged: (value) {
                  setState(() {
                    selectedEndYear = value;
                  });
                  _onChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHospitalFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_hospital_rounded,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            const Text(
              '医疗机构',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDropdown<String>(
          value: selectedHospital?.isEmpty == true ? null : selectedHospital,
          hint: '全部机构',
          items: ['全部', ...widget.availableHospitals],
          onChanged: (value) {
            setState(() {
              selectedHospital = value == '全部' ? null : value;
            });
            _onChanged();
          },
        ),
      ],
    );
  }

  Widget _buildDiagnosisFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.medical_services_rounded,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            const Text(
              '疾病类型',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: diagnosisController,
          decoration: InputDecoration(
            hintText: '输入疾病关键词',
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
              fontFamily: AppTheme.fontFamily,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: AppTheme.textTertiary,
            ),
            filled: true,
            fillColor: AppTheme.slate50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.medication_rounded,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            const Text(
              '药品名称',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: medicationController,
          decoration: InputDecoration(
            hintText: '输入药品关键词',
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
              fontFamily: AppTheme.fontFamily,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: AppTheme.textTertiary,
            ),
            filled: true,
            fillColor: AppTheme.slate50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? AppTheme.brandPrimary.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
