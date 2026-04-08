import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/enums/gender.dart';
import '../providers/baby_providers.dart';

/// 添加宝宝表单组件
/// 对应 Web 版添加宝宝表单
class AddBabyForm extends ConsumerStatefulWidget {
  const AddBabyForm({super.key});

  @override
  ConsumerState<AddBabyForm> createState() => _AddBabyFormState();
}

class _AddBabyFormState extends ConsumerState<AddBabyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Gender _selectedGender = Gender.male;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5, // 最大高度为屏幕高度的50%
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                '添加新宝宝',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),

              // 姓名输入
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '姓名',
                  hintText: '请输入宝宝姓名',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入宝宝姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 性别和出生日期
              Row(
                children: [
                  // 性别选择
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '性别',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.slate600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Gender>(
                              value: _selectedGender,
                              isExpanded: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              borderRadius: BorderRadius.circular(16),
                              items: Gender.values.map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender.label),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedGender = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 出生日期选择
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '出生日期',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.slate600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectBirthDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedBirthDate != null
                                        ? _selectedBirthDate!.toString().split(
                                            ' ',
                                          )[0]
                                        : '请选择日期',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedBirthDate != null
                                          ? AppTheme.brandDark
                                          : AppTheme.slate400,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: AppTheme.slate400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: const Text('确认添加'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedBirthDate = date);
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            duration: AppTheme.snackBarDisplayDuration,
            content: const Text('请选择出生日期'),
          ),
        );
        return;
      }

      try {
        await ref
            .read(babyNotifierProvider.notifier)
            .createBaby(
              name: _nameController.text.trim(),
              gender: _selectedGender,
              birthDate: _selectedBirthDate!,
            );

        // 清空表单
        _nameController.clear();
        setState(() {
          _selectedGender = Gender.male;
          _selectedBirthDate = null;
        });

        if (mounted) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(
            SnackBar(
              duration: AppTheme.snackBarDisplayDuration,
              content: const Text('宝宝添加成功'),
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
              content: Text('添加失败: $e'),
            ),
          );
        }
      }
    }
  }
}
