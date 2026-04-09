import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../providers/growth_data_providers.dart';
import 'glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 生长数据摘要卡片
/// 对齐 Design Spec：玻璃拟态卡片 + 图标容器 + 数据展示
class GrowthSummaryCard extends ConsumerWidget {
  const GrowthSummaryCard({super.key});

  int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255).toInt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestGrowthDataProvider);

    return latestAsync.when(
      data: (latest) {
        return Row(
          children: [
            // 身高卡片
            Expanded(
              child: _buildDataCard(
                icon: Icons.straighten_rounded,
                label: '最新身高',
                value: latest?.height.toStringAsFixed(1) ?? '--',
                unit: 'cm',
                iconBackgroundColor:
                    const Color(0xFF3B82F6).withAlpha(_alpha(0.1)),
                iconColor: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),

            // 体重卡片
            Expanded(
              child: _buildDataCard(
                icon: Icons.monitor_weight_outlined,
                label: '最新体重',
                value: latest?.weight.toStringAsFixed(1) ?? '--',
                unit: 'kg',
                iconBackgroundColor:
                    const Color(0xFF10B981).withAlpha(_alpha(0.1)),
                iconColor: const Color(0xFF10B981),
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing3,
                vertical: AppTheme.spacing2 + 2,
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing3,
                vertical: AppTheme.spacing2 + 2,
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (err, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color iconBackgroundColor,
    required Color iconColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing3,
        vertical: AppTheme.spacing2 + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeCaption,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeBody,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textTertiary,
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
