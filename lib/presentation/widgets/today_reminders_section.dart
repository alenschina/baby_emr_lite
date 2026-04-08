import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/medication_providers.dart';
import '../providers/vaccination_record_providers.dart';
import 'glass_card.dart';

/// 今日提醒区域
/// 对齐 Design Spec：分组标题 + 玻璃拟态卡片
/// 显示今日待处理的用药和疫苗提醒
class TodayRemindersSection extends ConsumerWidget {
  const TodayRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationRemindersAsync = ref.watch(
      todayMedicationRemindersProvider,
    );
    final vaccinationRemindersAsync = ref.watch(
      todayVaccinationRemindersProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏 - Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '今日提醒',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSectionTitle,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            // GestureDetector(
            //   onTap: () => context.go('/medication'),
            //   child: const Text(
            //     '查看全部',
            //     style: TextStyle(
            //       fontSize: AppTheme.fontSizeCaption,
            //       fontWeight: FontWeight.w500,
            //       color: AppTheme.brandPrimary,
            //       fontFamily: AppTheme.fontFamily,
            //     ),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 12),

        // 提醒列表
        medicationRemindersAsync.when(
          data: (medicationReminders) {
            return vaccinationRemindersAsync.when(
              data: (vaccinationReminders) {
                final totalReminders =
                    medicationReminders.length + vaccinationReminders.length;

                if (totalReminders == 0) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    // 用药提醒
                    ...medicationReminders.map(
                      (reminder) => _buildMedicationReminderItem(
                        context,
                        reminder,
                        () => context.go(
                          Uri(
                            path: RoutePaths.medication,
                            queryParameters: {
                              'checkinPlanId': reminder.planId,
                              'checkinPlanName': reminder.medicationName,
                            },
                          ).toString(),
                        ),
                      ),
                    ),

                    // 疫苗提醒
                    ...vaccinationReminders.map(
                      (reminder) => _buildVaccinationReminderItem(
                        context,
                        reminder,
                        () => context.go('/vaccination'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.brandPrimary,
                ),
              ),
              error: (_, __) => _buildEmptyState(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandPrimary,
            ),
          ),
          error: (_, __) => _buildEmptyState(),
        ),
      ],
    );
  }

  /// 用药提醒项
  Widget _buildMedicationReminderItem(
    BuildContext context,
    TodayMedicationReminder reminder,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing3,
          vertical: AppTheme.spacing2 + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppTheme.radiusIconContainer,
                ),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: AppTheme.brandPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.medicationName,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '今日 ${reminder.timeOfDay} · 每次 ${reminder.doseText} · 待打卡',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeCaption,
                      color: AppTheme.textSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// 疫苗提醒项
  Widget _buildVaccinationReminderItem(
    BuildContext context,
    TodayVaccinationReminder reminder,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing3,
          vertical: AppTheme.spacing2 + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppTheme.radiusIconContainer,
                ),
              ),
              child: const Icon(
                Icons.vaccines_rounded,
                color: AppTheme.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.vaccineName,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '今日需接种疫苗',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeCaption,
                      color: AppTheme.textSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.cardPadding,
        vertical: AppTheme.spacing3 + 2,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusIconContainer),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.success,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '今日暂无待办事项',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '添加用药计划或疫苗后会自动显示',
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
}
