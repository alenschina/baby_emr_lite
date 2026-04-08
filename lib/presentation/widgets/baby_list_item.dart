import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/baby.dart';

/// 宝宝列表项组件
/// 对应 Web 版宝宝列表项
class BabyListItem extends StatelessWidget {
  final Baby baby;
  final bool isCurrentBaby;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BabyListItem({
    super.key,
    required this.baby,
    this.isCurrentBaby = false,
    required this.onTap,
    required this.onDelete,
  });

  int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255).toInt();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(_alpha(0.7)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // 头像 - 圆角图片
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              baby.avatarPath ?? baby.gender.defaultAvatarPath,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('👶', style: TextStyle(fontSize: 24)),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  baby.birthDate.toString().split(' ')[0],
                  style: TextStyle(fontSize: 13, color: AppTheme.slate500),
                ),
              ],
            ),
          ),

          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 切换/当前按钮
              if (isCurrentBaby)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPrimary.withAlpha(_alpha(0.1)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.brandPrimary.withAlpha(_alpha(0.3)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppTheme.brandPrimary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '当前',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.brandPrimary, Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandPrimary.withAlpha(_alpha(0.3)),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      '切换',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),

              // 删除按钮
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppTheme.slate400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
