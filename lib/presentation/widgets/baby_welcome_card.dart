import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/baby.dart';
import '../../domain/enums/gender.dart';
import 'glass_card.dart';

/// 宝宝欢迎卡片组件
/// 对齐 Design Spec：玻璃拟态卡片 + 圆角头像 + 状态标签
class BabyWelcomeCard extends StatelessWidget {
  final Baby baby;

  const BabyWelcomeCard({super.key, required this.baby});

  @override
  Widget build(BuildContext context) {
    final isMale = baby.gender == Gender.male;

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.cardPaddingLarge),
      child: Row(
        children: [
          // 头像 - 圆角图片
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusIconContainer),
            child: Image.asset(
              baby.avatarPath ?? baby.gender.defaultAvatarPath,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isMale
                          ? [
                              const Color(0xFF3B82F6).withOpacity(0.15),
                              const Color(0xFF6366F1).withOpacity(0.1),
                            ]
                          : [
                              const Color(0xFFEC4899).withOpacity(0.15),
                              const Color(0xFFF43F5E).withOpacity(0.1),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusIconContainer,
                    ),
                  ),
                  child: const Center(
                    child: Text('👶', style: TextStyle(fontSize: 32)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baby.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${baby.gender.label} · ${_formatDate(baby.birthDate)}',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeBody,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),

          // 性别标签 - 使用 StatusBadge 风格
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isMale
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : const Color(0xFFEC4899).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: isMale
                    ? const Color(0xFF3B82F6).withOpacity(0.15)
                    : const Color(0xFFEC4899).withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Text(
              baby.gender.shortLabel,
              style: TextStyle(
                fontSize: AppTheme.fontSizeCaption,
                fontWeight: FontWeight.w500,
                color: isMale
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE11D48),
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
