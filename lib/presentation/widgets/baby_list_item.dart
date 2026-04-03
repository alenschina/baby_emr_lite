import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/baby.dart';

/// 宝宝列表项组件
/// 对应 Web 版宝宝列表项
class BabyListItem extends StatelessWidget {
  final Baby baby;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BabyListItem({
    super.key,
    required this.baby,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text('👶', style: const TextStyle(fontSize: 24)),
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
                  '${baby.gender.label} · ${baby.birthDate.toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 13, color: AppTheme.slate500),
                ),
              ],
            ),
          ),

          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 切换按钮
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
                        color: AppTheme.brandPrimary.withOpacity(0.3),
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
